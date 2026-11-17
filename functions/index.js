// Les 4 actions réservées au serveur (cahier des charges, partie 3) : créer un compte, désactiver un compte,
// supprimer un partenaire, envoyer les push. Les droits sont vérifiés ici, jamais seulement dans l'app.
const { setGlobalOptions } = require('firebase-functions/v2');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentWrittenWithAuthContext } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getStorage } = require('firebase-admin/storage');

initializeApp();
setGlobalOptions({ region: 'europe-west9' }); // Paris, RGPD
const db = getFirestore();
const TOPIC = 'partenaires';

/** Refuse tout appelant qui n'est pas un admin actif (OWASP M3). Renvoie son uid. */
async function verifierAdmin(request) {
  const auth = request.auth;
  if (!auth || auth.token.role !== 'admin') throw new HttpsError('permission-denied', 'Action réservée au bureau.');
  const user = await db.doc(`users/${auth.uid}`).get();
  if (user.get('disabled') === true) throw new HttpsError('permission-denied', 'Ce compte est désactivé.');
  return auth.uid;
}

function texte(valeur, max, nom) {
  if (typeof valeur !== 'string' || !valeur.trim() || valeur.length > max) {
    throw new HttpsError('invalid-argument', `${nom} manquant ou trop long.`);
  }
  return valeur.trim();
}

/** Journal des actions du bureau (F18) : qui a fait quoi, sur quoi, quand. */
async function journal(auteur, action, cible) {
  const email = (await getAuth().getUser(auteur).catch(() => null))?.email ?? auteur;
  return db.collection('adminLogs').add({ auteur, auteurEmail: email, action, cible, date: FieldValue.serverTimestamp() });
}

async function nomDe(uid) {
  const fiche = await db.doc(`partners/${uid}`).get();
  return fiche.get('nom') || uid;
}

/** Un compte désactivé ou supprimé ne reçoit plus les invitations. */
async function desabonner(token) {
  if (token) await getMessaging().unsubscribeFromTopic(token, TOPIC).catch(() => {});
}

