import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/format_date.dart';
import '../data/event.dart';
import 'etiquette_type.dart';

class VisuelEvenement extends StatelessWidget {
  const VisuelEvenement({super.key, required this.event, this.surtitre});

  final Event event;
  final String? surtitre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final type = event.type.trim();
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: scheme.secondary,
            child: PhotoEvenement(photo: event.photo),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0xD9000000), Color(0xF5000000)],
                stops: [0, 0.68, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, surtitre != null ? 120 : 84, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (surtitre != null) ...[
                DecoratedBox(
                  decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(5)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    child: Text(
                      surtitre!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (type.isNotEmpty) ...[
                EtiquetteType(type),
                const SizedBox(height: 8),
              ],
              Semantics(
                header: true,
                child: Text(
                  event.titre.toUpperCase(),
                  style: theme.textTheme.displaySmall?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${dateLongue(event.date)} · ${heure(event.date)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PhotoEvenement extends StatelessWidget {
  const PhotoEvenement({super.key, this.photo});

  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final image = photo;
    final defaut = Image.asset(
      'assets/images/terrain.jpg',
      fit: BoxFit.cover,
      alignment: Alignment.topRight,
      excludeFromSemantics: true,
    );
    return image == null
        ? defaut
        : Image.memory(image, fit: BoxFit.cover, excludeFromSemantics: true, errorBuilder: (_, _, _) => defaut);
  }
}
