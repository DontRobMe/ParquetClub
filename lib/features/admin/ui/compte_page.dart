import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../partners/logic/partners_cubit.dart';
import '../logic/admin_cubit.dart';
import '../logic/admin_state.dart';
import 'confirmer.dart';

/// Gestion d'un compte partenaire : lien de mot de passe (F2), désactivation (F4), suppression (F5).
class ComptePage extends StatefulWidget {
  const ComptePage({super.key, required this.uid});

  final String uid;

  @override
  State<ComptePage> createState() => _ComptePageState();
}

class _ComptePageState extends State<ComptePage> {
  bool _enCours = false; // état local : un seul appel serveur à la fois

  Future<void> _executer(Future<String?> Function() action, {required String succes, bool fermer = false}) async {
    setState(() => _enCours = true);
    final erreur = await action();
    if (!mounted) return;
    setState(() => _enCours = false);
    afficher(context, erreur ?? succes);
    if (erreur == null && fermer) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AdminCubit>();
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, _) {
        final compte = cubit.compte(widget.uid);
        if (compte == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('PARQUET.')),
            body: const Center(child: Text("Ce compte n'existe plus.")),
          );
        }
        final nom = context.read<PartnersCubit>().partenaire(compte.uid)?.nom ?? compte.email;
        return Scaffold(
          appBar: AppBar(title: const Text('PARQUET.')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Semantics(header: true, child: Text(nom.toUpperCase(), style: theme.textTheme.headlineMedium)),
              Text(compte.email),
              Text(
                compte.actif ? 'Accès actif' : 'Accès désactivé',
                style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant),
              ),
              FutureBuilder<String>(
                future: cubit.telephonePerso(compte.uid),
                builder: (context, tel) =>
                    (tel.data ?? '').isEmpty ? const SizedBox.shrink() : Text('Téléphone personnel : ${tel.data}'),
              ),
              const SizedBox(height: 24),
              // Actions sensibles en haut, loin du pouce, et toujours confirmées (cours 5).
              OutlinedButton.icon(
                icon: Icon(compte.actif ? Icons.block : Icons.check_circle_outline),
                label: Text(compte.actif ? "Désactiver l'accès" : "Réactiver l'accès"),
                onPressed: _enCours
                    ? null
                    : () async {
                        if (compte.actif &&
                            !await confirmer(
                              context,
                              titre: "Désactiver l'accès ?",
                              texte:
                                  '$nom ne pourra plus se connecter ni recevoir les invitations. '
                                  'Sa fiche reste dans l\'annuaire. Vous pourrez réactiver l\'accès.',
                              action: 'Désactiver',
                            )) {
                          return;
                        }
                        await _executer(
                          () => cubit.changerAcces(compte.uid, actif: !compte.actif, nom: nom),
                          succes: compte.actif ? 'Accès désactivé.' : 'Accès réactivé.',
                        );
                      },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Supprimer le partenaire'),
                onPressed: _enCours
                    ? null
                    : () async {
                        if (!await confirmer(
                          context,
                          titre: 'Supprimer $nom ?',
                          texte:
                              'La fiche, le logo, le numéro privé et les réponses aux événements seront effacés '
                              'définitivement. Il restera à supprimer son compte de connexion dans la console Firebase.',
                          action: 'Supprimer',
                        )) {
                          return;
                        }
                        await _executer(
                          () => cubit.supprimer(compte.uid, nom: nom),
                          // Forfait Spark : l'app ne peut pas supprimer le compte de connexion d'un autre.
                          succes:
                              'Partenaire supprimé. Supprimez aussi ${compte.email} dans la console '
                              'Firebase (Authentication).',
                          fermer: true,
                        );
                      },
              ),
              const SizedBox(height: 32),
              Text(
                'Partenaire perdu ? Envoyez-lui le lien pour choisir un nouveau mot de passe. '
                'Personne ne voit jamais son mot de passe.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton(
                onPressed: _enCours || !compte.actif
                    ? null
                    : () => _executer(() => cubit.envoyerLien(compte.email), succes: 'Lien envoyé à ${compte.email}.'),
                child: const Text('Envoyer le lien de mot de passe'),
              ),
            ),
          ),
        );
      },
    );
  }
}
