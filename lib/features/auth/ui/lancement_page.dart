import 'package:flutter/material.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

/// Lancement sur fond noir (charte), affiché seulement le temps de lire la session.
class LancementPage extends StatelessWidget {
  const LancementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: scheme.secondary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoParquet(taille: 96),
            const SizedBox(height: 12),
            Text('PARQUET.', style: theme.textTheme.displaySmall?.copyWith(color: scheme.onSecondary)),
            Text('Club partenaires', style: TextStyle(color: scheme.onSecondary)),
          ],
        ),
      ),
    );
  }
}
