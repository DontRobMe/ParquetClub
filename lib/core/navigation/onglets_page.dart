import 'package:flutter/material.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/ui/accueil_page.dart';
import '../../features/auth/ui/connexion_page.dart';
import '../../features/auth/ui/profil_page.dart';
import '../../features/events/ui/evenements_page.dart';
import '../../features/partners/ui/annuaire_page.dart';

/// Onglets en bas, dans la zone du pouce (cours 5), calculés à partir de la session.
/// Visiteur : Club, Annuaire, Connexion. Partenaire et bureau : Annuaire, Événements, Mon profil.
// ponytail: l'onglet Administration du bureau arrive avec ses écrans (F3 à F5, F10, F13).
class OngletsPage extends StatefulWidget {
  const OngletsPage({super.key, this.session});

  /// null pour un visiteur.
  final Session? session;

  @override
  State<OngletsPage> createState() => _OngletsPageState();
}

class _OngletsPageState extends State<OngletsPage> {
  int _index = 0;

  void _aller(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final List<(Widget, NavigationDestination)> onglets = session == null
        ? [
            (
              AccueilPage(voirPartenaires: () => _aller(1), seConnecter: () => _aller(2)),
              const NavigationDestination(icon: Icon(Icons.sports_basketball), label: 'Club'),
            ),
            (const AnnuairePage(), const NavigationDestination(icon: Icon(Icons.grid_view), label: 'Annuaire')),
            (const ConnexionPage(), const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Connexion')),
          ]
        : [
            (const AnnuairePage(), const NavigationDestination(icon: Icon(Icons.grid_view), label: 'Annuaire')),
            (const EvenementsPage(), const NavigationDestination(icon: Icon(Icons.event), label: 'Événements')),
            (
              ProfilPage(session: session),
              const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Mon profil'),
            ),
          ];

    return Scaffold(
      // IndexedStack garde chaque onglet vivant : on retrouve sa recherche ou sa position en revenant.
      body: IndexedStack(index: _index, children: [for (final (page, _) in onglets) page]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _aller,
        destinations: [for (final (_, destination) in onglets) destination],
      ),
    );
  }
}
