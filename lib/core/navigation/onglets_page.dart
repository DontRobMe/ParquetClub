import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/admin/ui/administration_page.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/logic/auth_cubit.dart';
import '../../features/events/ui/event_detail_page.dart';
import '../../features/auth/ui/accueil_page.dart';
import '../../features/auth/ui/connexion_page.dart';
import '../../features/auth/ui/profil_page.dart';
import '../../features/events/ui/evenements_page.dart';
import '../../features/partners/ui/annuaire_page.dart';

/// Onglets en bas, dans la zone du pouce (cours 5), calculés à partir de la session.
/// Visiteur : Club, Annuaire, Connexion. Partenaire : Annuaire, Événements, Mon profil.
/// Bureau : les mêmes et Administration. Masquer l'onglet ne protège rien : le serveur revérifie le rôle.
class OngletsPage extends StatefulWidget {
  const OngletsPage({super.key, this.session});

  /// null pour un visiteur.
  final Session? session;

  @override
  State<OngletsPage> createState() => _OngletsPageState();
}

class _OngletsPageState extends State<OngletsPage> {
  int _index = 0;
  StreamSubscription<String>? _ouvertures;

  void _aller(int i) => setState(() => _index = i);

  @override
  void initState() {
    super.initState();
    if (widget.session == null) return; // un visiteur ne voit aucune demande de permission
    final auth = context.read<AuthCubit>();
    // Appui sur un rappel : ouvrir le détail de l'événement.
    _ouvertures = auth.evenementsOuverts.listen((id) {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EventDetailPage(eventId: id)));
    });
  }

  @override
  void dispose() {
    _ouvertures?.cancel();
    super.dispose();
  }

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
            if (session.estAdmin)
              (
                const AdministrationPage(),
                const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Administration'),
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
