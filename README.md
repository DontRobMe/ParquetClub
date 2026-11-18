# Parquet – Club partenaires

App Flutter (Android + iOS) du réseau partenaires du club de basket : annuaire public, invitations avec réponse « Je viens », notifications. Serveur : Firebase (région europe-west9).

## Documentation

Cahier des charges, maquette, charte et fiches des stores : voir [docs/](docs/README.md).

## Lancer

```bash
flutter pub get
flutter run
```

## Mettre en place Firebase (une fois)

1. Créer le projet Firebase (région `europe-west9`), activer Authentication (e-mail / mot de passe), Firestore, Storage, et passer au forfait Blaze (obligatoire pour Cloud Functions).
2. `flutterfire configure`, puis ajouter `options: DefaultFirebaseOptions.currentPlatform` dans `lib/main.dart`.
3. `cd functions && npm install`, puis `firebase deploy --only firestore:rules,storage,functions`.
4. Créer chaque compte du bureau : `node functions/scripts/creer-admin.js prenom@club.fr` (voir l'en-tête du script). Le bénévole choisit son mot de passe avec « Mot de passe oublié ».
5. iOS (sur un Mac) : dans Xcode, ajouter les capacités *Push Notifications* et *Background Modes > Remote notifications*, puis déposer la clé APNs dans Firebase > Paramètres > Cloud Messaging.
6. Dans Authentication > Modèles, adapter l'e-mail de réinitialisation : c'est aussi l'e-mail d'invitation d'un nouveau partenaire.

## Organisation (cahier des charges, partie 4)

MVVM : Vue → Cubit (ViewModel) → Repository → Firebase.

```
lib/core/theme/app_theme.dart     seul fichier de couleurs et polices (cours 5)
lib/features/<auth|partners|events|admin>/
    data/    repositories, seuls à parler à Firebase
    logic/   Cubits et états (sealed class : chargement, erreur, vide, succès)
    ui/      écrans
test/                             un test par Cubit + test widget « Je viens » (cours 6)
functions/                        Cloud Functions : créer, désactiver, supprimer un compte, push
firestore.rules, storage.rules    droits vérifiés côté serveur
```

Polices : Barlow Condensed et DM Sans (licence OFL, `assets/fonts`).

## Intégration continue

`.github/workflows/ci.yml`, à chaque push sur `main` et à chaque pull request :

1. **Analyse et tests** : format, `flutter analyze`, `flutter test`.
2. **Cloud Functions** : le module se charge et exporte ses 5 fonctions.
3. **Build Android** : `app-release.aab` obfusqué, numéro de build = numéro du run, téléchargeable dans l'onglet Actions (avec les symboles pour décoder les plantages).
4. **Build iOS sans signature** (sur `main` seulement) : vérifie que l'app compile, faute de Mac dans l'équipe.

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
