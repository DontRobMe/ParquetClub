import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/partner.dart';
import '../logic/partners_cubit.dart';
import '../logic/partners_state.dart';
import 'partner_logo.dart';

/// Fiche détail (F9). Reçoit l'identifiant et relit le partenaire dans le Cubit partagé :
/// une modification de la fiche s'affiche en direct, et la fiche reste lisible hors ligne.
class PartnerDetailPage extends StatelessWidget {
  const PartnerDetailPage({super.key, required this.partnerId});

  final String partnerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PARQUET.')),
      body: BlocBuilder<PartnersCubit, PartnersState>(
        builder: (context, _) {
          final p = context.read<PartnersCubit>().partenaire(partnerId);
          if (p == null) {
            return const Center(child: Text("Ce partenaire n'est plus dans l'annuaire."));
          }
          return _Fiche(p);
        },
      ),
    );
  }
}

class _Fiche extends StatelessWidget {
  const _Fiche(this.p);

  final Partner p;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ios = theme.platform == TargetPlatform.iOS;
    final adresse = [p.adresse, p.ville].where((s) => s.isNotEmpty).join(', ');
    final sousTitre = [p.metier, p.ville].where((s) => s.isNotEmpty).join(' · ');

    final actions = <(IconData, String, Uri)>[
      if (p.telephone.isNotEmpty) (Icons.call, 'Appeler', Uri(scheme: 'tel', path: p.telephone.replaceAll(' ', ''))),
      if (p.email.isNotEmpty) (Icons.mail_outline, 'E-mail', Uri(scheme: 'mailto', path: p.email)),
      // OWASP M4 : seul un lien https est ouvert, le reste n'est que du texte.
      if (p.site.startsWith('https://') && Uri.tryParse(p.site) != null)
        (Icons.language, 'Site web', Uri.parse(p.site)),
      if (adresse.isNotEmpty)
        (
          Icons.directions,
          'Itinéraire',
          ios
              ? Uri.https('maps.apple.com', '/', {'q': adresse})
              : Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': adresse}),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Row(
          children: [
            PartnerLogo(p, taille: 72),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(p.nom.toUpperCase(), style: theme.textTheme.headlineMedium)),
                  if (sousTitre.isNotEmpty)
                    Text(sousTitre, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        if (p.description.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(p.description),
        ],
        if (adresse.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(adresse)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        for (final (icone, libelle, uri) in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              icon: Icon(icone),
              label: Text(libelle),
              onPressed: () => _ouvrir(context, uri),
            ),
          ),
      ],
    );
  }
}

/// Ouvre l'app du téléphone (Téléphone, Mail, navigateur, Plans).
Future<void> _ouvrir(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucune application ne peut ouvrir ce lien.')),
    );
  }
}
