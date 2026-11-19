import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../../../core/format_date.dart';
import '../../../core/widgets/etat_contenu.dart';
import '../../events/logic/events_cubit.dart';
import '../../events/logic/events_state.dart';
import 'evenement_bureau_page.dart';
import 'evenement_form_page.dart';

/// Agenda et historique côté bureau, avec création.
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
          final maintenant = DateTime.now();
          final List<Widget> contenu = switch (state) {
            EventsLoading() => [const SqueletteListe(libelle: 'Chargement des événements')],
            EventsError(:final message) => [
              Text(message),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: context.read<EventsCubit>().charger, child: const Text('Réessayer')),
            ],
            EventsEmpty() => [
              const EtatContenu(
                icone: Icons.event_available_outlined,
                titre: 'Aucun événement à venir',
                message: 'Créez un rendez-vous pour le partager avec les partenaires.',
              ),
            ],
            EventsSuccess() => [
              for (final (titre, evenements) in [
                ('À venir', state.aVenir(maintenant)),
                ('Historique', state.historique(maintenant)),
              ])
                if (evenements.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Semantics(header: true, child: Text(titre, style: theme.textTheme.headlineSmall)),
                  ),
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
