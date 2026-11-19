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
class EvenementsPage extends StatefulWidget {
  const EvenementsPage({super.key, required this.actif, required this.bureau});

  final bool actif;
  final bool bureau;

  @override
  State<EvenementsPage> createState() => _EvenementsPageState();
}

class _EvenementsPageState extends State<EvenementsPage> {
  bool _historique = false;
  bool _proposePendantVisite = false;

  @override
  void didUpdateWidget(covariant EvenementsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.actif) _proposePendantVisite = false;
    if (widget.actif && !oldWidget.actif) _proposerAvis();
  }

  void _proposerAvis() {
    if (widget.bureau || !widget.actif || _proposePendantVisite) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.actif || _proposePendantVisite || ModalRoute.of(context)?.isCurrent != true) return;
      final state = context.read<EventsCubit>().state;
      if (state is! EventsSuccess) return;
      final event = state.aNoter(DateTime.now()).firstOrNull;
      if (event == null) return;
      _proposePendantVisite = true;
      setState(() => _historique = true);
      ouvrirAvisEvenement(context, event);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TitreParquet()),
      body: BlocConsumer<EventsCubit, EventsState>(
        listener: (_, _) => _proposerAvis(),
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
    final maintenant = DateTime.now();
    final aNoter = state.aNoter(maintenant).map((e) => e.id).toSet();
    final liste = _historique ? state.historique(maintenant) : state.aVenir(maintenant);
    return Column(
      children: [
        if (state.horsLigne) BandeauHorsLigne(derniereSynchro: state.derniereSynchro),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(value: false, label: Text('À venir')),
                ButtonSegment(
                  value: true,
                  label: Badge(
                    isLabelVisible: aNoter.isNotEmpty,
                    label: Text('${aNoter.length}', semanticsLabel: '${aNoter.length} avis à laisser'),
                    offset: const Offset(13, -7),
                    child: const Text('Historique'),
                  ),
                ),
              ],
              selected: {_historique},
              onSelectionChanged: (choix) => setState(() => _historique = choix.single),
            ),
          ),
        ),
        Expanded(
          child: liste.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: EtatContenu(
                      icone: _historique ? Icons.history : Icons.event_available_outlined,
                      titre: _historique ? 'Aucun événement passé' : 'Aucun événement à venir',
                      message: _historique
                          ? 'Les rendez-vous terminés apparaîtront ici.'
                          : 'Les prochains rendez-vous du club apparaîtront ici.',
                    ),
                  ),
                )
              : _Agenda(liste: liste, reponses: state.reponses, historique: _historique, aNoter: aNoter),
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
  const _Agenda({required this.liste, required this.reponses, required this.historique, required this.aNoter});

  final List<Event> liste;
  final Map<String, EventResponse> reponses;
  final bool historique;
  final Set<String> aNoter;

  @override
  Widget build(BuildContext context) {
    final prochain = historique ? null : liste.where((e) => !e.annule).firstOrNull;
    final suivants = liste.where((e) => e != prochain);
    return ListView(
      key: PageStorageKey(historique),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (prochain != null) _ProchaineInvitation(prochain, reponses[prochain.id]),
        if (!historique && suivants.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Semantics(header: true, child: Text('À suivre', style: Theme.of(context).textTheme.headlineSmall)),
          ),
        for (final e in suivants)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: _Ligne(e, reponses[e.id], historique: historique, aNoter: aNoter.contains(e.id)),
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
    final statut = texteStatut(event, reponse);
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

class _Ligne extends StatelessWidget {
  const _Ligne(this.event, this.reponse, {required this.historique, required this.aNoter});

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
                  ],
                ),
              ),
              if (aNoter)
                Chip(
                  avatar: Icon(Icons.star_outline_rounded, color: theme.colorScheme.onPrimaryContainer, size: 18),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  label: const Text('À noter'),
                )
              else
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
