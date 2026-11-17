import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/format_date.dart';
import '../../events/data/event.dart';

/// Notifications (cahier des charges, partie 4) :
/// - push : envoyée par la Cloud Function via FCM sur le topic `partenaires`, arrive même app fermée ;
/// - locale : rappel 2 jours avant, programmé par l'app elle-même, part même sans réseau (F16).
/// Seule classe qui connaît FCM et le plugin de notifications locales.
class NotificationRepository {
  NotificationRepository([
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? local,
  ]) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _local = local ?? FlutterLocalNotificationsPlugin();

  static const topic = 'partenaires';
  static const _canalRappels = AndroidNotificationDetails(
    'rappels',
    'Rappels',
    channelDescription: 'Rappel 2 jours avant un événement auquel vous venez',
  );

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _local;
  final _ouvertures = StreamController<String>.broadcast();
  StreamSubscription<String>? _rafraichissement;
  bool _lancementLu = false;

  /// Initialisé une seule fois, au premier besoin ; tous les appels attendent la même initialisation.
  late final Future<void> _initialisation = _initialiserUneFois();
  Future<void> _initialiser() => _initialisation;

  Future<void> _initialiserUneFois() async {
    tz_data.initializeTimeZones();
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final id = message.data['eventId'];
      if (id is String) _ouvertures.add(id);
    });
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // La permission est demandée une seule fois, par FCM, au bon moment.
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

  /// Vrai si le système n'a encore jamais posé la question : l'app explique d'abord pourquoi.
  Future<bool> permissionADemander() async =>
      (await _messaging.getNotificationSettings()).authorizationStatus == AuthorizationStatus.notDetermined;

  /// À la connexion d'un partenaire : autorisation, token enregistré dans `users/{uid}`, abonnement au topic.
  /// En cas de refus, l'app fonctionne : les événements restent visibles dans l'onglet.
  Future<void> activer(String uid) async {
    await _initialiser();
    final reglages = await _messaging.requestPermission();
    if (reglages.authorizationStatus == AuthorizationStatus.denied) return;

    Future<void> enregistrer(String token) => _firestore.collection('users').doc(uid).update({'fcmToken': token});

    // getToken / onTokenRefresh / deleteToken sont marqués obsolètes au profit de register() (identifiant
    // d'installation), mais les topics et le SDK Admin des Cloud Functions travaillent encore avec ce token.
    // ignore: deprecated_member_use
    final token = await _messaging.getToken();
    if (token != null) await enregistrer(token);
    await _rafraichissement?.cancel();
    // ignore: deprecated_member_use
    _rafraichissement = _messaging.onTokenRefresh.listen(enregistrer);
    await _messaging.subscribeToTopic(topic);
  }

  /// À la déconnexion : plus de push ni de rappel sur ce téléphone, même pour le compte suivant.
  Future<void> desactiver() async {
    await _rafraichissement?.cancel();
    _rafraichissement = null;
    await _messaging.unsubscribeFromTopic(topic);
    // ignore: deprecated_member_use
    await _messaging.deleteToken(); // l'ancien token ne vaut plus rien, même s'il reste en base
    await _initialiser();
    await _local.cancelAll();
  }

  /// Identifiants d'événements à ouvrir : appui sur un push (app fermée ou en arrière-plan) ou sur un rappel.
  Stream<String> evenementsOuverts() async* {
    await _initialiser();
    final depart = await _messaging.getInitialMessage();
    final id = depart?.data['eventId'];
    if (id is String) yield id;
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
