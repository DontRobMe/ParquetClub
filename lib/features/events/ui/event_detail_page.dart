import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../../../core/widgets/etat_contenu.dart';
import '../../admin/ui/evenement_bureau_page.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import '../data/event.dart';
import '../logic/events_cubit.dart';
import '../logic/events_state.dart';
import 'avis_evenement_sheet.dart';
import 'evenements_page.dart';
import 'lieu_evenement.dart';
import 'visuel_evenement.dart';

const _maxPersonnes = 10; // même borne que les règles Firestore

/// Détail d'une invitation et réponse « Je viens / Je ne viens pas » (F11, F12).
class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  /// État purement local du compteur : setState suffit (cahier des charges, partie 4).
  int? _nbPersonnes;
  bool _rappelPropose = false; // une seule proposition par écran

  EventResponse? _reponse(EventsState s) => s is EventsSuccess ? s.reponses[widget.eventId] : null;

  Future<void> _repondre(bool vient, int nb) async {
    final cubit = context.read<EventsCubit>();
    final messager = ScaffoldMessenger.of(context);
    // Pas d'await : hors ligne, la réponse s'affiche tout de suite « En attente de synchronisation ».
    cubit.repondre(widget.eventId, vient: vient, nbPersonnes: nb).catchError((Object _) {
      messager.showSnackBar(const SnackBar(content: Text("Réponse refusée par le serveur. Réessayez plus tard.")));
    });
    // « Je viens » programme un rappel : c'est le moment où la permission sert (cours 3, OWASP M6).
    if (vient && !_rappelPropose && await cubit.rappelsADemander()) {
      _rappelPropose = true;
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Un rappel 2 jours avant ?'),
          content: const Text('Parquet peut vous envoyer une notification 2 jours avant cet événement.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non merci')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continuer')),
          ],
        ),
      );
      if (ok == true) await cubit.autoriserRappels();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Confirme quand la réponse quitte la file d'attente (retour du réseau).
    return BlocListener<EventsCubit, EventsState>(
      listenWhen: (avant, apres) => _reponse(avant)?.enAttente == true && _reponse(apres)?.enAttente == false,
      listener: (context, _) =>
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réponse envoyée au club.'))),
      child: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, state) {
          final event = context.read<EventsCubit>().evenement(widget.eventId);
          if (event == null) {
            return Scaffold(
              appBar: AppBar(title: const TitreParquet()),
              body: DetailEvenementIndisponible(state: state),
            );
          }
          final reponse = _reponse(state);
          // F12 est réservée aux partenaires : le bureau suit les réponses, il ne répond pas.
          final auth = context.read<AuthCubit>().state;
          final bureau = auth is AuthConnecte && auth.session.estAdmin;
          final maintenant = DateTime.now();
          final suivi = event.estPasse(maintenant) || (reponse?.presence == true && event.emargementOuvert(maintenant));
          final peutNoter = !bureau && (reponse?.peutNoter(event, maintenant) ?? false);
          final nb = _nbPersonnes ?? ((reponse?.vient ?? false) ? reponse!.nbPersonnes : 1);
          return Scaffold(
            appBar: AppBar(title: const TitreParquet()),
            body: _Infos(event: event, reponse: bureau ? null : reponse, passe: suivi),
            // Action principale en bas, pleine largeur, dans la zone du pouce (cours 5).
            bottomNavigationBar: bureau
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute<void>(builder: (_) => EvenementBureauPage(eventId: event.id))),
                        icon: const Icon(Icons.groups_outlined),
                        label: const Text('Voir les réponses'),
                      ),
                    ),
                  )
                : peutNoter
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: FilledButton.icon(
                        onPressed: () => ouvrirAvisEvenement(context, event),
                        icon: const Icon(Icons.star_outline_rounded),
                        label: const Text('Noter cet événement'),
                      ),
                    ),
                  )
                : event.annule || suivi
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Compteur(valeur: nb, onChange: (v) => setState(() => _nbPersonnes = v)),
                          const SizedBox(height: 8),
                          FilledButton(onPressed: () => _repondre(true, nb), child: const Text('Je viens')),
                          const SizedBox(height: 8),
                          OutlinedButton(onPressed: () => _repondre(false, 0), child: const Text('Je ne viens pas')),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class DetailEvenementIndisponible extends StatelessWidget {
  const DetailEvenementIndisponible({super.key, required this.state});

  final EventsState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: switch (state) {
          EventsLoading() => const Padding(
            padding: EdgeInsets.all(20),
            child: SqueletteListe(libelle: "Chargement de l'événement", avecVisuel: true, lignes: 2),
          ),
          EventsError(:final message) => EtatContenu(
            icone: Icons.sync_problem,
            titre: 'Événement indisponible',
            message: message,
            action: FilledButton(onPressed: context.read<EventsCubit>().charger, child: const Text('Réessayer')),
          ),
          _ => const EtatContenu(
            icone: Icons.event_busy_outlined,
            titre: "Cet événement n'est plus à venir.",
            message: "Retrouvez les prochains rendez-vous dans l'agenda.",
          ),
        },
      ),
    );
  }
}

class _Infos extends StatelessWidget {
  const _Infos({required this.event, required this.reponse, required this.passe});

  final Event event;
  final EventResponse? reponse;
  final bool passe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statut = texteStatut(event, reponse, passe: passe);
    final lieu = event.lieu.trim();
    final description = event.description.trim();
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        VisuelEvenement(event: event),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (statut != null)
                Semantics(
                  liveRegion: true,
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: reponse?.enAttente == true
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          event.annule
                              ? Icons.event_busy_outlined
                              : reponse?.enAttente == true
                              ? Icons.schedule
                              : Icons.check_circle_outline,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            event.annule ? 'Cet événement est annulé.' : statut,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (event.statut == EventStatut.modifie)
                const Text('Date, heure ou lieu modifiés par le club.', style: TextStyle(fontWeight: FontWeight.w700)),
              if (description.isNotEmpty) ...[
                if (statut != null || event.statut == EventStatut.modifie) const SizedBox(height: 16),
                Text(description, style: theme.textTheme.bodyLarge),
              ],
              if (lieu.isNotEmpty) ...[
                if (statut != null || event.statut == EventStatut.modifie || description.isNotEmpty)
                  const SizedBox(height: 20),
                LieuEvenement(lieu: lieu),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Nombre de personnes, avec des cibles de 48 dp et des libellés pour le lecteur d'écran.
class _Compteur extends StatelessWidget {
  const _Compteur({required this.valeur, required this.onChange});

  final int valeur;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text('Nombre de personnes')),
        IconButton(
          tooltip: 'Une personne de moins',
          onPressed: valeur > 1 ? () => onChange(valeur - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Semantics(liveRegion: true, child: Text('$valeur', style: Theme.of(context).textTheme.titleLarge)),
        IconButton(
          tooltip: 'Une personne de plus',
          onPressed: valeur < _maxPersonnes ? () => onChange(valeur + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
