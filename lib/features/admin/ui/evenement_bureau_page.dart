import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../../../core/widgets/etat_contenu.dart';
import '../../events/logic/events_cubit.dart';
import '../../events/logic/events_state.dart';
import '../../events/ui/event_detail_page.dart';
import '../../events/ui/lieu_evenement.dart';
import '../../events/ui/visuel_evenement.dart';
import '../../partners/logic/partners_cubit.dart';
import '../data/admin_repository.dart';
import '../logic/admin_cubit.dart';
import '../logic/admin_state.dart';
import 'confirmer.dart';
import 'emargement_page.dart';
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
        builder: (context, state) {
          final event = context.read<EventsCubit>().evenement(eventId);
          final theme = Theme.of(context);
          if (event == null) {
            return Scaffold(
              appBar: AppBar(title: const TitreParquet()),
              body: DetailEvenementIndisponible(state: state),
            );
          }
          final maintenant = DateTime.now();
          final passe = event.estPasse(maintenant);
          return Scaffold(
            appBar: AppBar(title: const TitreParquet()),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                VisuelEvenement(event: event),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (event.annule) ...[
                        const Text('Événement annulé', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                      ],
                      if (event.emargementOuvert(maintenant)) ...[
                        FilledButton.icon(
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Émargement'),
                          onPressed: () {
                            final reponses = context.read<ReponsesCubit>();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BlocProvider.value(
                                  value: reponses,
                                  child: EmargementPage(event: event),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _Reponses(afficherAvis: passe && !event.annule),
                      if (event.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(event.description.trim(), style: theme.textTheme.bodyLarge),
                      ],
                      if (event.lieu.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        LieuEvenement(lieu: event.lieu.trim()),
                      ],
                      if (!event.annule) ...[
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context)
                                  .push(MaterialPageRoute<void>(builder: (_) => EvenementFormPage(existant: event))),
                          child: const Text("Modifier l'événement"),
                        ),
                      ],
                      if (!event.annule && !passe) ...[
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
                              texte:
                                  "Les partenaires verront l'événement annulé dans l'app, et leur rappel sera retiré.",
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Reponses extends StatelessWidget {
  const _Reponses({required this.afficherAvis});

  final bool afficherAvis;

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
          ReponsesLoading() => [const SqueletteListe(libelle: 'Chargement des réponses')],
          ReponsesError(:final message) => [
            Text(message),
            OutlinedButton(onPressed: context.read<ReponsesCubit>().charger, child: const Text('Réessayer')),
          ],
          ReponsesEmpty() => [
            const EtatContenu(
              icone: Icons.inbox_outlined,
              titre: 'Aucune réponse pour le moment.',
              message: 'Les confirmations et les refus des partenaires apparaîtront ici.',
            ),
          ],
          ReponsesSuccess(:final reponses) when reponses.any((r) => r.aRepondu) => [
            for (final r in reponses)
              if (r.aRepondu) _LigneReponse(r),
          ],
          ReponsesSuccess() => [const Text("Aucune réponse à l'invitation.")],
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state is ReponsesSuccess && state.reponses.any((r) => r.aRepondu)) ...[
              carte,
              const SizedBox(height: 20),
            ],
            Semantics(header: true, child: Text('Réponses reçues', style: theme.textTheme.headlineSmall)),
            const SizedBox(height: 8),
            ...liste,
            if (afficherAvis && (state is ReponsesSuccess || state is ReponsesEmpty)) ...[
              const SizedBox(height: 24),
              _AvisRecus(reponses: state is ReponsesSuccess ? state.reponses : const []),
            ],
          ],
        );
      },
    );
  }
}

class _AvisRecus extends StatelessWidget {
  const _AvisRecus({required this.reponses});

  final List<ReponseBureau> reponses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final annuaire = context.watch<PartnersCubit>();
    final avis = reponses.where((r) => r.avis != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text('Avis des participants', style: theme.textTheme.headlineSmall)),
        const SizedBox(height: 8),
        if (avis.isEmpty)
          const EtatContenu(icone: Icons.star_outline_rounded, titre: 'Aucun avis reçu')
        else ...[
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(Icons.star_rounded, color: theme.colorScheme.onPrimaryContainer),
              title: Text(
                '${(avis.fold(0, (total, r) => total + r.avis!.note) / avis.length).toStringAsFixed(1).replaceAll('.', ',')} / 5',
                style: theme.textTheme.headlineSmall,
              ),
              subtitle: Text('Note moyenne · ${avis.length} avis'),
            ),
          ),
          for (final reponse in avis)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('${annuaire.partenaire(reponse.uid)?.nom ?? 'Partenaire'} · ${reponse.avis!.note}/5'),
                subtitle: reponse.avis!.commentaire.isEmpty ? null : Text(reponse.avis!.commentaire),
              ),
            ),
        ],
      ],
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
