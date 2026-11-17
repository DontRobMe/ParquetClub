import 'package:flutter/material.dart';

/// Politique de confidentialité (cahier des charges, partie 5 « RGPD ; cours 6).
/// Accessible depuis Mon profil et en bas de l'annuaire, pour les visiteurs. Lisible hors ligne.
class ConfidentialitePage extends StatelessWidget {
  const ConfidentialitePage({super.key});

  static const _sections = [
    (
      'Responsable du traitement',
      "Le club de basket, représenté par son président. Google Firebase héberge les données pour le club "
          '(sous-traitant), dans l\'Union européenne (Paris).',
    ),
    (
      'Données collectées',
      'Pour les partenaires : nom et e-mail du compte, informations professionnelles de la fiche, logo de '
          "l'entreprise, téléphone personnel facultatif, réponses aux événements, identifiant de notification. "
          "Pour les visiteurs : aucune donnée. L'application n'a ni publicité, ni traceur, ni statistiques, "
          "et n'utilise pas la localisation.",
    ),
    (
      'Pourquoi',
      "Exécution du contrat de partenariat : présenter votre entreprise dans l'annuaire public et vous inviter "
          'aux événements du club.',
    ),
    (
      'Qui voit quoi',
      "La fiche (nom, activité, description, adresse, contacts professionnels, logo) est publique : elle apparaît "
          "dans l'annuaire, consultable sans compte. Le téléphone personnel et vos réponses aux événements ne sont "
          'visibles que par vous et le bureau du club.',
    ),
    (
      'Durée de conservation',
      'Tant que le partenariat est actif. À la fin, tout est effacé de l\'application. Les réponses aux '
          'événements sont effacées 12 mois après l\'événement.',
    ),
    (
      'Vos droits',
      "Accès et rectification : vous voyez et modifiez votre fiche dans « Mon profil ». Effacement : demandez la "
          'suppression au bureau du club, elle est faite sous 1 mois. Vous pouvez aussi adresser une réclamation '
          'à la CNIL (cnil.fr).',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('PARQUET.')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Semantics(header: true, child: Text('CONFIDENTIALITÉ', style: theme.textTheme.displaySmall)),
          for (final (titre, texte) in _sections) ...[
            const SizedBox(height: 20),
            Semantics(header: true, child: Text(titre, style: theme.textTheme.titleLarge)),
            const SizedBox(height: 4),
            Text(texte),
          ],
        ],
      ),
    );
  }
}
