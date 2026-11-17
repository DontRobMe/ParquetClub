import 'package:flutter/material.dart';

import '../data/partner.dart';

/// Logo dans un cadre fixe quel que soit son format ; initiales s'il n'y en a pas (charte).
class PartnerLogo extends StatelessWidget {
  const PartnerLogo(this.partner, {super.key, this.taille = 48});

  final Partner partner;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initiales = Container(
      color: scheme.secondary,
      alignment: Alignment.center,
      child: Text(
        _initiales(partner.nom),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: scheme.onSecondary, fontSize: taille * 0.42),
      ),
    );
    return Semantics(
      label: 'Logo de ${partner.nom}',
      image: true,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: taille,
            child: switch (partner.logo) {
              null => initiales,
              final octets => ColoredBox(
                color: scheme.surface,
                child: Image.memory(octets, fit: BoxFit.contain, errorBuilder: (_, _, _) => initiales),
              ),
            },
          ),
        ),
      ),
    );
  }
}

String _initiales(String nom) {
  final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).take(2);
  return mots.map((m) => m[0].toUpperCase()).join();
}
