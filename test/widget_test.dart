import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/main.dart';

import 'fake_event_repository.dart';
import 'fake_partner_repository.dart';

void main() {
  late FakePartnerRepository partners;
  late FakeEventRepository events;

  Future<void> lancer(WidgetTester tester) async {
    partners = FakePartnerRepository();
    events = FakeEventRepository();
    await tester.pumpWidget(ParquetApp(partnerRepository: partners, eventRepository: events));
  }

  testWidgets('chercher un expert-comptable et ouvrir sa fiche', (tester) async {
    // Arrange
    await lancer(tester);
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
    partners.envoyer([atelier], horsLigne: true);
    await tester.pump();
    expect(find.textContaining('Hors connexion'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  // Parcours principal du cahier des charges (cours 6) : ouvrir un événement et répondre « Je viens ».
  testWidgets('ouvrir un événement et répondre Je viens à deux, hors connexion', (tester) async {
    // Arrange
    await lancer(tester);
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
}
