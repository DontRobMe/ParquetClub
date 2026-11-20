import { baseDocuments, creerJeu, prefixeDemo } from './seed.mjs';

const racine = `/${baseDocuments}`;
const collections = ['users', 'partners', 'events', 'adminLogs'];
const id = (document) => document.name.split('/').at(-1);
const estDemo = (document) => id(document).startsWith(prefixeDemo);
const chemin = (document) => '/' + document.name.split('/').map(encodeURIComponent).join('/');

async function lister(client, collection, champs) {
  const documents = [];
  let pageToken;
  do {
    const queryParams = new URLSearchParams({ pageSize: '100', showMissing: 'true' });
    for (const champ of champs) queryParams.append('mask.fieldPaths', champ);
    if (pageToken) queryParams.set('pageToken', pageToken);
    const { body } = await client.get(collection, { queryParams });
    documents.push(...(body.documents ?? []));
    pageToken = body.nextPageToken;
  } while (pageToken);
  return documents;
}

async function avecSousCollections(client, document) {
  const adresse = chemin(document);
  const descendants = [];
  let pageToken;
  do {
    const { body } = await client.post(`${adresse}:listCollectionIds`, { pageSize: 100, pageToken });
    for (const collection of body.collectionIds ?? []) {
      const enfants = await lister(client, `${adresse}/${encodeURIComponent(collection)}`, ['nom']);
      for (const enfant of enfants) descendants.push(...await avecSousCollections(client, enfant));
    }
    pageToken = body.nextPageToken;
  } while (pageToken);
  if (document.updateTime) descendants.push(document);
  return descendants;
}

export async function preparer(client, { tout }) {
  const racines = await Promise.all(collections.map((collection) => lister(
    client, `${racine}/${collection}`, collection === 'users' ? ['email', 'role'] : ['nom'],
  )));

  const { documents, bilan } = await creerJeu();
  const cibles = racines.flatMap((docs, indice) => docs.filter((doc) => estDemo(doc) || (tout && collections[indice] !== 'users')));
  const aRetirer = [];
  // Limiter les lectures simultanées lors d'une remise à zéro volumineuse.
  for (let debut = 0; debut < cibles.length; debut += 12) {
    const arbres = await Promise.all(cibles.slice(debut, debut + 12).map((doc) => avecSousCollections(client, doc)));
    aRetirer.push(...arbres.flat());
  }

  const versions = new Map([...racines.flat(), ...aRetirer].filter((doc) => doc.updateTime).map((doc) => [doc.name, doc.updateTime]));
  const remplacements = new Set(documents.map(({ update }) => update.name));
  const suppressions = aRetirer.filter((doc) => !remplacements.has(doc.name)).map((doc) => ({
    delete: doc.name,
    currentDocument: { updateTime: doc.updateTime },
  }));
  const ecritures = documents.map(({ update }) => ({
    update,
    currentDocument: versions.has(update.name) ? { updateTime: versions.get(update.name) } : { exists: false },
  }));

  return {
    bilan,
    suppressions: suppressions.length,
    ecritures: [...suppressions, ...ecritures],
  };
}

export async function appliquer(client, { ecritures }) {
  // La démo tient dans un commit. Le découpage couvre aussi les gros nettoyages avec --tout.
  const tailleLot = 400;
  for (let debut = 0; debut < ecritures.length; debut += tailleLot) {
    try {
      await client.post(`${racine}:commit`, { writes: ecritures.slice(debut, debut + tailleLot) }, { retries: 0 });
    } catch (erreur) {
      if (debut === 0) throw erreur;
      throw new Error(`${debut} écritures validées avant l'erreur. Relancez le script pour terminer. ${erreur.message}`);
    }
  }
}
