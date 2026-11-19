import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../../../core/confidentialite_page.dart';
import '../../../core/widgets/bandeau_hors_ligne.dart';
import '../../../core/widgets/etat_contenu.dart';
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
      appBar: AppBar(title: const TitreParquet()),
      body: BlocBuilder<PartnersCubit, PartnersState>(
        builder: (context, state) => switch (state) {
          PartnersLoading() => const SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: SqueletteListe(libelle: "Chargement de l'annuaire"),
          ),
          PartnersError(:final message) => _Erreur(message),
          PartnersEmpty(:final horsLigne, :final derniereSynchro) => Column(
            children: [
              if (horsLigne) BandeauHorsLigne(derniereSynchro: derniereSynchro),
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      EtatContenu(
                        icone: Icons.storefront_outlined,
                        titre: "Aucun partenaire dans l'annuaire",
                        message: 'Les entreprises du réseau apparaîtront ici.',
                      ),
                      _LienConfidentialite(),
                    ],
                  ),
                ),
              ),
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
            // En-tête, lignes (ou « aucun résultat »), puis le lien Confidentialité pour les visiteurs.
            itemCount: (partenaires.isEmpty ? 2 : partenaires.length + 1) + 1,
            itemBuilder: (context, i) {
              if (i == 0) return _EnTete(state);
              if (i == (partenaires.isEmpty ? 2 : partenaires.length + 1)) return const _LienConfidentialite();
              if (partenaires.isEmpty) {
                return const EtatContenu(
                  icone: Icons.search_off,
                  titre: 'Aucun résultat',
                  message: 'Essayez un autre nom, métier ou filtre.',
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
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => PartnerDetailPage(partnerId: partner.id))),
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
      child: SingleChildScrollView(
        child: EtatContenu(
          icone: Icons.sync_problem,
          titre: 'Annuaire indisponible',
          message: message,
          action: FilledButton(onPressed: context.read<PartnersCubit>().charger, child: const Text('Réessayer')),
        ),
      ),
    );
  }
}

class _LienConfidentialite extends StatelessWidget {
  const _LienConfidentialite();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ConfidentialitePage())),
        child: Text(
          'Confidentialité',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
