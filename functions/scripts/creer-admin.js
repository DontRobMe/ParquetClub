// Crée (ou promeut) un compte du bureau. À lancer une fois par bénévole, depuis le dossier functions :
//   gcloud auth application-default login
//   GCLOUD_PROJECT=<id-du-projet> node scripts/creer-admin.js prenom@club.fr
// Le bénévole choisit ensuite son mot de passe avec « Mot de passe oublié » dans l'app.
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

async function main(email) {
  if (!email) throw new Error('Usage : node scripts/creer-admin.js prenom@club.fr');
  initializeApp();
  const auth = getAuth();
  const user = await auth.getUserByEmail(email).catch(() => auth.createUser({ email }));
  await auth.setCustomUserClaims(user.uid, { role: 'admin' });
  await getFirestore().doc(`users/${user.uid}`).set({ email, role: 'admin', disabled: false }, { merge: true });
  console.log(`Compte bureau prêt : ${email}`);
}

main(process.argv[2]).catch((e) => {
  console.error(e.message);
  process.exit(1);
});
