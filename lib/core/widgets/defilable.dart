import 'package:flutter/material.dart';

/// Écran plein (accueil, verrou) qui défile quand le texte est agrandi (WCAG 1.4.4) :
/// les Spacer gardent la mise en page en taille normale, le défilement évite le débordement en grand.
class PleinEcranDefilant extends StatelessWidget {
  const PleinEcranDefilant({super.key, required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, contraintes) => SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: contraintes.maxHeight - padding.vertical),
        child: IntrinsicHeight(child: child),
      ),
    ),
  );
}
