import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../../../core/format_date.dart';
import '../../events/logic/events_cubit.dart';
import '../../events/logic/events_state.dart';
import 'evenement_bureau_page.dart';
import 'evenement_form_page.dart';

/// Liste des événements à venir côté bureau, avec création (F10).
class GestionEvenementsPage extends StatelessWidget {
  const GestionEvenementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void ouvrir(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(title: const TitreParquet()),
      body: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, state) {
          final List<Widget> contenu = switch (state) {
            EventsLoading() => [const Center(child: CircularProgressIndicator(semanticsLabel: 'Chargement'))],
            EventsError(:final message) => [
              Text(message),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: context.read<EventsCubit>().charger, child: const Text('Réessayer')),
            ],
            EventsEmpty() => [const Text('Aucun événement à venir.')],
            EventsSuccess(:final evenements) => [
              for (final e in evenements)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(e.titre, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([dateLongue(e.date), heure(e.date), if (e.annule) 'Annulé'].join(' · ')),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => ouvrir(EvenementBureauPage(eventId: e.id)),
                  ),
                ),
            ],
          };
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Semantics(header: true, child: Text('ÉVÉNEMENTS', style: theme.textTheme.displaySmall)),
              const SizedBox(height: 16),
              ...contenu,
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Créer un événement'),
            onPressed: () => ouvrir(const EvenementFormPage()),
          ),
        ),
      ),
    );
  }
}
