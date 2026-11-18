import 'package:flutter/material.dart';

/// Logo du club, détouré (assets/images/logo.png).
class LogoParquet extends StatelessWidget {
  const LogoParquet({super.key, this.taille = 32});

  final double taille;

  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/logo.png', width: taille, height: taille, semanticLabel: 'Logo Parquet');
}

/// Titre des barres du haut, comme sur la maquette : logo, « PARQUET. » et « CLUB PARTENAIRES ».
class TitreParquet extends StatelessWidget {
  const TitreParquet({super.key});

  @override
  Widget build(BuildContext context) {
    final couleur = Theme.of(context).appBarTheme.foregroundColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Le nom est lu juste après : le logo n'a pas besoin d'être annoncé une seconde fois.
        const ExcludeSemantics(child: LogoParquet()),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PARQUET.'),
            Text(
              'CLUB PARTENAIRES',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: couleur,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