/** F3. Crée le compte sans mot de passe : l'app envoie ensuite le lien Firebase pour le choisir. */
exports.creerPartenaire = onCall(async (request) => {
  const auteur = await verifierAdmin(request);
  const nom = texte(request.data?.nom, 80, "Nom de l'entreprise");
  const email = texte(request.data?.email, 254, 'E-mail').toLowerCase();

  let user;
  try {
    user = await getAuth().createUser({ email });
  } catch (e) {
    if (e.code === 'auth/email-already-exists') throw new HttpsError('already-exists', 'Un compte existe déjà avec cet e-mail.');
    if (e.code === 'auth/invalid-email') throw new HttpsError('invalid-argument', "Cet e-mail n'est pas valide.");
    throw e;
  }
  // Le rôle est un custom claim : personne ne peut le modifier depuis l'app.
  await getAuth().setCustomUserClaims(user.uid, { role: 'partenaire' });

  const batch = db.batch();
  batch.set(db.doc(`users/${user.uid}`), { email, role: 'partenaire', disabled: false });
  batch.set(db.doc(`partners/${user.uid}`), {
    nom, metier: '', secteur: 'Autre', description: '', adresse: '', ville: '',
    telephone: '', email: '', site: '', logoUrl: '', updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  await journal(auteur, 'création du compte', nom);
  return { uid: user.uid };
});

/** F4. Désactive (ou réactive) un compte tout de suite : connexion bloquée, sessions révoquées, règles fermées. */
exports.changerAcces = onCall(async (request) => {
  const auteur = await verifierAdmin(request);
  const uid = texte(request.data?.uid, 128, 'Compte');
  const actif = request.data?.actif === true;
  if (uid === auteur) throw new HttpsError('failed-precondition', 'Vous ne pouvez pas désactiver votre propre compte.');

  await getAuth().updateUser(uid, { disabled: !actif });
  const ref = db.doc(`users/${uid}`);
  await ref.update({ disabled: !actif }); // les règles Firestore refusent aussitôt toute écriture
  if (!actif) {
    await getAuth().revokeRefreshTokens(uid);
    await desabonner((await ref.get()).get('fcmToken'));
  }
  await journal(auteur, actif ? "réactivation de l'accès" : "désactivation de l'accès", await nomDe(uid));
});

/** F5. Efface le compte, la fiche, le numéro privé, le logo, les réponses et le token de notification. */
exports.supprimerPartenaire = onCall(async (request) => {
  const auteur = await verifierAdmin(request);
  const uid = texte(request.data?.uid, 128, 'Compte');
  if (uid === auteur) throw new HttpsError('failed-precondition', 'Vous ne pouvez pas supprimer votre propre compte.');

  const nom = await nomDe(uid);
  const user = await db.doc(`users/${uid}`).get();
  await desabonner(user.get('fcmToken'));

  const writer = db.bulkWriter();
  // ponytail: parcourt tous les événements, un club en a quelques dizaines par an.
  for (const event of await db.collection('events').listDocuments()) {
    writer.delete(event.collection('responses').doc(uid));
  }
  writer.delete(db.doc(`partners/${uid}/private/contact`));
  writer.delete(db.doc(`partners/${uid}`));
  writer.delete(db.doc(`users/${uid}`));
  await writer.close();

  await getStorage().bucket().file(`logos/${uid}.jpg`).delete({ ignoreNotFound: true });
  await getAuth().deleteUser(uid).catch((e) => {
    if (e.code !== 'auth/user-not-found') throw e;
  });
  await journal(auteur, 'suppression du partenaire', nom);
});

/** F14. Push automatique à la création, la modification ou l'annulation d'un événement.
 *  Le texte est généré ici : le bureau n'écrit jamais le message envoyé à tous. */
exports.notifierEvenement = onDocumentWrittenWithAuthContext('events/{eventId}', async (event) => {
  const avant = event.data.before.exists ? event.data.before.data() : null;
  const apres = event.data.after.exists ? event.data.after.data() : null;
  if (!apres) return;

  let titre;
  let action;
  if (!avant) {
    titre = `Nouvelle invitation : ${apres.titre}`;
    action = "création de l'événement";
  } else if (apres.statut === 'annule' && avant.statut !== 'annule') {
    titre = `Annulé : ${apres.titre}`;
    action = "annulation de l'événement";
  } else if (!avant.date.isEqual(apres.date) || avant.lieu !== apres.lieu || avant.titre !== apres.titre) {
    titre = `${apres.titre} : date ou lieu modifié`;
    action = "modification de l'événement";
  } else {
    return; // description seule : pas de push
  }

  const quand = apres.date.toDate().toLocaleString('fr-FR', {
    timeZone: 'Europe/Paris', weekday: 'long', day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit',
  });
  await getMessaging().send({
    topic: TOPIC,
    notification: { title: titre, body: apres.lieu ? `${quand} · ${apres.lieu}` : quand },
    data: { eventId: event.params.eventId }, // un appui ouvre le détail de l'événement
  });
  if (event.authType === 'app_user' && event.authId) await journal(event.authId, action, apres.titre);
});

/** RGPD : les réponses aux événements sont effacées 12 mois après l'événement (cahier des charges, partie 5). */
exports.purgerReponses = onSchedule({ schedule: 'every day 03:00', timeZone: 'Europe/Paris' }, async () => {
  const limite = new Date();
  limite.setFullYear(limite.getFullYear() - 1);
  // ponytail: relit chaque nuit tous les anciens événements ; marquer ceux déjà purgés si la liste grossit.
  const anciens = await db.collection('events').where('date', '<', limite).get();
  const writer = db.bulkWriter();
  for (const event of anciens.docs) {
    for (const reponse of await event.ref.collection('responses').listDocuments()) writer.delete(reponse);
  }
  await writer.close();
});
