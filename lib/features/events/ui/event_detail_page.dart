import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format_date.dart';
import '../data/event.dart';
import '../logic/events_cubit.dart';
import '../logic/events_state.dart';
import 'evenements_page.dart';

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

  EventResponse? _reponse(EventsState s) => s is EventsSuccess ? s.reponses[widget.eventId] : null;

  void _repondre(bool vient, int nb) {
    final cubit = context.read<EventsCubit>();
    final messager = ScaffoldMessenger.of(context);
    // Pas d'await : hors ligne, la réponse s'affiche tout de suite « En attente de synchronisation ».
    cubit.repondre(widget.eventId, vient: vient, nbPersonnes: nb).catchError((Object _) {
      messager.showSnackBar(const SnackBar(content: Text("Réponse refusée par le serveur. Réessayez plus tard.")));
    });
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
              appBar: AppBar(title: const Text('PARQUET.')),
              body: const Center(child: Text("Cet événement n'est plus à venir.")),
            );
          }
          final reponse = _reponse(state);
          final nb = _nbPersonnes ?? ((reponse?.vient ?? false) ? reponse!.nbPersonnes : 1);
          return Scaffold(
            appBar: AppBar(title: const Text('PARQUET.')),
            body: _Infos(event: event, reponse: reponse),
            // Action principale en bas, pleine largeur, dans la zone du pouce (cours 5).
            bottomNavigationBar: event.annule
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

class _Infos extends StatelessWidget {
  const _Infos({required this.event, required this.reponse});

  final Event event;
  final EventResponse? reponse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaire = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final statut = texteStatut(event, reponse);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        if (event.type.isNotEmpty)
          Text(event.type, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
        Semantics(header: true, child: Text(event.titre.toUpperCase(), style: theme.textTheme.headlineLarge)),
        const SizedBox(height: 8),
        Text('${dateLongue(event.date)} · ${heure(event.date)}', style: secondaire),
        if (event.lieu.isNotEmpty) Text(event.lieu, style: secondaire),
        if (event.statut == EventStatut.modifie) ...[
          const SizedBox(height: 8),
          const Text('Date, heure ou lieu modifiés par le club.', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
        if (event.description.isNotEmpty) ...[const SizedBox(height: 16), Text(event.description)],
        if (statut != null) ...[
          const SizedBox(height: 24),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(
                    reponse?.enAttente == true ? Icons.schedule : Icons.check_circle_outline,
                    color: theme.colorScheme.onSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.annule ? 'Cet événement est annulé.' : statut,
                      style: TextStyle(color: theme.colorScheme.onSecondary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
