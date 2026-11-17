import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Événements à venir (F11), en temps réel : une modification du bureau s'affiche dès que le réseau revient.
  Stream<EvenementsSnapshot> ecouterEvenements() => _firestore
      .collection('events')
      .where('date', isGreaterThanOrEqualTo: Timestamp.now())
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
  Future<void> repondre(String eventId, {required bool vient, required int nbPersonnes}) =>
      _reponse(eventId).set({'vient': vient, 'nbPersonnes': nbPersonnes, 'updatedAt': FieldValue.serverTimestamp()});

  DocumentReference<Map<String, dynamic>> _reponse(String eventId) =>
      _firestore.collection('events').doc(eventId).collection('responses').doc(_uid);
}
