import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/main.dart';

import 'fake_partner_repository.dart';

void main() {
  testWidgets('chercher un expert-comptable et ouvrir sa fiche', (tester) async {
    // Arrange
    final repository = FakePartnerRepository();
    await tester.pumpWidget(ParquetApp(partnerRepository: repository));
    repository.envoyer([atelier, cap, grain]);
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
    final repository = FakePartnerRepository();
    await tester.pumpWidget(ParquetApp(partnerRepository: repository));
    repository.envoyer([atelier], horsLigne: true);
    await tester.pump();
    expect(find.textContaining('Hors connexion'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
