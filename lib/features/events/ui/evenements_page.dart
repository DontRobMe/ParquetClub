import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../../../core/format_date.dart';
import '../../../core/widgets/bandeau_hors_ligne.dart';
import '../../../core/widgets/etat_contenu.dart';
import '../../admin/ui/evenement_bureau_page.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import '../data/event.dart';
import '../logic/events_cubit.dart';
import '../logic/events_state.dart';
import 'avis_evenement_sheet.dart';
import 'event_detail_page.dart';
import 'visuel_evenement.dart';

/// Agenda du partenaire (F11) : la prochaine invitation en tête, puis « À suivre ».
class EvenementsPage extends StatelessWidget {
  const EvenementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TitreParquet()),
      body: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, state) => switch (state) {
          EventsLoading() => const SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: SqueletteListe(libelle: 'Chargement des événements', avecVisuel: true),
          ),
          EventsError(:final message) => _Erreur(message),
          EventsEmpty(:final horsLigne, :final derniereSynchro) => _contenu(
            EventsSuccess(evenements: const [], horsLigne: horsLigne, derniereSynchro: derniereSynchro),
          ),
          EventsSuccess() => _contenu(state),
        },
      ),
    );
  }

  Widget _contenu(EventsSuccess state) {
    final liste = state.aVenir(DateTime.now());
    return Column(
      children: [
        if (state.horsLigne) BandeauHorsLigne(derniereSynchro: state.derniereSynchro),
        Expanded(
          child: liste.isEmpty
              ? const Center(
                  child: SingleChildScrollView(
                    child: EtatContenu(
                      icone: Icons.event_available_outlined,
                      titre: 'Aucun événement à venir',
                      message: 'Les prochains rendez-vous du club apparaîtront ici.',
                    ),
                  ),
                )
              : _Agenda(liste: liste, reponses: state.reponses),
        ),
      ],
    );
  }
}

void _ouvrirEvenement(BuildContext context, String eventId) {
  final auth = context.read<AuthCubit>().state;
  final bureau = auth is AuthConnecte && auth.session.estAdmin;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => bureau ? EvenementBureauPage(eventId: eventId) : EventDetailPage(eventId: eventId),
    ),
  );
}

class _Agenda extends StatelessWidget {
  const _Agenda({required this.liste, required this.reponses});

  final List<Event> liste;
  final Map<String, EventResponse> reponses;

  @override
  Widget build(BuildContext context) {
    final prochain = liste.where((e) => !e.annule).firstOrNull;
    final suivants = liste.where((e) => e != prochain);
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (prochain != null) _ProchaineInvitation(prochain, reponses[prochain.id]),
        if (suivants.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Semantics(header: true, child: Text('À suivre', style: Theme.of(context).textTheme.headlineSmall)),
          ),
        for (final e in suivants)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: LigneEvenement(e, reponses[e.id]),
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
    final auth = context.read<AuthCubit>().state;
    final bureau = auth is AuthConnecte && auth.session.estAdmin;
    final peutNoter = reponse?.peutNoter(event, DateTime.now()) ?? false;
    final statut = texteStatut(event, reponse, passe: reponse?.presence == true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VisuelEvenement(event: event, surtitre: bureau ? 'Prochain événement' : 'Prochaine invitation'),
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
              if (event.statut == EventStatut.modifie)
                const Text('Modifié par le club', style: TextStyle(fontWeight: FontWeight.w700)),
              if (!bureau && statut != null) ...[
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
              if (!bureau && peutNoter)
                FilledButton.icon(
                  icon: const Icon(Icons.star_outline_rounded),
                  label: const Text('Donner mon avis'),
                  onPressed: () => ouvrirAvisEvenement(context, event),
                )
              else
                FilledButton.icon(
                  icon: Icon(bureau ? Icons.groups_outlined : Icons.arrow_forward),
                  label: Text(
                    bureau
                        ? 'Voir les réponses'
                        : reponse == null
                        ? "Répondre à l'invitation"
                        : 'Voir ma réponse',
                  ),
                  onPressed: () => _ouvrirEvenement(context, event.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class LigneEvenement extends StatelessWidget {
  const LigneEvenement(this.event, this.reponse, {super.key, this.historique = false, this.aNoter = false});

  final Event event;
  final EventResponse? reponse;
  final bool historique;
  final bool aNoter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      if (event.type.isNotEmpty) event.type,
      if (historique) '${event.date.year}' else heure(event.date),
      ?texteStatut(event, reponse, passe: historique),
    ].join(' · ');
    // Ligne maison plutôt qu'un ListTile : ListTile bloque la hauteur de la pastille,
    // qui débordait avec le texte agrandi (WCAG 1.4.4).
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _ouvrirEvenement(context, event.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Semantics(
                label: dateLongue(event.date),
                child: ExcludeSemantics(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.titre,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: event.annule ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(details, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    if (aNoter)
                      Text(
                        'À noter',
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }
}

/// Statut en texte, jamais seulement en couleur (charte, accessibilité).
String? texteStatut(Event event, EventResponse? reponse, {bool passe = false}) {
  if (event.annule) return 'Annulé';
  if (passe) {
    final avis = reponse?.avis;
    if (avis != null) return 'Votre note · ${avis.note}/5';
    return switch (reponse?.presence) {
      true => 'Présence validée',
      false => 'Absent',
      null => null,
    };
  }
  return switch (reponse) {
    null => null,
    EventResponse(aRepondu: false) => null,
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
      child: SingleChildScrollView(
        child: EtatContenu(
          icone: Icons.sync_problem,
          titre: 'Agenda indisponible',
          message: message,
          action: FilledButton(onPressed: context.read<EventsCubit>().charger, child: const Text('Réessayer')),
        ),
      ),
    );
  }
}
