import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/carte_evenement.dart';

class LieuEvenement extends StatefulWidget {
  LieuEvenement({required this.lieu}) : super(key: ValueKey(lieu));

  final String lieu;

  @override
  State<LieuEvenement> createState() => _LieuEvenementState();
}

class _LieuEvenementState extends State<LieuEvenement> {
  late final _carte = CarteEvenement.charger(widget.lieu);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text('Lieu', style: theme.textTheme.headlineSmall)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.lieu)),
          ],
        ),
        FutureBuilder<CarteEvenement?>(
          future: _carte,
          builder: (context, snapshot) => AnimatedSize(
            alignment: Alignment.topCenter,
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: snapshot.data == null ? const SizedBox.shrink() : _Apercu(carte: snapshot.data!),
          ),
        ),
      ],
    );
  }
}

class _Apercu extends StatelessWidget {
  const _Apercu({required this.carte});

  final CarteEvenement carte;

  Future<void> _ouvrirItineraire(BuildContext context) async {
    final point = '${carte.latitude},${carte.longitude}';
    final url = Theme.of(context).platform == TargetPlatform.iOS
        ? Uri.https('maps.apple.com', '/', {'daddr': point})
        : Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': point});
    final ouvert = await launchUrl(url, mode: LaunchMode.externalApplication).catchError((Object _) => false);
    if (!ouvert && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir l'itinéraire.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Image.memory(
      carte.image,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
      frameBuilder: (context, image, frame, _) {
        if (frame == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 720 / 352,
                  child: Semantics(
                    image: true,
                    label: "Carte du lieu de l'événement",
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image,
                        Align(
                          alignment: Alignment.center,
                          child: Transform.translate(
                            offset: const Offset(0, -14),
                            child: Icon(Icons.location_on, color: theme.colorScheme.primary, size: 34),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              child: Text('© IGN', style: theme.textTheme.labelSmall),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _ouvrirItineraire(context),
                icon: const Icon(Icons.directions_outlined),
                label: const Text("Ouvrir l’itinéraire"),
              ),
            ],
          ),
        );
      },
    );
  }
}
