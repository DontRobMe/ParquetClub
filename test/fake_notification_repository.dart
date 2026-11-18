import 'dart:async';

import 'package:parquet/features/events/data/event.dart';
import 'package:parquet/features/notifications/data/notification_repository.dart';

/// Fausses notifications locales : enregistre ce que l'app demande.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({this.aDemander = false});

  bool aDemander;
  var demandes = 0; // fenêtres système ouvertes
  final rappels = <String, Event>{}; // programmés en ce moment
  final ouvertures = StreamController<String>.broadcast();

  @override
  Future<bool> permissionADemander() async => aDemander;

  @override
  Future<void> demanderPermission() async => demandes++;

  @override
  Stream<String> evenementsOuverts() => ouvertures.stream;

  @override
  Future<void> programmerRappel(Event event) async => rappels[event.id] = event;

  @override
  Future<void> annulerRappel(String eventId) async => rappels.remove(eventId);

  @override
  Future<void> annulerTousLesRappels() async => rappels.clear();
}
