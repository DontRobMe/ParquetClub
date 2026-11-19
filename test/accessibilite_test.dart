import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/main.dart';

import 'fake_admin_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_event_repository.dart';
import 'fake_notification_repository.dart';
import 'fake_partner_repository.dart';
import 'fake_verrou_repository.dart';

/// Audit d'accessibilité (charte, WCAG 2.1 AA) : chaque écran principal, sur un téléphone réel,
/// en taille de texte normale puis doublée (réglage « Taille de police » d'Android au maximum).
void main() {
  late FakePartnerRepository partners;
  late FakeEventRepository events;
  late FakeAdminRepository admin;

  Future<void> lancer(
    WidgetTester tester, {
    required double texte,
    bool connecte = false,
    bool estBureau = false,
  }) async {
    // Pixel 7 : 412 × 915 dp.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    tester.platformDispatcher.textScaleFactorTestValue = texte;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    partners = FakePartnerRepository();
    events = FakeEventRepository();
    admin = FakeAdminRepository();
    await tester.pumpWidget(
      ParquetApp(
        authRepository: FakeAuthRepository(connecteAuDemarrage: connecte, compte: estBureau ? bureau : partenaire),
        partnerRepository: partners,
        eventRepository: events,
        adminRepository: admin,
        notificationRepository: FakeNotificationRepository(aDemander: false),
        verrouRepository: FakeVerrouRepository(estActif: false, reussit: true),
      ),
    );
    await tester.pump();
    if (connecte && !estBureau) {
      partners.fiche.add(maFiche);
      await tester.pump();
    }
  }

  Future<void> verifier(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  }

  Future<void> ouvrir(WidgetTester tester, String texte) async {
    await tester.tap(find.text(texte).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  for (final texte in [1.0, 2.0]) {
    group('texte ×$texte', () {
      testWidgets('visiteur : accueil', (tester) async {
        await lancer(tester, texte: texte);
        await verifier(tester);
      });

      testWidgets('visiteur : annuaire puis fiche', (tester) async {
        await lancer(tester, texte: texte);
        await ouvrir(tester, 'Annuaire');
        partners.envoyer([atelier, cap, grain]);
        await verifier(tester);
        await tester.scrollUntilVisible(find.text('Cap Conseil'), 200, scrollable: find.byType(Scrollable).first);
        await ouvrir(tester, 'Cap Conseil');
        await verifier(tester);
      });

      testWidgets('visiteur : connexion', (tester) async {
        await lancer(tester, texte: texte);
        await ouvrir(tester, 'Connexion');
        await verifier(tester);
      });

      testWidgets('partenaire : agenda puis détail', (tester) async {
        await lancer(tester, texte: texte, connecte: true);
        await ouvrir(tester, 'Événements');
        events.envoyer([soiree, afterwork, voeux]);
        await verifier(tester);
        await tester.scrollUntilVisible(find.text('Afterwork du club'), 200);
        await ouvrir(tester, 'Afterwork du club');
        await verifier(tester);
      });

      testWidgets('partenaire : profil', (tester) async {
        await lancer(tester, texte: texte, connecte: true);
        await ouvrir(tester, 'Mon profil');
        await verifier(tester);
      });

      testWidgets('bureau : administration et événements', (tester) async {
        await lancer(tester, texte: texte, connecte: true, estBureau: true);
        partners.envoyer([cap, grain]);
        events.envoyer([soiree]);
        admin.comptes.add(const []);
        await ouvrir(tester, 'Administration');
        await verifier(tester);
        await ouvrir(tester, 'Gérer les événements');
        await verifier(tester);
      });
    });
  }
}
