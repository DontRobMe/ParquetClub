import { comptesDemo, projet } from './seed.mjs';

const racine = `/projects/${projet}/accounts`;
const confidentialite = { retries: 0, skipLog: { body: true, resBody: true } };

export async function preparerComptes(client) {
  const [parEmail, parUid] = await Promise.all([
    client.post(`${racine}:lookup`, { email: comptesDemo.map(({ email }) => email) }, confidentialite),
    client.post(`${racine}:lookup`, { localId: comptesDemo.map(({ localId }) => localId) }, confidentialite),
  ]);
  const existants = [...(parEmail.body.users ?? []), ...(parUid.body.users ?? [])];
  return comptesDemo.map((compte) => {
    const comptesLies = existants.filter(({ email, localId }) =>
      email?.toLowerCase() === compte.email || localId === compte.localId,
    );
    // Même UID avec un autre e-mail : la seed le met à jour. Même e-mail sur un autre UID : conflit.
    if (comptesLies.some(({ localId }) => localId !== compte.localId)) {
      throw new Error(`Conflit dans Firebase Authentication pour ${compte.email}. Le compte existant a été conservé.`);
    }
    return { ...compte, existe: comptesLies.length > 0 };
  });
}

export async function appliquerComptes(client, comptes) {
  const motsDePasse = {
    // Mots de passe courts et connus, pour les essais et l'oral (6 caractères, minimum de Firebase).
    // Attention : écrits dans un dépôt public ; changer le mot de passe du bureau avant toute vraie mise en service.
    bureau: 'bureau',
    partenaires: 'presta',
  };
  for (const { localId, email, existe } of comptes) {
    const password = email === comptesDemo[0].email ? motsDePasse.bureau : motsDePasse.partenaires;
    try {
      const { body } = await client.post(
        existe ? `${racine}:update` : racine,
        { localId, password, email, ...(existe ? { disableUser: false } : {}) },
        confidentialite,
      );
      if (body.localId !== localId) throw new Error('UID retourné inattendu.');
    } catch (erreur) {
      throw new Error(`Firebase Authentication a échoué pour ${email}. Relancez la démo pour reprendre. ${erreur.message}`);
    }
  }
  return motsDePasse;
}
