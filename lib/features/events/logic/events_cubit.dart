import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../notifications/data/notification_repository.dart';
import '../data/event.dart';
import '../data/event_repository.dart';
import 'events_state.dart';

/// ViewModel des événements : partagé par la liste et le détail (état partagé, cours 4).
class EventsCubit extends Cubit<EventsState> {
  EventsCubit(this._repository, [this._notifications]) : super(const EventsLoading());

  final EventRepository _repository;
  final NotificationRepository? _notifications;

  /// Rappels déjà programmés : identifiant de l'événement → ce qui a servi à les écrire.
  final _rappels = <String, String>{};
  bool _rappelsRemisAZero = false;
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

  /// Vrai si l'écran doit expliquer le rappel avant de demander l'autorisation des notifications.
  Future<bool> rappelsADemander() async {
    try {
      return await _notifications?.permissionADemander() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> autoriserRappels() async => _notifications?.demanderPermission().catchError((Object _) {});

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

  Future<void> annuler(String eventId) {
    final event = evenement(eventId);
    return event == null ? Future.value() : _repository.annuler(event);
  }

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

  /// F16. Recalculé à chaque changement : « Je viens » programme le rappel, « Je ne viens pas »,
  /// une annulation ou un événement passé le retirent ; un changement de date le reprogramme.
  // ponytail: un événement annulé pendant que l'app est fermée garde son rappel jusqu'à la prochaine ouverture.
  void _mettreAJourRappels() {
    final notifications = _notifications;
    if (notifications == null) return;
    if (!_rappelsRemisAZero) {
      // Au démarrage, on repart de zéro : rien d'un ancien état ou d'un autre compte ne survit.
      _rappelsRemisAZero = true;
      notifications.annulerTousLesRappels().ignore();
    }
    final voulus = {
      for (final e in _evenements)
        if (!e.annule && (_reponses[e.id]?.vient ?? false)) e.id: e,
    };
    for (final id in _rappels.keys.toList()) {
      if (!voulus.containsKey(id)) {
        _rappels.remove(id);
        notifications.annulerRappel(id).ignore();
      }
    }
    for (final e in voulus.values) {
      final signature = '${e.date}|${e.titre}|${e.lieu}';
      if (_rappels[e.id] != signature) {
        _rappels[e.id] = signature;
        notifications.programmerRappel(e).ignore();
      }
    }
  }

  void _emettre() {
    if (!_recu) return;
    _mettreAJourRappels();
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
