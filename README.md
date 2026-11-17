# Parquet – Club partenaires

App Flutter (Android + iOS) du réseau partenaires du club de basket : annuaire public, invitations avec réponse « Je viens », notifications. Serveur : Firebase (région europe-west9).

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
5. Dans Authentication > Modèles, adapter l'e-mail de réinitialisation : c'est aussi l'e-mail d'invitation d'un nouveau partenaire.

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
