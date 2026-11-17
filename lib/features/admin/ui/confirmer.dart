import 'package:flutter/material.dart';

/// Confirmation des actions destructrices (cours 5). Renvoie true si l'utilisateur confirme.
Future<bool> confirmer(
  BuildContext context, {
  required String titre,
  required String texte,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titre),
      content: Text(texte),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok == true;
}

void afficher(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
