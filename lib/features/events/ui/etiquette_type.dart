import 'package:flutter/material.dart';

/// Type d'événement (« Match en loge », « Afterwork »…) en petite étiquette, comme sur la maquette.
class EtiquetteType extends StatelessWidget {
  const EtiquetteType(this.type, {super.key});

  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          // Rouge foncé sur rose pâle : 5,6:1 (WCAG AA).
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
