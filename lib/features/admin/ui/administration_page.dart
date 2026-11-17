import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../partners/logic/partners_cubit.dart';
import '../data/admin_repository.dart';
import '../logic/admin_cubit.dart';
import '../logic/admin_state.dart';
import 'compte_page.dart';
import 'gestion_evenements_page.dart';
import 'inviter_page.dart';
import 'journal_page.dart';

/// Onglet Administration du bureau : partenaires actifs, invitations, comptes, événements.
class AdministrationPage extends StatelessWidget {
  const AdministrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void ouvrir(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(title: const Text('PARQUET.')),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          final entete = <Widget>[
            Semantics(header: true, child: Text('ADMINISTRATION', style: theme.textTheme.displaySmall)),
            const SizedBox(height: 16),
            _Total(actifs: state is AdminSuccess ? state.actifs : 0),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Inviter un partenaire'),
              onPressed: () => ouvrir(const InviterPage()),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: const Text('Gérer les événements'),
              onPressed: () => ouvrir(const GestionEvenementsPage()),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Journal des actions'),
              onPressed: () => ouvrir(const JournalPage()),
            ),
            const SizedBox(height: 24),
            Semantics(header: true, child: Text('Partenaires', style: theme.textTheme.headlineSmall)),
            const SizedBox(height: 8),
          ];
          final List<Widget> contenu = switch (state) {
            AdminLoading() => [
              const Center(child: CircularProgressIndicator(semanticsLabel: 'Chargement des comptes')),
            ],
            AdminError(:final message) => [
              Text(message),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: context.read<AdminCubit>().charger, child: const Text('Réessayer')),
            ],
            AdminEmpty() => [const Text('Aucun partenaire pour le moment. Invitez le premier.')],
            AdminSuccess(:final comptes) => [
              for (final c in comptes) _Ligne(c, onTap: () => ouvrir(ComptePage(uid: c.uid))),
            ],
          };
          return ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), children: [...entete, ...contenu]);
        },
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.actifs});

  final int actifs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.secondary, borderRadius: BorderRadius.circular(10)),
      child: Semantics(
        label: '$actifs partenaires actifs',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$actifs', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: scheme.onSecondary)),
              Text(actifs > 1 ? 'partenaires actifs' : 'partenaire actif', style: TextStyle(color: scheme.onSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne(this.compte, {required this.onTap});

  final Compte compte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nom = context.read<PartnersCubit>().partenaire(compte.uid)?.nom ?? compte.email;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(nom, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${compte.email} · ${compte.actif ? 'Actif' : 'Désactivé'}'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
