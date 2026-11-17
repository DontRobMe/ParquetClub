import '../data/event.dart';

/// Les 4 états de l'écran événements (cours 1 et 4).
sealed class EventsState {
  const EventsState();
}

class EventsLoading extends EventsState {
  const EventsLoading();
}

class EventsError extends EventsState {
  const EventsError(this.message);
  final String message;
}

class EventsEmpty extends EventsState {
  const EventsEmpty({this.horsLigne = false, this.derniereSynchro});
  final bool horsLigne;
  final DateTime? derniereSynchro;
}

class EventsSuccess extends EventsState {
  const EventsSuccess({
    required this.evenements,
    this.reponses = const {},
    this.horsLigne = false,
    this.derniereSynchro,
  });

  final List<Event> evenements;

  /// Mes réponses, par identifiant d'événement.
  final Map<String, EventResponse> reponses;
  final bool horsLigne;
  final DateTime? derniereSynchro;
}
