import 'package:flutter/material.dart';

/// Type d'événement (« Match en loge », « Afterwork »…) en petite étiquette, comme sur la maquette.
class EtiquetteType extends StatelessWidget {
  const EtiquetteType(this.type, {super.key});

  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rouge = theme.colorScheme.primary;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          // Teinte très légère : le texte rouge garde un contraste suffisant (WCAG AA).
          color: rouge.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: theme.textTheme.labelMedium?.copyWith(color: rouge, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
