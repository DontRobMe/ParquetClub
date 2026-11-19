import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/bandeau_hors_ligne.dart';
import '../../../core/widgets/etat_contenu.dart';
import '../../../core/widgets/titre_parquet.dart';
import '../logic/events_cubit.dart';
import '../logic/events_state.dart';
import 'avis_evenement_sheet.dart';
import 'evenements_page.dart';

class HistoriqueEvenementsPage extends StatefulWidget {
  const HistoriqueEvenementsPage({super.key});

  @override
  State<HistoriqueEvenementsPage> createState() => _HistoriqueEvenementsPageState();
}

class _HistoriqueEvenementsPageState extends State<HistoriqueEvenementsPage> {
  bool _avisPropose = false;

  @override
  void initState() {
    super.initState();
    _proposerAvis();
  }

  void _proposerAvis() {
    if (_avisPropose) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _avisPropose || ModalRoute.of(context)?.isCurrent != true) return;
      final state = context.read<EventsCubit>().state;
      if (state is! EventsSuccess) return;
      final event = state.aNoter(DateTime.now()).firstOrNull;
      if (event == null) return;
      _avisPropose = true;
      ouvrirAvisEvenement(context, event);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TitreParquet()),
      body: BlocConsumer<EventsCubit, EventsState>(
        listener: (_, _) => _proposerAvis(),
        builder: (context, state) {
          final maintenant = DateTime.now();
          final historique = state is EventsSuccess ? state.historiquePartenaire(maintenant) : const [];
          final (horsLigne, derniereSynchro) = switch (state) {
            EventsSuccess(:final horsLigne, :final derniereSynchro) ||
            EventsEmpty(:final horsLigne, :final derniereSynchro) => (horsLigne, derniereSynchro),
            _ => (false, null),
          };
          return Column(
            children: [
              if (horsLigne) BandeauHorsLigne(derniereSynchro: derniereSynchro),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  children: [
                    Semantics(header: true, child: Text('HISTORIQUE', style: Theme.of(context).textTheme.displaySmall)),
                    const SizedBox(height: 16),
                    if (state is EventsLoading)
                      const SqueletteListe(libelle: "Chargement de l’historique")
                    else if (state is EventsError)
                      EtatContenu(
                        icone: Icons.sync_problem,
                        titre: 'Historique indisponible',
                        message: state.message,
                        action: OutlinedButton(
                          onPressed: context.read<EventsCubit>().charger,
                          child: const Text('Réessayer'),
                        ),
                      )
                    else if (historique.isEmpty)
                      const EtatContenu(
                        icone: Icons.history,
                        titre: 'Aucun événement passé',
                        message: 'Les événements du club apparaîtront ici.',
                      )
                    else if (state is EventsSuccess)
                      for (final event in historique)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: LigneEvenement(
                            event,
                            state.reponses[event.id],
                            historique: true,
                            aNoter: state.reponses[event.id]?.peutNoter(event, maintenant) ?? false,
                          ),
                        ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
