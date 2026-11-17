import 'package:flutter/material.dart';

/// Accueil du club pour un visiteur : courte présentation, puis l'annuaire ou la connexion.
class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key, required this.voirPartenaires, required this.seConnecter});

  final VoidCallback voirPartenaires;
  final VoidCallback seConnecter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const blanc = TextStyle(color: Colors.white);
    return Scaffold(
      backgroundColor: theme.colorScheme.secondary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/terrain.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topRight,
            excludeFromSemantics: true,
          ),
          // Dégradé noir sous les textes blancs : le contraste ne dépend pas du recadrage.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0xF2000000)],
                stops: [0.2, 0.7],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Semantics(
                    header: true,
                    child: Text(
                      'PARQUET.',
                      style: theme.textTheme.displayMedium
                          ?.merge(blanc)
                          .copyWith(fontFamily: 'BarlowCondensed', fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Text('Club partenaires', style: blanc),
                  const SizedBox(height: 16),
                  const Text(
                    'Les entreprises, commerçants et artisans qui font vivre le club. '
                    'Trouvez un métier près de chez vous, sans créer de compte.',
                    style: blanc,
                  ),
                  const SizedBox(height: 24),
                  // Action principale en bas, dans la zone du pouce.
                  FilledButton(onPressed: voirPartenaires, child: const Text('Voir les partenaires')),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: seConnecter,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
