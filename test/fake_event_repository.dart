import 'dart:async';

import 'package:parquet/features/events/data/event.dart';
import 'package:parquet/features/events/data/event_repository.dart';

/// Faux repository qui imite Firestore hors ligne : la réponse apparaît tout de suite « en attente »,
/// puis `confirmerServeur()` simule le retour du réseau.
class FakeEventRepository implements EventRepository {
  final evenements = StreamController<EvenementsSnapshot>.broadcast();
  final _reponses = <String, StreamController<EventResponse?>>{};
  final appels = <({String eventId, bool vient, int nbPersonnes})>[];
  var _serveur = Completer<void>();

  @override
  Stream<EvenementsSnapshot> ecouterEvenements() => evenements.stream;

  @override
  Stream<EventResponse?> ecouterReponse(String eventId) =>
      (_reponses[eventId] ??= StreamController<EventResponse?>.broadcast()).stream;

  @override
  Future<void> repondre(String eventId, {required bool vient, required int nbPersonnes}) {
    appels.add((eventId: eventId, vient: vient, nbPersonnes: nbPersonnes));
    _reponses[eventId]?.add(EventResponse(vient: vient, nbPersonnes: nbPersonnes, enAttente: true));
    return _serveur.future;
  }

  final enregistres = <Event>[];
  final annules = <String>[];

  @override
  Future<void> enregistrer(Event event) async => enregistres.add(event);

  @override
  Future<void> annuler(Event event) async => annules.add(event.id);

  void envoyer(List<Event> liste, {bool horsLigne = false}) =>
      evenements.add((evenements: liste, horsLigne: horsLigne));

  void confirmerServeur() {
    final dernier = appels.last;
    _reponses[dernier.eventId]?.add(EventResponse(vient: dernier.vient, nbPersonnes: dernier.nbPersonnes));
    _serveur.complete();
    _serveur = Completer<void>();
  }
}

final soiree = Event(
  id: 'loge',
  titre: 'Soirée en loge',
  type: 'Match en loge',
  date: DateTime(2026, 12, 4, 19, 30),
  lieu: 'Palais des Sports · Limoges',
);
final afterwork = Event(id: 'aw', titre: 'Afterwork du club', type: 'Afterwork', date: DateTime(2026, 12, 17, 18, 45));
final voeux = Event(id: 'voeux', titre: 'Vœux au parquet', date: DateTime(2027, 1, 14, 19), statut: EventStatut.annule);
