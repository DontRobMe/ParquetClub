import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/event.dart';
import '../data/event_repository.dart';
import 'events_state.dart';

/// ViewModel des événements : partagé par la liste et le détail (état partagé, cours 4).
class EventsCubit extends Cubit<EventsState> {
  EventsCubit(this._repository) : super(const EventsLoading());

  final EventRepository _repository;
  StreamSubscription<EvenementsSnapshot>? _abonnement;
  // ponytail: une écoute par événement à venir ; un club en a une poignée. Requête collectionGroup si ça grossit.
  final _abonnementsReponses = <String, StreamSubscription<EventResponse?>>{};

  List<Event> _evenements = const [];
  final _reponses = <String, EventResponse>{};
  bool _recu = false;
  bool _horsLigne = false;
  DateTime? _derniereSynchro;

  /// Démarre (ou relance après une erreur) l'écoute des événements à venir.
  void charger() {
    emit(const EventsLoading());
    _toutArreter();
    _abonnement = _repository.ecouterEvenements().listen((snap) {
      _evenements = snap.evenements;
      _horsLigne = snap.horsLigne;
      if (!snap.horsLigne) _derniereSynchro = DateTime.now();
      _recu = true;
      _suivreReponses();
      _emettre();
    }, onError: (Object _) => emit(const EventsError('Impossible de charger les événements.')));
  }

  Event? evenement(String id) {
    for (final e in _evenements) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// F12. Ne pas attendre le Future pour afficher : hors ligne, il ne se termine qu'au retour du réseau.
  /// La réponse apparaît tout de suite via `ecouterReponse`, avec `enAttente` à vrai.
  Future<void> repondre(String eventId, {required bool vient, int nbPersonnes = 1}) =>
      _repository.repondre(eventId, vient: vient, nbPersonnes: vient ? nbPersonnes : 0);

  /// F10. Une modification de date ou de lieu passe l'événement au statut « modifié ».
  /// Même règle que `repondre` : l'écran n'attend pas le serveur.
  Future<void> enregistrer(Event event, {Event? ancien}) {
    final change = ancien != null && (ancien.date != event.date || ancien.lieu != event.lieu);
    return _repository.enregistrer(
      Event(
        id: event.id,
        titre: event.titre,
        type: event.type,
        date: event.date,
        lieu: event.lieu,
        description: event.description,
        statut: change ? EventStatut.modifie : (ancien?.statut ?? EventStatut.prevu),
      ),
    );
  }

  Future<void> annuler(String eventId) => _repository.annuler(eventId);

  void _suivreReponses() {
    final ids = {for (final e in _evenements) e.id};
    for (final id in _abonnementsReponses.keys.toList()) {
      if (!ids.contains(id)) {
        _abonnementsReponses.remove(id)!.cancel();
        _reponses.remove(id);
      }
    }
    for (final id in ids) {
      _abonnementsReponses[id] ??= _repository.ecouterReponse(id).listen(
        (reponse) {
          if (reponse == null) {
            _reponses.remove(id);
          } else {
            _reponses[id] = reponse;
          }
          _emettre();
        },
        // Une réponse illisible ne bloque pas la liste : l'événement s'affiche sans réponse.
        onError: (Object _) {},
      );
    }
  }

  void _emettre() {
    if (!_recu) return;
    if (_evenements.isEmpty) {
      emit(EventsEmpty(horsLigne: _horsLigne, derniereSynchro: _derniereSynchro));
      return;
    }
    emit(
      EventsSuccess(
        evenements: _evenements,
        reponses: Map.unmodifiable(_reponses),
        horsLigne: _horsLigne,
        derniereSynchro: _derniereSynchro,
      ),
    );
  }

  void _toutArreter() {
    _abonnement?.cancel();
    for (final a in _abonnementsReponses.values) {
      a.cancel();
    }
    _abonnementsReponses.clear();
    _reponses.clear();
  }

  @override
  Future<void> close() {
    _toutArreter();
    return super.close();
  }
}
