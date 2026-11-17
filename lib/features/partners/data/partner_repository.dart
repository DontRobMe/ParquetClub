import 'package:cloud_firestore/cloud_firestore.dart';
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
  PartnerRepository([FirebaseFirestore? firestore]) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const tailleMaxLogo = 150 * 1000; // même limite que les règles Firestore

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

  /// Logo : sélecteur photo du système (aucune permission), réduit à 256 px avant l'envoi.
  /// Renvoie false si l'utilisateur annule. Hors ligne, il part au retour du réseau.
  Future<bool> choisirEtEnvoyerLogo(String uid) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 80,
      requestFullMetadata: false, // pas de position GPS ni de métadonnées de la photo
    );
    if (image == null) return false;
    final octets = await image.readAsBytes();
    if (octets.length >= tailleMaxLogo) throw const PartnerErreur('Image trop lourde (150 Ko maximum).');
    // Pas d'attente du serveur : comme une réponse « Je viens », l'écriture est mise en file hors ligne.
    _firestore.collection('partners').doc(uid).update({
      'logo': Blob(octets),
      'updatedAt': FieldValue.serverTimestamp(),
    }).ignore();
    return true;
  }

  DocumentReference<Map<String, dynamic>> _contact(String uid) =>
      _firestore.collection('partners').doc(uid).collection('private').doc('contact');
}
