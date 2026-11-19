import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/etat_contenu.dart';
import '../../../core/widgets/titre_parquet.dart';
import '../../events/data/event.dart';
import '../../events/logic/events_cubit.dart';
import '../../partners/logic/partners_cubit.dart';
import '../data/admin_repository.dart';
import '../logic/admin_cubit.dart';
import '../logic/admin_state.dart';

class EmargementPage extends StatelessWidget {
  const EmargementPage({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final reponses = context.watch<ReponsesCubit>().state;
    final comptes = context.watch<AdminCubit>().state;
    final actuel = context.watch<EventsCubit>().evenement(event.id);
    final Widget contenu;
    if (actuel?.emargementOuvert(DateTime.now()) != true) {
      contenu = const EtatContenu(icone: Icons.event_busy_outlined, titre: 'Émargement indisponible');
    } else if (reponses is ReponsesError || comptes is AdminError) {
      contenu = EtatContenu(
        icone: Icons.sync_problem,
        titre: 'Liste indisponible',
        action: OutlinedButton(
          onPressed: () {
            if (reponses is ReponsesError) context.read<ReponsesCubit>().charger();
            if (comptes is AdminError) context.read<AdminCubit>().charger();
          },
          child: const Text('Réessayer'),
        ),
      );
    } else if (reponses is ReponsesLoading || comptes is AdminLoading) {
      contenu = const SqueletteListe(libelle: 'Chargement des participants');
    } else {
      final suivis = {
        if (reponses is ReponsesSuccess)
          for (final r in reponses.reponses) r.uid: r,
      };
      final actifs = comptes is AdminSuccess ? comptes.comptes.where((c) => c.actif) : const <Compte>[];
      final annuaire = context.watch<PartnersCubit>();
      final noms = <String, String>{
        for (final uid in suivis.keys) uid: annuaire.partenaire(uid)?.nom ?? 'Partenaire',
        for (final compte in actifs) compte.uid: annuaire.partenaire(compte.uid)?.nom ?? compte.email,
      };
      final nomsTries = noms.entries.toList()..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
      final presents = suivis.values.where((r) => r.presence == true).length;
      contenu = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (noms.isEmpty)
            const EtatContenu(icone: Icons.group_outlined, titre: 'Aucun partenaire à émarger')
          else ...[
            Text('$presents présent${presents > 1 ? 's' : ''} sur ${noms.length}'),
            const SizedBox(height: 12),
            for (final nom in nomsTries)
              _LignePresence(key: ValueKey(nom.key), uid: nom.key, nom: nom.value, reponse: suivis[nom.key]),
          ],
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const TitreParquet()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Semantics(header: true, child: Text('ÉMARGEMENT', style: Theme.of(context).textTheme.displaySmall)),
          Text(event.titre),
          const SizedBox(height: 20),
          contenu,
        ],
      ),
    );
  }
}

class _LignePresence extends StatefulWidget {
  const _LignePresence({super.key, required this.uid, required this.nom, this.reponse});

  final String uid;
  final String nom;
  final ReponseBureau? reponse;

  @override
  State<_LignePresence> createState() => _LignePresenceState();
}

class _LignePresenceState extends State<_LignePresence> {
  bool _enCours = false;

  Future<void> _marquer(bool present) async {
    setState(() => _enCours = true);
    final erreur = await context.read<ReponsesCubit>().emarger(widget.uid, present);
    if (!mounted) return;
    setState(() => _enCours = false);
    if (erreur != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erreur)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reponse = widget.reponse;
    final presence = reponse?.presence;
    final verrouille = reponse?.avis != null;
    final invitation = switch (reponse) {
      ReponseBureau(vient: true, :final nbPersonnes) => '$nbPersonnes attendu${nbPersonnes > 1 ? 's' : ''}',
      ReponseBureau(aRepondu: true) => 'Invitation déclinée',
      _ => 'Invitation sans réponse',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(invitation, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final present in [true, false])
                  ChoiceChip(
                    label: Text(present ? 'Présent' : 'Absent'),
                    selected: presence == present,
                    onSelected: _enCours || verrouille || presence == present ? null : (_) => _marquer(present),
                  ),
              ],
            ),
            if (_enCours) const LinearProgressIndicator(semanticsLabel: 'Enregistrement de la présence'),
            if (verrouille) Text('Avis reçu', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
