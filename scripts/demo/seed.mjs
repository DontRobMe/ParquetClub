import { readFile } from 'node:fs/promises';
import { evenements, partenaires } from './catalogue.mjs';

export const projet = 'parquetclub';
export const baseDocuments = `projects/${projet}/databases/(default)/documents`;
export const prefixeDemo = 'parquet-demo-';
const bureauDemo = { localId: `${prefixeDemo}bureau`, email: 'demo-admin@parquet.fr' };
const partenairesDemo = partenaires.map((_, indice) => ({
  localId: `${prefixeDemo}presta${indice + 1}`, email: `presta${indice + 1}@parquet.fr`,
}));
export const comptesDemo = [bureauDemo, ...partenairesDemo];

function datesParis(maintenant) {
  const calendrier = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Paris', year: 'numeric', month: '2-digit', day: '2-digit',
  });
  const decalage = new Intl.DateTimeFormat('en-US', { timeZone: 'Europe/Paris', timeZoneName: 'longOffset' });
  const parties = Object.fromEntries(calendrier.formatToParts(maintenant).map(({ type, value }) => [type, value]));
  return (jour, heure = 18, minute = 0) => {
    const reference = new Date(Date.UTC(+parties.year, +parties.month - 1, +parties.day + jour, heure, minute));
    const zone = decalage.formatToParts(reference).find(({ type }) => type === 'timeZoneName').value;
    const [, signe, heures, minutes] = /^GMT([+-])(\d\d):(\d\d)$/.exec(zone);
    const offset = (+heures * 60 + +minutes) * (signe === '-' ? -1 : 1);
    return new Date(reference.getTime() - offset * 60_000);
  };
}

async function lireMedia(nom, max) {
  const contenu = await readFile(new URL(`./media/${nom}`, import.meta.url));
  if (!contenu.length || contenu.length > max) throw new Error(`Format ou taille inattendue pour ${nom}.`);
  return contenu;
}

function valeurFirestore(valeur) {
  if (Buffer.isBuffer(valeur)) return { bytesValue: valeur.toString('base64') };
  if (valeur instanceof Date) return { timestampValue: valeur.toISOString() };
  if (typeof valeur === 'boolean') return { booleanValue: valeur };
  if (typeof valeur === 'number' && Number.isInteger(valeur)) return { integerValue: String(valeur) };
  if (typeof valeur === 'string') return { stringValue: valeur };
  throw new Error(`Valeur de démo non prise en charge : ${typeof valeur}.`);
}

export async function creerJeu() {
  const maintenant = new Date();
  const date = datesParis(maintenant);
  const uids = [];
  const documents = [];
  let reponses = 0;
  let avis = 0;
  let logs = 0;
  const enregistrer = (chemin, donnees) => documents.push({
    update: {
      name: `${baseDocuments}/${chemin}`,
      fields: Object.fromEntries(Object.entries(donnees).map(([champ, valeur]) => [champ, valeurFirestore(valeur)])),
    },
  });
  enregistrer(`users/${bureauDemo.localId}`, { email: bureauDemo.email, role: 'admin', disabled: false });

  function journal(action, cible, dateAction) {
    logs++;
    enregistrer(`adminLogs/${prefixeDemo}log-${String(logs).padStart(3, '0')}`, {
      action, cible, auteur: `${prefixeDemo}bureau`, auteurEmail: 'demo-logs@parquet.fr',
      date: dateAction < maintenant ? dateAction : maintenant,
    });
  }

  for (const [indice, partenaire] of partenaires.entries()) {
    const { nom, metier, secteur, ville, description, adresse = '', site = '', logo, desactive = false } = partenaire;
    const { localId: uid, email } = partenairesDemo[indice];
    uids.push(uid);
    enregistrer(`users/${uid}`, { email, role: 'partenaire', disabled: desactive });
    enregistrer(`partners/${uid}`, {
      nom, metier, secteur, ville, description: `Fiche de démonstration. ${description}`, adresse, site,
      email: '', telephone: '', updatedAt: date(-90 + indice, 10),
      ...(logo ? { logo: await lireMedia(logo, 150_000) } : {}),
    });
    journal('création du compte partenaire', nom, date(-90 + indice, 10));
  }
  journal("désactivation de l'accès", 'Studio Lisière', date(-6, 9));

  const photos = new Map();
  for (const event of evenements) {
    const { id, titre, type, lieu = '', description = '', statut = 'prevu', photo, jour, heure, minute } = event;
    const debut = date(jour, heure, minute);
    if (photo && !photos.has(photo)) photos.set(photo, await lireMedia(photo, 450_000));
    const evenement = `events/${prefixeDemo}${id}`;
    enregistrer(evenement, {
      titre, type, lieu, description, statut, date: debut,
      ...(photo ? { photo: photos.get(photo) } : {}),
    });
    journal("création de l'événement", titre, date(Math.min(jour - 12, -2), 11));
    if (statut === 'modifie') journal("modification de l'événement", titre, date(-5, 14));
    if (statut === 'annule') journal("annulation de l'événement", titre, date(-2, 16));

    for (const [numero, invites, presence, note, commentaire = ''] of event.reponses ?? []) {
      const uid = uids[numero - 1];
      enregistrer(`${evenement}/responses/${uid}`, {
        ...(invites !== null ? { vient: invites > 0, nbPersonnes: invites, updatedAt: date(Math.min(jour - 2, -1), 15) } : {}),
        ...(presence !== undefined ? { presence } : {}),
        ...(note !== undefined ? { note, commentaire } : {}),
      });
      reponses++;
      if (note !== undefined) avis++;
    }
  }
  journal('réactivation de l’accès', 'Atelier Terre Claire', date(-19, 11));
  journal('modification de l’événement', 'Rencontres au bord du parquet', date(-11, 12));

  const bilan = { partenaires: partenaires.length, evenements: evenements.length, reponses, avis, logs };
  return { documents, bilan };
}
