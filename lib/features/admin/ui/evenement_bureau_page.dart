import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../../../core/format_date.dart';
import '../../events/logic/events_cubit.dart';
import '../../events/logic/events_state.dart';
import '../../partners/logic/partners_cubit.dart';
import '../data/admin_repository.dart';
import '../logic/admin_cubit.dart';
import '../logic/admin_state.dart';
import 'confirmer.dart';
import '../../events/ui/etiquette_type.dart';
import 'evenement_form_page.dart';

/// Suivi d'un événement par le bureau (maquette « Suivi par le bureau ») : total et réponses (F13),
/// modification et annulation (F10).
class EvenementBureauPage extends StatelessWidget {
  const EvenementBureauPage({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReponsesCubit(context.read<AdminRepository>(), eventId)..charger(),
      child: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, _) {
          final event = context.read<EventsCubit>().evenement(eventId);
          final theme = Theme.of(context);
          if (event == null) {
            return Scaffold(
              appBar: AppBar(title: const TitreParquet()),
              body: const Center(child: Text("Cet événement n'est plus à venir.")),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const TitreParquet()),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                if (event.type.isNotEmpty) ...[EtiquetteType(event.type), const SizedBox(height: 6)],
                Semantics(header: true, child: Text(event.titre.toUpperCase(), style: theme.textTheme.headlineLarge)),
                Text(
                  [dateLongue(event.date), heure(event.date), if (event.lieu.isNotEmpty) event.lieu].join(' · '),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (event.annule)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Événement annulé', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 16),
                const _Reponses(),
                const SizedBox(height: 16),
                if (!event.annule) ...[
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => EvenementFormPage(existant: event))),
                    child: const Text("Modifier l'événement"),
                  ),
                  const SizedBox(height: 24),
                  // Action destructrice : hors de la zone d'action principale, en rouge, confirmée.
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    onPressed: () async {
                      final cubit = context.read<EventsCubit>();
                      final messager = ScaffoldMessenger.of(context);
                      if (!await confirmer(
                        context,
                        titre: "Annuler l'événement ?",
                        texte: "Les partenaires verront l'événement annulé dans l'app, et leur rappel sera retiré.",
                        action: "Annuler l'événement",
                      )) {
                        return;
                      }
                      cubit.annuler(event.id).catchError((Object _) {
                        messager.showSnackBar(const SnackBar(content: Text("L'annulation a été refusée.")));
                      });
                    },
                    child: const Text("Annuler l'événement"),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Reponses extends StatelessWidget {
  const _Reponses();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return BlocBuilder<ReponsesCubit, ReponsesState>(
      builder: (context, state) {
        final total = state is ReponsesSuccess ? state.total : 0;
        final carte = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: scheme.secondary, borderRadius: BorderRadius.circular(10)),
          child: Semantics(
            label: '$total participants confirmés',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$total', style: theme.textTheme.displaySmall?.copyWith(color: scheme.onSecondary)),
                  Text(
                    total > 1 ? 'participants confirmés' : 'participant confirmé',
                    style: TextStyle(color: scheme.onSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
        final List<Widget> liste = switch (state) {
          ReponsesLoading() => [
            const Center(child: CircularProgressIndicator(semanticsLabel: 'Chargement des réponses')),
          ],
          ReponsesError(:final message) => [
            Text(message),
            OutlinedButton(onPressed: context.read<ReponsesCubit>().charger, child: const Text('Réessayer')),
          ],
          ReponsesEmpty() => [const Text('Aucune réponse pour le moment.')],
          ReponsesSuccess(:final reponses) => [for (final r in reponses) _LigneReponse(r)],
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            carte,
            const SizedBox(height: 24),
            Semantics(header: true, child: Text('Réponses reçues', style: theme.textTheme.headlineSmall)),
            const SizedBox(height: 8),
            ...liste,
          ],
        );
      },
    );
  }
}

class _LigneReponse extends StatelessWidget {
  const _LigneReponse(this.reponse);

  final ReponseBureau reponse;

  @override
  Widget build(BuildContext context) {
    final nom = context.read<PartnersCubit>().partenaire(reponse.uid)?.nom ?? 'Partenaire';
    final detail = reponse.vient ? '${reponse.nbPersonnes} personne${reponse.nbPersonnes > 1 ? 's' : ''}' : 'Absent';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: nom,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' · $detail'),
            ],
          ),
        ),
      ),
    );
  }
}
