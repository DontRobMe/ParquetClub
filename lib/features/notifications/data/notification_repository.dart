import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/format_date.dart';
import '../../events/data/event.dart';

/// Notifications locales : rappel 2 jours avant un événement (F16), programmé par l'app elle-même.
/// Il part même sans réseau et sans serveur.
/// Forfait Spark : sans Cloud Functions, pas de push envoyé par un serveur (F14 reportée, voir le cahier des charges).
/// Seule classe qui connaît le plugin de notifications.
class NotificationRepository {
  NotificationRepository([FlutterLocalNotificationsPlugin? local])
    : _local = local ?? FlutterLocalNotificationsPlugin();

  static const _canalRappels = AndroidNotificationDetails(
    'rappels',
    'Rappels',
    channelDescription: 'Rappel 2 jours avant un événement auquel vous venez',
  );

  final FlutterLocalNotificationsPlugin _local;
  final _ouvertures = StreamController<String>.broadcast();
  bool _lancementLu = false;

  /// Initialisé une seule fois, au premier besoin ; tous les appels attendent la même initialisation.
  late final Future<void> _initialisation = _initialiserUneFois();
  Future<void> _initialiser() => _initialisation;

  Future<void> _initialiserUneFois() async {
    tz_data.initializeTimeZones();
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // La permission est demandée au moment où elle sert, après une explication (cours 3, OWASP M6).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (reponse) {
        final id = reponse.payload;
        if (id != null && id.isNotEmpty) _ouvertures.add(id);
      },
    );
  }

  /// Vrai si les notifications ne sont pas encore autorisées : l'app explique d'abord pourquoi.
  Future<bool> permissionADemander() async {
    await _initialiser();
    final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return !(await android.areNotificationsEnabled() ?? true);
    final ios = _local.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return !((await ios.checkPermissions())?.isEnabled ?? true);
    return false;
  }

  /// Fenêtre du système. En cas de refus, l'app fonctionne : seul le rappel manque.
  Future<void> demanderPermission() async {
    await _initialiser();
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _local.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      sound: true,
    );
  }

  /// Identifiants d'événements à ouvrir après un appui sur un rappel (app ouverte ou lancée par le rappel).
  Stream<String> evenementsOuverts() async* {
    await _initialiser();
    if (!_lancementLu) {
      _lancementLu = true; // le plugin renvoie toujours le même lancement : on ne le lit qu'une fois
      final lancement = await _local.getNotificationAppLaunchDetails();
      final rappel = lancement?.notificationResponse?.payload;
      if ((lancement?.didNotificationLaunchApp ?? false) && rappel != null) yield rappel;
    }
    yield* _ouvertures.stream;
  }

  /// F16. Rappel 2 jours avant l'événement ; rien si cette date est déjà passée.
  Future<void> programmerRappel(Event event) async {
    final quand = event.date.subtract(const Duration(days: 2));
    if (quand.isBefore(DateTime.now())) return;
    await _initialiser();
    await _local.zonedSchedule(
      id: idRappel(event.id),
      // Un instant absolu : l'heure UTC donne le bon moment quel que soit le fuseau du téléphone.
      scheduledDate: tz.TZDateTime.from(quand, tz.UTC),
      notificationDetails: const NotificationDetails(android: _canalRappels, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // pas de permission d'alarme exacte
      title: 'Dans 2 jours : ${event.titre}',
      body: [dateLongue(event.date), heure(event.date), if (event.lieu.isNotEmpty) event.lieu].join(' · '),
      payload: event.id,
    );
  }

  Future<void> annulerRappel(String eventId) async {
    await _initialiser();
    await _local.cancel(id: idRappel(eventId));
  }

  /// Aussi à la déconnexion : aucun rappel d'un compte ne survit pour le suivant sur ce téléphone.
  Future<void> annulerTousLesRappels() async {
    await _initialiser();
    await _local.cancelAll();
  }
}

/// Identifiant numérique stable d'un rappel, calculé à partir de l'identifiant de l'événement.
int idRappel(String eventId) {
  var h = 0;
  for (final c in eventId.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}
