# Parquet – Club partenaires

App Flutter (Android et iOS) du réseau de partenaires du club de basket. Elle propose l’annuaire public, les invitations, les rappels, l’émargement et les avis sur les événements. Le projet Firebase `parquetclub` utilise la région `europe-west9`.

## Documentation

Cahier des charges, maquette, charte et fiches des stores : voir [docs/](docs/README.md).

## Lancer

```bash
flutter pub get
flutter run
```

## Démo Windows

[`demo.bat`](demo.bat) utilise Node.js 20 ou plus récent et la session Firebase CLI connectée avec `npx firebase-tools@15.37.0 login`. Il travaille sur Firebase Authentication et la base Firestore `(default)` du projet `parquetclub`. Les données sont visibles dans la [console Cloud Firestore](https://console.firebase.google.com/project/parquetclub/firestore/data) et les comptes dans la [console Authentication](https://console.firebase.google.com/project/parquetclub/authentication/users).

| Commande | Action |
| --- | --- |
| `demo.bat --apercu` | Affiche les opérations prévues en lecture seule. |
| `demo.bat` | Initialise les comptes de démo et remplace les documents préfixés `parquet-demo-`. |
| `demo.bat --tout --apercu` | Affiche les opérations prévues pour une remise à zéro des collections métier. |
| `demo.bat --tout` | Après saisie de `EFFACER parquetclub`, efface les événements et leurs réponses, les fiches partenaires et leurs sous-collections, le journal et les profils Firestore préfixés `parquet-demo-`, puis charge la démo. Les autres profils `users` sont conservés. |

Le script crée `demo-admin@parquet.fr` (mot de passe `bureau`) pour le bureau et `presta1@parquet.fr` à `presta12@parquet.fr` (mot de passe `presta`) pour les partenaires. Les comptes gardent leur UID à chaque lancement. Ces mots de passe sont publics : à changer avant toute vraie mise en service. Le profil `presta12` sert à montrer un accès désactivé dans l’app. Si une adresse est déjà liée à un UID extérieur au jeu de démo, le script s’arrête avant toute écriture.

Pour présenter le parcours complet avec un compte `presta1@parquet.fr` existant, le bureau peut l’émarger sur **Soirée partenaires à Beaublanc**. Dans **Mon profil → Historique des événements**, **Rencontres au bord du parquet** contient déjà une présence validée sans avis. Le journal et les événements utilisent des dates calculées à chaque lancement.

Les profils et partenariats de démo sont fictifs. Les marques et leurs logos servent d’exemples visuels.

| Visuels | Provenance |
| --- | --- |
| Logos Nike et Fnac | [Nike sur Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Logo_NIKE.svg), [Fnac sur Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Fnac_Logo.svg) |
| Logos adidas, Boulanger, New Balance et PUMA | [Simple Icons](https://simpleicons.org/) |
| Photos d’illustration pour les événements | [Zekai Zhu](https://www.pexels.com/photo/11831850/), [Piotr Arnoldes](https://www.pexels.com/photo/7156048/), [Maria Orlova](https://www.pexels.com/photo/4946389/) sous [licence Pexels](https://www.pexels.com/license/) |

## Mettre en place Firebase (une fois)

Forfait **Spark** (gratuit, sans carte) : Authentication et Firestore seulement, région `europe-west9` (Paris).
Pas de Cloud Functions ni de Storage : les actions du bureau se font depuis son téléphone, protégées par
`firestore.rules`, et les logos sont rangés dans les fiches.

1. Console Firebase : Authentication (e-mail / mot de passe, modèles d'e-mail en français) et Firestore (édition Standard, `(default)`, `europe-west9`, mode production).
2. `flutterfire configure`, puis ajouter `options: DefaultFirebaseOptions.currentPlatform` dans `lib/main.dart`.
3. Publier les règles avec `firebase deploy --only firestore:rules --project parquetclub`. Relancer cette commande après toute modification de `firestore.rules`, notamment avant de tester une nouvelle écriture sur le Firebase du club.
4. Premier compte du bureau, à la main dans la console :
   - Authentication > Ajouter un utilisateur (e-mail + mot de passe provisoire), copier son UID ;
   - Firestore > collection `users` > document dont l'ID est cet UID, champs `email` (string), `role` = `admin` (string), `disabled` = `false` (boolean) ;
   - le bénévole choisit ensuite son mot de passe avec « Mot de passe oublié ».
   Les comptes suivants (bureau et partenaires) se créent depuis l'app.
5. Supprimer un partenaire depuis l'app efface ses données ; son compte de connexion se supprime ensuite à la main (Authentication).

Limite du forfait Spark : pas de notification push envoyée par un serveur (F14). Le rappel 2 jours avant (F16) est une notification locale et fonctionne.

L’émargement et l’avis complètent la réponse existante dans `events/{eventId}/responses/{uid}`. Le bureau valide le champ `presence`, puis le partenaire présent peut écrire `note` et `commentaire`.

## Organisation (cahier des charges, partie 4)

MVVM : Vue → Cubit (ViewModel) → Repository → Firebase.

```
lib/core/theme/app_theme.dart     seul fichier de couleurs et polices (cours 5)
lib/features/<auth|partners|events|admin>/
    data/    repositories, seuls à parler à Firebase
    logic/   Cubits et états (sealed class : chargement, erreur, vide, succès)
    ui/      écrans
test/                             un test par Cubit + test widget « Je viens » (cours 6)
firestore.rules                   droits vérifiés côté serveur
```

Polices : Barlow Condensed et DM Sans (licence OFL, `assets/fonts`).

## Intégration continue

`.github/workflows/ci.yml`, à chaque push sur `main` et à chaque pull request :

1. **Analyse et tests** : format, `flutter analyze`, `flutter test`.
2. **Build Android** : `app-release.aab` obfusqué, numéro de build = numéro du run, téléchargeable dans l'onglet Actions (avec les symboles pour décoder les plantages).
3. **Build iOS sans signature** (sur `main` seulement) : vérifie que l'app compile, faute de Mac dans l'équipe.

## Publier

### Clé de signature Android (une fois, à garder précieusement hors du dépôt)

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- En local : copier le fichier dans `android/app/` et créer `android/key.properties` (ignorés par Git) :
  ```
  storeFile=upload-keystore.jks
  storePassword=…
  keyAlias=upload
  keyPassword=…
  ```
- En CI : secrets GitHub `ANDROID_KEYSTORE_BASE64` (`base64 -w0 upload-keystore.jks`), `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

Sans clé, le build de publication est signé avec la clé de debug : il compile, mais ne doit jamais être envoyé sur un store.

### Version

`version: 1.0.0+1` dans `pubspec.yaml` : le nom (1.0.0) se change à la main à chaque version, le numéro de build est donné par la CI.

### Distribuer avant de publier

- Android : envoyer l'`.aab` de la CI en **test interne** sur la Play Console (Play App Signing activé).
- iOS : depuis un Mac, `flutter build ipa`, puis **TestFlight**.

### Fiches des stores

Textes dans `Fiche_App_Store.pdf` et `Fiche_Google_Play.pdf` ; remplacer « [Nom du club] », ajouter l'icône, les captures et le lien vers la politique de confidentialité.
