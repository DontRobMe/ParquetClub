import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../logic/auth_cubit.dart';

/// Onglet « Mon profil ». L'édition de la fiche (F6, F7) viendra s'ajouter ici.
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key, required this.session});

  final Session session;

  Future<void> _deconnecter(BuildContext context) async {
    final cubit = context.read<AuthCubit>();
    // Action destructrice : confirmée (cours 5).
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous ne recevrez plus les invitations sur ce téléphone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Se déconnecter')),
        ],
      ),
    );
    if (ok == true) await cubit.deconnecter();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // Déconnexion en haut, loin du pouce.
      appBar: AppBar(
        title: const Text('PARQUET.'),
        actions: [
          IconButton(tooltip: 'Se déconnecter', icon: const Icon(Icons.logout), onPressed: () => _deconnecter(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Semantics(header: true, child: Text('MON PROFIL', style: theme.textTheme.displaySmall)),
          const SizedBox(height: 8),
          Text(session.email),
          Text(
            session.estAdmin ? 'Compte du bureau' : 'Compte partenaire',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
