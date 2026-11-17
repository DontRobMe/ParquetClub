import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(const ParquetApp());
}

class ParquetApp extends StatelessWidget {
  const ParquetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parquet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LancementPage(),
    );
  }
}

/// Écran de lancement (maquette) : remplacé par la navigation par rôle une fois Firebase branché.
class LancementPage extends StatelessWidget {
  const LancementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.secondary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_basketball, size: 72, color: scheme.primary, semanticLabel: 'Parquet'),
            const SizedBox(height: 12),
            Text('PARQUET.', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: scheme.onSecondary)),
            Text('Club partenaires', style: TextStyle(color: scheme.onSecondary)),
          ],
        ),
      ),
    );
  }
}
