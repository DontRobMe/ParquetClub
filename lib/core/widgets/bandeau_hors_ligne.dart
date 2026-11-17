import 'package:flutter/material.dart';

/// Bandeau discret « Hors connexion — données du … » plutôt qu'un chargement sans fin (cahier des charges, partie 6).
class BandeauHorsLigne extends StatelessWidget {
  const BandeauHorsLigne({super.key, this.derniereSynchro});

  final DateTime? derniereSynchro;

  @override
  Widget build(BuildContext context) {
    final d = derniereSynchro;
    final quand = d == null
        ? 'dernières données enregistrées'
        : 'données du ${_deuxChiffres(d.day)}/${_deuxChiffres(d.month)} à ${d.hour}h${_deuxChiffres(d.minute)}';
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: scheme.outline,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 18, color: scheme.onSurface),
            const SizedBox(width: 8),
            Expanded(child: Text('Hors connexion — $quand')),
          ],
        ),
      ),
    );
  }
}

String _deuxChiffres(int n) => n.toString().padLeft(2, '0');
