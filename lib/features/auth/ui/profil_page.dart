import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/confidentialite_page.dart';
import '../../admin/logic/verrou_cubit.dart';
import '../../partners/logic/profile_cubit.dart';
import '../../partners/ui/fiche_form_page.dart';
import '../../partners/ui/partner_logo.dart';
import '../data/auth_repository.dart';
import '../logic/auth_cubit.dart';

/// Onglet « Mon profil » : sa fiche (partenaire), la confidentialité et la déconnexion.
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
    void ouvrir(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
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
          if (!session.estAdmin) ...[const SizedBox(height: 24), _MaFiche(ouvrir: ouvrir)],
          if (session.estAdmin) ...[const SizedBox(height: 24), const _Verrouillage()],
          const SizedBox(height: 24),
          TextButton(
            style: TextButton.styleFrom(alignment: Alignment.centerLeft, minimumSize: const Size.fromHeight(48)),
            onPressed: () => ouvrir(const ConfidentialitePage()),
            child: const Text('Confidentialité'),
          ),
        ],
      ),
    );
  }
}

class _MaFiche extends StatelessWidget {
  const _MaFiche({required this.ouvrir});

  final void Function(Widget) ouvrir;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) => switch (state) {
        ProfileLoading() => const Center(child: CircularProgressIndicator(semanticsLabel: 'Chargement de votre fiche')),
        ProfileError(:final message) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message),
            OutlinedButton(onPressed: context.read<ProfileCubit>().charger, child: const Text('Réessayer')),
          ],
        ),
        ProfileSuccess(:final fiche, :final telephonePerso) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: PartnerLogo(fiche),
                title: Text(fiche.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(fiche.metier.isEmpty ? 'Fiche à compléter' : [fiche.metier, fiche.ville].join(' · ')),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier ma fiche'),
              onPressed: () => ouvrir(FicheFormPage(fiche: fiche, telephonePerso: telephonePerso)),
            ),
          ],
        ),
      },
    );
  }
}

/// F17. Réglage du verrouillage biométrique, compte bureau seulement.
class _Verrouillage extends StatelessWidget {
  const _Verrouillage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerrouCubit, VerrouState>(
      builder: (context, state) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Verrouiller par empreinte ou visage'),
        subtitle: Text(
          state.disponible
              ? "Demandé à l'ouverture de l'app et à chaque retour sur l'app."
              : "Ce téléphone n'a ni empreinte, ni visage, ni code configuré.",
        ),
        value: state.actif,
        onChanged: state.disponible
            ? (actif) async {
                final messager = ScaffoldMessenger.of(context);
                final erreur = await context.read<VerrouCubit>().changerPreference(actif: actif);
                if (erreur != null) messager.showSnackBar(SnackBar(content: Text(erreur)));
              }
            : null,
      ),
    );
  }
}
