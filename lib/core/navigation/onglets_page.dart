import 'package:flutter/material.dart';

import '../../features/events/ui/evenements_page.dart';
import '../../features/partners/ui/annuaire_page.dart';

/// Onglets en bas, dans la zone du pouce (cours 5).
// ponytail: provisoire, Annuaire + Événements pour tout le monde ; les onglets par rôle
// (Mon profil, Administration, visiteur sans Événements) arrivent avec la connexion.
class OngletsPage extends StatefulWidget {
  const OngletsPage({super.key});

  @override
  State<OngletsPage> createState() => _OngletsPageState();
}

class _OngletsPageState extends State<OngletsPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack garde chaque onglet vivant : on retrouve sa recherche ou sa position en revenant.
      body: IndexedStack(index: _index, children: const [AnnuairePage(), EvenementsPage()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Annuaire'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Événements'),
        ],
      ),
    );
  }
}
