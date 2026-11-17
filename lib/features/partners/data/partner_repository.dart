import 'package:cloud_firestore/cloud_firestore.dart';

import 'partner.dart';

typedef AnnuaireSnapshot = ({List<Partner> partenaires, bool horsLigne});

/// Seule classe de la fonctionnalité qui connaît Firebase.
/// Pas d'interface séparée (cours 2) : en Dart, le faux repository des tests fait `implements PartnerRepository`.
class PartnerRepository {
  PartnerRepository([FirebaseFirestore? firestore]) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Écoute l'annuaire en temps réel. Sans réseau, Firestore répond depuis son cache local :
  /// `horsLigne` vaut alors true (bandeau « Hors connexion »).
  Stream<AnnuaireSnapshot> ecouterPartenaires() => _firestore
      .collection('partners')
      .orderBy('nom')
      .snapshots(includeMetadataChanges: true)
      .map((snap) => (
            partenaires: [for (final doc in snap.docs) Partner.fromMap(doc.id, doc.data())],
            horsLigne: snap.metadata.isFromCache,
          ));
}
