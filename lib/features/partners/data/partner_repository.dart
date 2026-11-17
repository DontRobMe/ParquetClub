import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'partner.dart';

typedef AnnuaireSnapshot = ({List<Partner> partenaires, bool horsLigne});

/// Erreur déjà traduite pour l'écran.
class PartnerErreur implements Exception {
  const PartnerErreur(this.message);
  final String message;
}

/// Seule classe de la fonctionnalité qui connaît Firebase.
/// Pas d'interface séparée (cours 2) : en Dart, le faux repository des tests fait `implements PartnerRepository`.
class PartnerRepository {
  PartnerRepository([FirebaseFirestore? firestore, FirebaseStorage? storage])
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const tailleMaxLogo = 1024 * 1024; // même limite que storage.rules

  /// Écoute l'annuaire en temps réel. Sans réseau, Firestore répond depuis son cache local :
  /// `horsLigne` vaut alors true (bandeau « Hors connexion »).
  Stream<AnnuaireSnapshot> ecouterPartenaires() => _firestore
      .collection('partners')
      .orderBy('nom')
      .snapshots(includeMetadataChanges: true)
      .map(
        (snap) => (
          partenaires: [for (final doc in snap.docs) Partner.fromMap(doc.id, doc.data())],
          horsLigne: snap.metadata.isFromCache,
        ),
      );

  /// Ma fiche, en temps réel (null si elle n'existe pas).
  Stream<Partner?> ecouterFiche(String uid) => _firestore
      .collection('partners')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? Partner.fromMap(doc.id, doc.data()!) : null);

  /// F7. Téléphone personnel : document séparé, car les règles Firestore filtrent par document, pas par champ.
  Stream<String> ecouterTelephonePerso(String uid) =>
      _contact(uid).snapshots().map((doc) => doc.data()?['telephonePerso'] as String? ?? '');

  /// F6. Hors ligne, l'écriture part au retour du réseau ; le Future ne se termine qu'à ce moment-là.
  Future<void> mettreAJourFiche(Partner p) => _firestore.collection('partners').doc(p.id).update({
    'nom': p.nom,
    'metier': p.metier,
    'secteur': p.secteur,
    'description': p.description,
    'adresse': p.adresse,
    'ville': p.ville,
    'telephone': p.telephone,
    'email': p.email,
    'site': p.site,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> enregistrerTelephonePerso(String uid, String telephone) =>
      _contact(uid).set({'telephonePerso': telephone});

  /// Logo : sélecteur photo du système (aucune permission), redimensionné à 512 px avant l'envoi.
  /// Renvoie false si l'utilisateur annule.
  Future<bool> choisirEtEnvoyerLogo(String uid) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
      requestFullMetadata: false, // pas de position GPS ni de métadonnées de la photo
    );
    if (image == null) return false;
    final octets = await image.readAsBytes();
    if (octets.length >= tailleMaxLogo) throw const PartnerErreur('Image trop lourde (1 Mo maximum).');
    try {
      final ref = _storage.ref('logos/$uid.jpg');
      await ref.putData(octets, SettableMetadata(contentType: 'image/jpeg'));
      // Paramètre de version : le nouveau logo remplace l'ancien dans le cache des téléphones.
      final url = '${await ref.getDownloadURL()}&v=${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('partners').doc(uid).update({
        'logoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException {
      throw const PartnerErreur("Le logo n'a pas pu être envoyé. Vérifiez la connexion et réessayez.");
    }
  }

  DocumentReference<Map<String, dynamic>> _contact(String uid) =>
      _firestore.collection('partners').doc(uid).collection('private').doc('contact');
}
