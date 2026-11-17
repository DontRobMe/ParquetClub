import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/features/admin/data/admin_repository.dart';
import 'package:parquet/main.dart';

import 'fake_admin_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_event_repository.dart';
import 'fake_notification_repository.dart';
import 'fake_partner_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late FakePartnerRepository partners;
  late FakeEventRepository events;
  late FakeAdminRepository admin;
  late FakeNotificationRepository notifications;

  Future<void> lancer(
    WidgetTester tester, {
    bool connecte = false,
    bool estBureau = false,
    bool notificationsADemander = false,
  }) async {
    notifications = FakeNotificationRepository(aDemander: notificationsADemander);
    auth = FakeAuthRepository(connecteAuDemarrage: connecte, compte: estBureau ? bureau : partenaire);
    partners = FakePartnerRepository();
    events = FakeEventRepository();
    admin = FakeAdminRepository();
    await tester.pumpWidget(
      ParquetApp(
        authRepository: auth,
        partnerRepository: partners,
        eventRepository: events,
        adminRepository: admin,
        notificationRepository: notifications,
      ),
    );
    await tester.pump(); // lecture de la session
    if (connecte && !estBureau) {
      partners.fiche.add(maFiche); // sinon le chargement de « Mon profil » tourne sans fin
      await tester.pump();
    }
  }

  /// Écran haut : tout le formulaire est construit, sans défilement.
  void ecranHaut(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('visiteur : accueil du club, annuaire et connexion, pas d\'événements', (tester) async {
    await lancer(tester);
    expect(find.text('Voir les partenaires'), findsOneWidget);
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Événements'), findsNothing);
  });

  testWidgets('chercher un expert-comptable et ouvrir sa fiche, sans compte', (tester) async {
    // Arrange
    await lancer(tester);
    await tester.tap(find.text('Voir les partenaires'));
    await tester.pump();
    partners.envoyer([atelier, cap, grain]);
    await tester.pump();
    expect(find.text('Atelier Martin'), findsOneWidget);

    // Act
    await tester.enterText(find.byType(TextField), 'comptable');
    await tester.pump();
    await tester.tap(find.text('Cap Conseil'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('CAP CONSEIL'), findsOneWidget);
    expect(find.text('Appeler'), findsOneWidget);
    expect(find.text('Site web'), findsOneWidget);
    expect(find.text('E-mail'), findsNothing); // pas d'e-mail renseigné : pas de bouton
  });

  testWidgets('hors connexion, le bandeau remplace le chargement sans fin', (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Annuaire'));
    await tester.pump();
    partners.envoyer([atelier], horsLigne: true);
    await tester.pump();
    expect(find.textContaining('Hors connexion'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('se connecter mène aux onglets du partenaire', (tester) async {
    await lancer(tester);
    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, 'E-mail'), 'contact@cap-conseil.example');
    await tester.enterText(find.widgetWithText(TextField, 'Mot de passe'), 'faux');
    await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
    await tester.pump();
    expect(find.text('E-mail ou mot de passe incorrect.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Mot de passe'), 'bon');
    await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Événements'), findsOneWidget);
    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('Connexion'), findsNothing);
  });

  // Parcours principal du cahier des charges (cours 6) : ouvrir un événement et répondre « Je viens ».
  testWidgets('ouvrir un événement et répondre Je viens à deux, hors connexion', (tester) async {
    // Arrange
    await lancer(tester, connecte: true);
    events.envoyer([soiree, afterwork, voeux]);
    await tester.tap(find.text('Événements'));
    await tester.pumpAndSettle();
    expect(find.text('SOIRÉE EN LOGE'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Annulé'), 200);
    expect(find.textContaining('Annulé'), findsOneWidget);

    // Act
    await tester.ensureVisible(find.text("Répondre à l'invitation"));
    await tester.tap(find.text("Répondre à l'invitation"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Une personne de plus'));
    await tester.pump();
    await tester.tap(find.text('Je viens'));
    await tester.pump();

    // Assert : affichée tout de suite, en attente du réseau
    expect(find.text('En attente de synchronisation'), findsOneWidget);
    expect(events.appels.single, (eventId: 'loge', vient: true, nbPersonnes: 2));

    // Retour du réseau : confirmée
    events.confirmerServeur();
    await tester.pump();
    await tester.pump();
    expect(find.text('Vous venez à 2'), findsOneWidget);
    expect(find.text('Réponse envoyée au club.'), findsOneWidget);
  });

  testWidgets('se déconnecter demande confirmation puis revient en visiteur', (tester) async {
    await lancer(tester, connecte: true);
    await tester.tap(find.text('Mon profil'));
    await tester.pump();
    await tester.tap(find.byTooltip('Se déconnecter'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // fin de la transition d'écran
    await tester.tap(find.widgetWithText(TextButton, 'Se déconnecter'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Voir les partenaires'), findsOneWidget);
  });

  testWidgets("partenaire : pas d'onglet Administration", (tester) async {
    await lancer(tester, connecte: true);
    expect(find.text('Administration'), findsNothing);
  });

  testWidgets("bureau : suivi d'un événement avec le total pour le traiteur", (tester) async {
    // Arrange
    await lancer(tester, connecte: true, estBureau: true);
    partners.envoyer([cap, grain]);
    events.envoyer([soiree]);
    admin.comptes.add(const []);
    await tester.tap(find.text('Administration'));
    await tester.pump();

    // Act
    await tester.tap(find.text('Gérer les événements'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // fin de la transition d'écran
    await tester.tap(find.text('Soirée en loge'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // fin de la transition d'écran
    admin.reponses.add(const [
      ReponseBureau(uid: 'c', vient: true, nbPersonnes: 3),
      ReponseBureau(uid: 'g', vient: false, nbPersonnes: 0),
    ]);
    await tester.pump();

    // Assert
    expect(find.text('3'), findsOneWidget);
    expect(find.text('participants confirmés'), findsOneWidget);
    expect(find.textContaining('Cap Conseil'), findsOneWidget);
    expect(find.textContaining('Absent'), findsOneWidget);
  });

  testWidgets('bureau : annuler un événement demande confirmation', (tester) async {
    await lancer(tester, connecte: true, estBureau: true);
    events.envoyer([soiree]);
    admin.comptes.add(const []);
    await tester.tap(find.text('Administration'));
    await tester.pump();
    await tester.tap(find.text('Gérer les événements'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // fin de la transition d'écran
    await tester.tap(find.text('Soirée en loge'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // fin de la transition d'écran

    await tester.scrollUntilVisible(find.widgetWithText(TextButton, "Annuler l'événement"), 200);
    await tester.tap(find.widgetWithText(TextButton, "Annuler l'événement"));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // fin de la transition d'écran
    expect(events.annules, isEmpty); // rien tant que ce n'est pas confirmé
    await tester.tap(find.widgetWithText(TextButton, "Annuler l'événement").last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // fin de la transition d'écran
    expect(events.annules, ['loge']);
  });

  testWidgets('notifications : explication avant la fenêtre du système, puis activation', (tester) async {
    await lancer(tester, connecte: true, notificationsADemander: true);
    await tester.pump();
    expect(find.text('Être prévenu des événements'), findsOneWidget);
    expect(notifications.activations, isEmpty); // rien avant l'accord

    await tester.tap(find.text('Continuer'));
    await tester.pump();
    expect(notifications.activations, ['p1']);
  });

  testWidgets('notifications : « Plus tard » ne demande rien au système', (tester) async {
    await lancer(tester, connecte: true, notificationsADemander: true);
    await tester.pump();
    await tester.tap(find.text('Plus tard'));
    await tester.pump();
    expect(notifications.activations, isEmpty);
  });

  testWidgets("appui sur une notification : ouvre le détail de l'événement", (tester) async {
    await lancer(tester, connecte: true);
    events.envoyer([soiree]);
    await tester.pump();
    notifications.ouvertures.add('loge');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // fin de la transition d'écran
    expect(find.text('Je viens'), findsOneWidget);
  });

  testWidgets('partenaire : modifier sa fiche, téléphone personnel réservé au bureau', (tester) async {
    // Arrange
    ecranHaut(tester);
    await lancer(tester, connecte: true);
    await tester.tap(find.text('Mon profil'));
    await tester.pump();
    await tester.tap(find.text('Modifier ma fiche'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // fin de la transition d'écran
    expect(find.textContaining('Visible uniquement par le bureau'), findsOneWidget);
    expect(find.textContaining('pas de photo de personne'), findsOneWidget);

    // Act : site en http refusé, puis corrigé
    await tester.enterText(find.widgetWithText(TextField, 'Site web'), 'http://cap.fr');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(partners.fichesEnregistrees, isEmpty);
    await tester.enterText(find.widgetWithText(TextField, 'Site web'), 'https://cap.fr');
    await tester.enterText(find.widgetWithText(TextField, 'Téléphone personnel (facultatif)'), '06 12 34 56 78');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();

    // Assert
    expect(partners.fichesEnregistrees.single.site, 'https://cap.fr');
    expect(partners.telephonesEnregistres.single, '06 12 34 56 78');
    expect(find.text('Fiche enregistrée.'), findsWidgets); // affiché aussi pendant le retour à l'écran précédent
  });

  testWidgets("visiteur : politique de confidentialité en bas de l'annuaire", (tester) async {
    ecranHaut(tester);
    await lancer(tester);
    await tester.tap(find.text('Annuaire'));
    await tester.pump();
    partners.envoyer([atelier]);
    await tester.pump();
    await tester.tap(find.text('Confidentialité'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('CONFIDENTIALITÉ'), findsOneWidget);
    expect(find.text('Vos droits'), findsOneWidget);
  });
}
