import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../../../core/format_date.dart';
import '../../../core/widgets/bandeau_hors_ligne.dart';
import '../data/event.dart';
import '../logic/events_cubit.dart';
import '../logic/events_state.dart';
import 'event_detail_page.dart';

/// Agenda du partenaire (F11) : la prochaine invitation en tête, puis « À suivre ».
class EvenementsPage extends StatelessWidget {
  const EvenementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TitreParquet()),
      body: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, state) => switch (state) {
          EventsLoading() => const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Chargement des événements'),
          ),
          EventsError(:final message) => _Erreur(message),
          EventsEmpty(:final horsLigne, :final derniereSynchro) => Column(
            children: [
              if (horsLigne) BandeauHorsLigne(derniereSynchro: derniereSynchro),
              const Expanded(child: Center(child: Text('Aucun événement à venir'))),
            ],
          ),
          EventsSuccess() => _Agenda(state),
        },
      ),
    );
  }
}

void ouvrirEvenement(BuildContext context, String eventId) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EventDetailPage(eventId: eventId)));

class _Agenda extends StatelessWidget {
  const _Agenda(this.state);

  final EventsSuccess state;

  @override
  Widget build(BuildContext context) {
    final prochain = state.evenements.where((e) => !e.annule).firstOrNull;
    final suivants = state.evenements.where((e) => e != prochain).toList();
    return Column(
      children: [
        if (state.horsLigne) BandeauHorsLigne(derniereSynchro: state.derniereSynchro),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (prochain != null) _ProchaineInvitation(prochain, state.reponses[prochain.id]),
              if (suivants.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Semantics(
                    header: true,
                    child: Text('À suivre', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                ),
              for (final e in suivants)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: _Ligne(e, state.reponses[e.id]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Visuel, date et action dans la même zone (charte : référence NBA App).
class _ProchaineInvitation extends StatelessWidget {
  const _ProchaineInvitation(this.event, this.reponse);

  final Event event;
  final EventResponse? reponse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const blanc = TextStyle(color: Colors.white);
    final statut = texteStatut(event, reponse);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/terrain.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.topRight,
                excludeFromSemantics: true,
              ),
            ),
            // Dégradé noir sous le titre blanc : le contraste ne dépend pas du recadrage de la photo.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0xEE000000)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'PROCHAINE INVITATION',
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    header: true,
                    child: Text(event.titre.toUpperCase(), style: theme.textTheme.displaySmall?.merge(blanc)),
                  ),
                  const SizedBox(height: 4),
                  Text('${dateLongue(event.date)} · ${heure(event.date)}', style: blanc),
                  if (event.statut == EventStatut.modifie)
                    Text('Modifié par le club', style: blanc.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (event.lieu.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(event.lieu, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ],
                ),
              // Sa réponse visible sans ouvrir l'invitation (maquette).
              if (statut != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      reponse!.enAttente ? Icons.schedule : Icons.check_circle_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(statut, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: Text(reponse == null ? "Répondre à l'invitation" : 'Voir ma réponse'),
                onPressed: () => ouvrirEvenement(context, event.id),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne(this.event, this.reponse);

  final Event event;
  final EventResponse? reponse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      if (event.type.isNotEmpty) event.type,
      heure(event.date),
      ?texteStatut(event, reponse),
    ].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Semantics(
          label: dateLongue(event.date),
          child: ExcludeSemantics(
            child: Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: theme.colorScheme.outline, borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${event.date.day}', style: theme.textTheme.titleLarge?.copyWith(height: 1)),
                  Text(moisCourt(event.date), style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          event.titre,
          style: TextStyle(fontWeight: FontWeight.w700, decoration: event.annule ? TextDecoration.lineThrough : null),
        ),
        subtitle: Text(details),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => ouvrirEvenement(context, event.id),
      ),
    );
  }
}

/// Statut en texte, jamais seulement en couleur (charte, accessibilité).
String? texteStatut(Event event, EventResponse? reponse) {
  if (event.annule) return 'Annulé';
  return switch (reponse) {
    null => null,
    EventResponse(enAttente: true) => 'En attente de synchronisation',
    EventResponse(vient: true, :final nbPersonnes) =>
      'Vous venez · $nbPersonnes ${nbPersonnes > 1 ? 'personnes' : 'personne'}',
    EventResponse(vient: false) => 'Vous ne venez pas',
  };
}

class _Erreur extends StatelessWidget {
  const _Erreur(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: context.read<EventsCubit>().charger, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
