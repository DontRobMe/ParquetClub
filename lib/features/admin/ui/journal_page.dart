import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format_date.dart';
import '../data/admin_repository.dart';
import '../logic/admin_cubit.dart';
import '../logic/admin_state.dart';

/// F18. Qui a créé, modifié, désactivé ou supprimé quoi : utile si le compte d'un bénévole est volé.
class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (context) => JournalCubit(context.read<AdminRepository>())..charger(),
      child: Scaffold(
        appBar: AppBar(title: const Text('PARQUET.')),
        body: BlocBuilder<JournalCubit, JournalState>(
          builder: (context, state) {
            final List<Widget> contenu = switch (state) {
              JournalLoading() => [const Center(child: CircularProgressIndicator(semanticsLabel: 'Chargement'))],
              JournalError(:final message) => [
                Text(message),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: context.read<JournalCubit>().charger, child: const Text('Réessayer')),
              ],
              JournalEmpty() => [const Text('Aucune action enregistrée pour le moment.')],
              JournalSuccess(:final entrees) => [for (final e in entrees) _Ligne(e)],
            };
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Semantics(header: true, child: Text('JOURNAL', style: theme.textTheme.displaySmall)),
                Text(
                  'Les 100 dernières actions du bureau.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                ...contenu,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne(this.entree);

  final EntreeJournal entree;

  @override
  Widget build(BuildContext context) {
    final date = entree.date;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${entree.action} : ${entree.cible}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text([entree.auteur, if (date != null) '${dateLongue(date)} · ${heure(date)}'].join(' · ')),
      ),
    );
  }
}
