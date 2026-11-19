import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../../../core/format_date.dart';
import '../../events/data/event.dart';
import '../../events/logic/events_cubit.dart';
import '../../events/ui/visuel_evenement.dart';

/// Créer ou modifier un événement (F10). Le texte du push est généré par le serveur, pas saisi ici.
class EvenementFormPage extends StatefulWidget {
  const EvenementFormPage({super.key, this.existant});

  final Event? existant;

  @override
  State<EvenementFormPage> createState() => _EvenementFormPageState();
}

class _EvenementFormPageState extends State<EvenementFormPage> {
  late final _titre = TextEditingController(text: widget.existant?.titre);
  late final _type = TextEditingController(text: widget.existant?.type);
  late final _lieu = TextEditingController(text: widget.existant?.lieu);
  late final _description = TextEditingController(text: widget.existant?.description);
  late DateTime? _date = widget.existant?.date;
  late Uint8List? _photo = widget.existant?.photo;
  bool _choixPhoto = false;
  String? _erreur;
  String? _erreurPhoto;

  @override
  void dispose() {
    for (final c in [_titre, _type, _lieu, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final maintenant = DateTime.now();
    final jour = await showDatePicker(
      context: context,
      initialDate: _date ?? maintenant,
      firstDate: maintenant.subtract(dureeSuiviEvenement),
      lastDate: maintenant.add(const Duration(days: 730)),
    );
    if (jour == null || !mounted) return;
    final h = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date ?? DateTime(0, 1, 1, 19)),
    );
    if (h == null || !mounted) return;
    setState(() => _date = DateTime(jour.year, jour.month, jour.day, h.hour, h.minute));
  }

  Future<void> _choisirPhoto() async {
    setState(() {
      _choixPhoto = true;
      _erreurPhoto = null;
    });
    try {
      final fichier = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 960,
        imageQuality: 72,
        requestFullMetadata: false,
      );
      if (fichier == null) return;
      final photo = await fichier.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (photo.length > tailleMaxPhotoEvenement || photo.isEmpty) {
          _erreurPhoto = 'Choisissez une photo de 450 Ko maximum après compression.';
        } else {
          _photo = photo;
        }
      });
    } on Exception {
      if (mounted) setState(() => _erreurPhoto = "Impossible d'ouvrir cette photo.");
    } finally {
      if (mounted) setState(() => _choixPhoto = false);
    }
  }

  void _enregistrer() {
    final date = _date;
    final titre = _titre.text.trim();
    if (titre.isEmpty || date == null) {
      setState(() => _erreur = 'Le titre, la date et l\'heure sont obligatoires.');
      return;
    }
    final messager = ScaffoldMessenger.of(context);
    final event = Event(
      id: widget.existant?.id ?? '',
      titre: titre,
      type: _type.text.trim(),
      date: date,
      lieu: _lieu.text.trim(),
      description: _description.text.trim(),
      photo: _photo,
    );
    // Pas d'await : hors ligne, l'événement apparaît tout de suite et part au retour du réseau.
    context.read<EventsCubit>().enregistrer(event, ancien: widget.existant).catchError((Object _) {
      messager.showSnackBar(const SnackBar(content: Text("L'événement n'a pas pu être enregistré.")));
    });
    messager.showSnackBar(SnackBar(content: Text(widget.existant == null ? 'Événement créé.' : 'Événement modifié.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = _date;
    final creation = widget.existant == null;
    final dateArchivee = widget.existant?.estPasse(DateTime.now()) ?? false;
    return Scaffold(
      appBar: AppBar(title: const TitreParquet()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Semantics(
            header: true,
            child: Text(creation ? 'NOUVEL ÉVÉNEMENT' : 'MODIFIER', style: theme.textTheme.displaySmall),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: 148,
              child: PhotoEvenement(photo: _photo),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _choixPhoto ? null : _choisirPhoto,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              _choixPhoto
                  ? 'Chargement de la photo…'
                  : _photo == null
                  ? 'Ajouter une photo'
                  : 'Changer la photo',
            ),
          ),
          if (_photo != null)
            TextButton(
              onPressed: _choixPhoto
                  ? null
                  : () => setState(() {
                      _photo = null;
                      _erreurPhoto = null;
                    }),
              child: const Text("Utiliser l’image par défaut"),
            ),
          if (_erreurPhoto != null) Text(_erreurPhoto!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 16),
          TextField(
            controller: _titre,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _type,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Type',
              hintText: 'Match en loge, Afterwork, Soirée partenaires',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(date == null ? 'Choisir la date et l\'heure' : '${dateLongue(date)} · ${heure(date)}'),
            onPressed: dateArchivee ? null : _choisirDate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lieu,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Lieu',
              helperText: 'Indiquez une adresse postale complète pour afficher une carte.',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            maxLength: 1000,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          if (_erreur != null)
            Semantics(
              liveRegion: true,
              child: Text(_erreur!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          if (!creation)
            Text(
              'Les partenaires seront prévenus si la date, l\'heure ou le lieu changent.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _choixPhoto ? null : _enregistrer,
            child: Text(creation ? "Créer l'événement" : 'Enregistrer'),
          ),
        ),
      ),
    );
  }
}
