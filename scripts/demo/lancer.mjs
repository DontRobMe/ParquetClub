import { existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { delimiter, join } from 'node:path';
import { createInterface } from 'node:readline';
import { stdin, stdout } from 'node:process';
import { appliquerComptes, preparerComptes } from './auth.mjs';
import { appliquer, preparer } from './firestore.mjs';
import { projet } from './seed.mjs';

async function connecterFirebase() {
  // Le .bat place la version épinglée du CLI dans le PATH via npm exec.
  const cli = process.env.PATH.split(delimiter)
    .map((dossier) => join(dossier, '..', 'firebase-tools', 'lib'))
    .find((dossier) => existsSync(join(dossier, 'requireAuth.js')));
  if (!cli) throw new Error('Firebase CLI introuvable. Lancez demo.bat depuis le projet.');

  const require = createRequire(import.meta.url);
  const { selectAccount, setActiveAccount } = require(join(cli, 'auth.js'));
  const { requireAuth } = require(join(cli, 'requireAuth.js'));
  const { Client } = require(join(cli, 'apiv2.js'));
  const options = { project: projet };
  const compte = selectAccount(undefined, process.cwd());
  if (compte) setActiveAccount(options, compte);
  await requireAuth(options);
  return {
    firestore: new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' }),
    authentication: new Client({ urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'v1' }),
  };
}

try {
  const args = process.argv.slice(2);
  if (args.some((option) => !['--apercu', '--tout', '--base'].includes(option))) {
    throw new Error('Utilisez demo.bat [--apercu] [--tout].');
  }
  if (Number(process.versions.node.split('.')[0]) < 20) throw new Error('Node.js 20 ou plus récent est requis.');

  const tout = args.includes('--tout');
  const apercu = args.includes('--apercu');
  console.log(`Cloud Firestore · ${projet} · (default)`);
  console.log(tout ? 'Périmètre · événements, fiches partenaires, journal et profils Firestore de démo' : 'Périmètre · données de démo');
  const { firestore, authentication } = await connecterFirebase();
  const [plan, comptes] = await Promise.all([preparer(firestore, { tout }), preparerComptes(authentication)]);
  const { bilan, suppressions, ecritures } = plan;
  console.log(`${suppressions} suppressions et ${ecritures.length - suppressions} écritures de démo prévues.`);
  console.log(`${bilan.partenaires} fiches, ${bilan.evenements} événements, ${bilan.reponses} réponses, ${bilan.avis} avis, ${bilan.logs} entrées du journal.`);
  const existants = comptes.filter(({ existe }) => existe).length;
  console.log(`Firebase Authentication · ${comptes.length - existants} comptes à créer et ${existants} mots de passe de démo à renouveler.`);

  if (apercu) {
    console.log('Aperçu terminé. Aucune écriture effectuée.');
  } else {
    if (tout) {
      const lecture = createInterface({ input: stdin, output: stdout });
      const attendu = `EFFACER ${projet}`;
      let confirmation;
      try {
        console.log(`Tapez ${attendu} pour valider la remise à zéro du Firestore distant.`);
        for await (const ligne of lecture) {
          confirmation = ligne.trim();
          break;
        }
      } finally {
        lecture.close();
      }
      if (confirmation !== attendu) throw new Error('Remise à zéro annulée.');
    }
    const motsDePasse = await appliquerComptes(authentication, comptes);
    await appliquer(firestore, plan).catch((erreur) => {
      throw new Error(`Les comptes de démo ont été configurés. L'écriture Firestore a échoué. Relancez le script pour terminer. ${erreur.message}`);
    });
    console.log(`Démo enregistrée sur Cloud Firestore. https://console.firebase.google.com/project/${projet}/firestore/data`);
    console.log(`Bureau · ${comptes[0].email} · ${motsDePasse.bureau}`);
    console.log(`Partenaires · presta1@parquet.fr à presta12@parquet.fr · ${motsDePasse.partenaires}`);
    console.log('Le profil presta12 est désactivé dans l’app pour la démo.');
  }
} catch (erreur) {
  console.error(`Échec de la démo. ${erreur.message}`);
  process.exitCode = 1;
}
