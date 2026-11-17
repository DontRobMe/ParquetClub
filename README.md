# Parquet – Club partenaires

App Flutter (Android + iOS) du réseau partenaires du club de basket : annuaire public, invitations avec réponse « Je viens », notifications. Serveur : Firebase (région europe-west9).

## Lancer

```bash
flutter pub get
flutter run
```

Firebase n'est pas encore branché : `flutterfire configure` génère `lib/firebase_options.dart`.

## Organisation (cahier des charges, partie 4)

MVVM : Vue → Cubit (ViewModel) → Repository → Firebase.

```
lib/core/theme/app_theme.dart     seul fichier de couleurs et polices (cours 5)
lib/features/<auth|partners|events|admin>/
    data/    repositories, seuls à parler à Firebase
    logic/   Cubits et états (sealed class : chargement, erreur, vide, succès)
    ui/      écrans
test/                             un test par Cubit + test widget « Je viens » (cours 6)
firestore.rules, storage.rules    droits vérifiés côté serveur
```

Polices : Barlow Condensed et DM Sans (licence OFL, `assets/fonts`).
