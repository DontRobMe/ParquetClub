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
import '../../features/events/logic/events_cubit.dart';
import '../../features/events/logic/events_state.dart';
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

class _OngletsPageState extends State<OngletsPage> with SingleTickerProviderStateMixin {
  int _index = 0;
  StreamSubscription<String>? _ouvertures;
  late final _transition = AnimationController(vsync: this, duration: const Duration(milliseconds: 200), value: 1);
  late final _fondu = _transition.drive(CurveTween(curve: Curves.easeOut));

  void _aller(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    if (MediaQuery.disableAnimationsOf(context)) {
      _transition.value = 1;
    } else {
      _transition.forward(from: 0.28);
    }
  }

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
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final avisEnAttente =
        session != null &&
        !session.estAdmin &&
        context.select((EventsCubit cubit) {
          final state = cubit.state;
          return state is EventsSuccess && state.aNoter(DateTime.now()).isNotEmpty;
        });
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
            (
              EvenementsPage(actif: _index == 1, bureau: session.estAdmin),
              NavigationDestination(
                icon: Badge(isLabelVisible: avisEnAttente, child: const Icon(Icons.event)),
                label: 'Événements',
              ),
            ),
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
      body: FadeTransition(
        opacity: _fondu,
        child: IndexedStack(
          index: _index,
          children: [for (var i = 0; i < onglets.length; i++) TickerMode(enabled: i == _index, child: onglets[i].$1)],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _aller,
        destinations: [for (final (_, destination) in onglets) destination],
      ),
    );
  }
}
