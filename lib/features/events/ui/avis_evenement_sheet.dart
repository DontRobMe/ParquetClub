import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format_date.dart';
import '../data/event.dart';
import '../logic/events_cubit.dart';

Future<void> ouvrirAvisEvenement(BuildContext context, Event event) async {
  final cubit = context.read<EventsCubit>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _AvisEvenementSheet(event: event, enregistrer: (avis) => cubit.noter(event.id, avis)),
  );
}

class _AvisEvenementSheet extends StatefulWidget {
  const _AvisEvenementSheet({required this.event, required this.enregistrer});

  final Event event;
  final Future<void> Function(AvisEvenement) enregistrer;

  @override
  State<_AvisEvenementSheet> createState() => _AvisEvenementSheetState();
}

class _AvisEvenementSheetState extends State<_AvisEvenementSheet> {
  final _commentaire = TextEditingController();
  int _note = 0;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.enregistrer(AvisEvenement(note: _note, commentaire: _commentaire.text.trim()));
      if (!mounted) return;
      final messager = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messager.showSnackBar(const SnackBar(content: Text('Merci pour votre retour !')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = e is ErreurSuiviEvenement ? e.message : "L’avis n’a pas pu être envoyé. Réessayez.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Comment était cet événement ?', style: theme.textTheme.headlineMedium),
            ),
            const SizedBox(height: 6),
            Text(
              '${event.titre} · ${dateLongue(event.date)}',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (var note = 1; note <= 5; note++)
                    IconButton(
                      tooltip: '$note sur 5',
                      isSelected: note == _note,
                      onPressed: _envoi ? null : () => setState(() => _note = note),
                      icon: Icon(
                        note <= _note ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: note <= _note
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentaire,
              enabled: !_envoi,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Commentaire (facultatif)'),
            ),
            if (_erreur != null)
              Semantics(
                liveRegion: true,
                child: Text(_erreur!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _envoi || _note == 0 ? null : _envoyer,
              child: Text(_envoi ? 'Envoi…' : "Envoyer mon avis"),
            ),
            TextButton(onPressed: _envoi ? null : () => Navigator.of(context).pop(), child: const Text('Plus tard')),
          ],
        ),
      ),
    );
  }
}
