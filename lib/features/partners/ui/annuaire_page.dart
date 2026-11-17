import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/bandeau_hors_ligne.dart';
import '../data/partner.dart';
import '../logic/partners_cubit.dart';
import '../logic/partners_state.dart';
import 'partner_detail_page.dart';
import 'partner_logo.dart';

/// Annuaire public (F8) : consultable sans compte, recherche par nom, métier et ville.
class AnnuairePage extends StatelessWidget {
  const AnnuairePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PARQUET.')),
      body: BlocBuilder<PartnersCubit, PartnersState>(
        builder: (context, state) => switch (state) {
          PartnersLoading() => const _Squelette(),
          PartnersError(:final message) => _Erreur(message),
          PartnersEmpty(:final horsLigne, :final derniereSynchro) => Column(
              children: [
                if (horsLigne) BandeauHorsLigne(derniereSynchro: derniereSynchro),
                const Expanded(child: Center(child: Text("Aucun partenaire dans l'annuaire pour le moment."))),
              ],
            ),
          PartnersSuccess() => _Liste(state),
        },
      ),
    );
  }
}

class _Liste extends StatelessWidget {
  const _Liste(this.state);

  final PartnersSuccess state;

  @override
  Widget build(BuildContext context) {
    final partenaires = state.partenaires;
    return Column(
      children: [
        if (state.horsLigne) BandeauHorsLigne(derniereSynchro: state.derniereSynchro),
        Expanded(
          // Liste paresseuse (cours 2 et 4) : seules les lignes visibles sont construites.
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            itemCount: partenaires.isEmpty ? 2 : partenaires.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return _EnTete(state);
              if (partenaires.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text('Aucun partenaire ne correspond à cette recherche.', textAlign: TextAlign.center),
                );
              }
              return _Ligne(partenaires[i - 1]);
            },
          ),
        ),
      ],
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete(this.state);

  final PartnersSuccess state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PartnersCubit>();
    final theme = Theme.of(context);
    final nb = state.partenaires.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text('ANNUAIRE', style: theme.textTheme.displaySmall)),
        Text('Trouvez un métier dans le réseau du club.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: state.recherche,
          onChanged: cubit.rechercher,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Nom, métier ou ville',
            prefixIcon: Icon(Icons.search),
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in [null, ...secteurs])
              ChoiceChip(
                label: Text(s ?? 'Tous'),
                selected: state.secteur == s,
                onSelected: (_) => cubit.filtrerSecteur(s),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('$nb ${nb > 1 ? 'ENTREPRISES' : 'ENTREPRISE'}', style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne(this.partner);

  final Partner partner;

  @override
  Widget build(BuildContext context) {
    final sousTitre = [partner.metier, partner.ville].where((s) => s.isNotEmpty).join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: PartnerLogo(partner),
        title: Text(partner.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: sousTitre.isEmpty ? null : Text(sousTitre),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => PartnerDetailPage(partnerId: partner.id)),
        ),
      ),
    );
  }
}

/// Chargement : trois lignes squelettes statiques (charte, compatible mouvement réduit).
class _Squelette extends StatelessWidget {
  const _Squelette();

  @override
  Widget build(BuildContext context) {
    final gris = Theme.of(context).colorScheme.outline;
    return Semantics(
      label: "Chargement de l'annuaire",
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: 64,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: gris, borderRadius: BorderRadius.circular(10)),
            ),
        ],
      ),
    );
  }
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
            FilledButton(onPressed: context.read<PartnersCubit>().charger, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
