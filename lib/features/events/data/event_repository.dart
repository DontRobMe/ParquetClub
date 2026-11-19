import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../admin/data/admin_repository.dart' show ajouterAuJournal;
import 'event.dart';

typedef EvenementsSnapshot = ({List<Event> evenements, bool horsLigne});

/// Seule classe des événements qui connaît Firebase (le faux repository des tests fait `implements`).
class EventRepository {
  EventRepository([FirebaseFirestore? firestore, FirebaseAuth? auth])
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser?.uid ?? (throw StateError('Aucun compte connecté'));

  /// Agenda et historique, en temps réel.
  Stream<EvenementsSnapshot> ecouterEvenements() => _firestore
      .collection('events')
      .orderBy('date')
      .snapshots(includeMetadataChanges: true)
      .map(
        (snap) => (
          evenements: [for (final doc in snap.docs) Event.fromMap(doc.id, doc.data())],
          horsLigne: snap.metadata.isFromCache,
        ),
      );

  /// Ma réponse à un événement, ou null si je n'ai pas encore répondu.
  Stream<EventResponse?> ecouterReponse(String eventId) => _reponse(eventId)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snap) => snap.exists ? EventResponse.fromMap(snap.data()!, enAttente: snap.metadata.hasPendingWrites) : null,
      );

  /// Hors ligne, Firestore écrit d'abord dans le cache (affiché tout de suite, `enAttente`),
  /// puis envoie au retour du réseau. Le Future ne se termine qu'à la confirmation du serveur.
  Future<void> repondre(String eventId, {required bool vient, required int nbPersonnes}) => _reponse(eventId).set({
    'vient': vient,
    'nbPersonnes': nbPersonnes,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  Future<void> noter(String eventId, AvisEvenement avis) {
    final ref = _reponse(eventId);
    return _firestore.runTransaction<void>((transaction) async {
      final reponse = (await transaction.get(ref)).data();
      if (reponse?['presence'] != true || reponse!.containsKey('note')) {
        throw StateError("L'avis n'est plus disponible.");
      }
      transaction.update(ref, {'note': avis.note, 'commentaire': avis.commentaire});
    });
  }

  /// F10, bureau uniquement (règle `isAdmin`). Un identifiant vide crée l'événement.
  /// L'événement et son entrée de journal (F18) partent dans le même lot.
  /// Hors ligne, le lot est appliqué au cache tout de suite et envoyé au retour du réseau.
  Future<void> enregistrer(Event event) {
    final evenements = _firestore.collection('events');
    final ref = event.id.isEmpty ? evenements.doc() : evenements.doc(event.id);
    final lot = _firestore.batch()..set(ref, event.toMap());
    ajouterAuJournal(
      _firestore,
      _auth,
      lot,
      event.id.isEmpty ? "création de l'événement" : "modification de l'événement",
      event.titre,
    );
    return lot.commit();
  }

  Future<void> annuler(Event event) {
    final lot = _firestore.batch()
      ..update(_firestore.collection('events').doc(event.id), {'statut': EventStatut.annule.name});
    ajouterAuJournal(_firestore, _auth, lot, "annulation de l'événement", event.titre);
    return lot.commit();
  }

  DocumentReference<Map<String, dynamic>> _reponse(String eventId) =>
      _firestore.collection('events').doc(eventId).collection('responses').doc(_uid);
}
