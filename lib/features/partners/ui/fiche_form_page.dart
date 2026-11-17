import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/partner.dart';
import '../logic/profile_cubit.dart';
import 'partner_logo.dart';

/// Modifier sa fiche (F6) et son téléphone personnel (F7).
/// Formulaire lisible (cours 5) : un champ par ligne, libellé au-dessus, clavier adapté.
class FicheFormPage extends StatefulWidget {
  const FicheFormPage({super.key, required this.fiche, required this.telephonePerso});

  final Partner fiche;
  final String telephonePerso;

  @override
  State<FicheFormPage> createState() => _FicheFormPageState();
}

class _FicheFormPageState extends State<FicheFormPage> {
  late final _nom = TextEditingController(text: widget.fiche.nom);
  late final _metier = TextEditingController(text: widget.fiche.metier);
  late final _description = TextEditingController(text: widget.fiche.description);
  late final _adresse = TextEditingController(text: widget.fiche.adresse);
  late final _ville = TextEditingController(text: widget.fiche.ville);
  late final _telephone = TextEditingController(text: widget.fiche.telephone);
  late final _email = TextEditingController(text: widget.fiche.email);
  late final _site = TextEditingController(text: widget.fiche.site);
  late final _telephonePerso = TextEditingController(text: widget.telephonePerso);
  late String _secteur = widget.fiche.secteur;
  bool _envoiLogo = false;
  String? _erreur;

  @override
  void dispose() {
    for (final c in [_nom, _metier, _description, _adresse, _ville, _telephone, _email, _site, _telephonePerso]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _changerLogo() async {
    setState(() => _envoiLogo = true);
    final erreur = await context.read<ProfileCubit>().changerLogo();
    if (!mounted) return;
    setState(() {
      _envoiLogo = false;
      _erreur = erreur;
    });
  }

  void _enregistrer() {
    final messager = ScaffoldMessenger.of(context);
    final erreur = context.read<ProfileCubit>().enregistrer(
      Partner(
        id: widget.fiche.id,
        nom: _nom.text,
        metier: _metier.text,
        secteur: _secteur,
        description: _description.text,
        adresse: _adresse.text,
        ville: _ville.text,
        telephone: _telephone.text,
        email: _email.text,
        site: _site.text,
        logoUrl: widget.fiche.logoUrl,
      ),
      telephonePerso: _telephonePerso.text,
      surRefus: () => messager.showSnackBar(
        const SnackBar(content: Text("Votre fiche n'a pas pu être enregistrée. Vérifiez les champs.")),
      ),
    );
    if (erreur != null) {
      setState(() => _erreur = erreur);
      return;
    }
    messager.showSnackBar(const SnackBar(content: Text('Fiche enregistrée.')));
    Navigator.of(context).pop();
  }

  Widget _champ(
    TextEditingController controleur,
    String libelle, {
    TextInputType? clavier,
    int? max,
    String? aide,
    List<String>? autofill,
    int lignes = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controleur,
      keyboardType: clavier ?? (lignes > 1 ? TextInputType.multiline : TextInputType.text),
      maxLength: max,
      minLines: lignes,
      maxLines: lignes > 1 ? lignes + 4 : 1,
      autofillHints: autofill,
      autocorrect: clavier == null,
      textCapitalization: clavier == null ? TextCapitalization.sentences : TextCapitalization.none,
      decoration: InputDecoration(labelText: libelle, helperText: aide, helperMaxLines: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('PARQUET.')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          // Le logo vient du Cubit : il change dès que l'envoi est terminé.
          final fiche = state is ProfileSuccess ? state.fiche : widget.fiche;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Semantics(header: true, child: Text('MA FICHE', style: theme.textTheme.displaySmall)),
              Text(
                "Votre fiche est publique : elle apparaît dans l'annuaire, visible sans compte.",
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  PartnerLogo(fiche, taille: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.image_outlined),
                      label: Text(_envoiLogo ? 'Envoi…' : "Logo de l'entreprise"),
                      onPressed: _envoiLogo ? null : _changerLogo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Une photo de personne est une donnée personnelle : le champ n'accepte que le logo (partie 5).
              Text(
                "Le logo de l'entreprise uniquement : pas de photo de personne.",
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _champ(_nom, "Nom de l'entreprise", max: 80),
              _champ(_metier, 'Activité (métier)', max: 60),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: _secteur,
                  decoration: const InputDecoration(labelText: 'Secteur'),
                  items: [for (final s in secteurs) DropdownMenuItem(value: s, child: Text(s))],
                  onChanged: (s) => setState(() => _secteur = s ?? _secteur),
                ),
              ),
              _champ(_description, 'Description', max: 1000, lignes: 3),
              _champ(_adresse, 'Adresse', max: 120, autofill: const [AutofillHints.streetAddressLine1]),
              _champ(_ville, 'Ville', max: 60, autofill: const [AutofillHints.addressCity]),
              _champ(_telephone, 'Téléphone professionnel', clavier: TextInputType.phone),
              _champ(_email, 'E-mail professionnel', clavier: TextInputType.emailAddress),
              _champ(_site, 'Site web', clavier: TextInputType.url, aide: 'Adresse complète, en https://'),
              const SizedBox(height: 8),
              Semantics(header: true, child: Text('Réservé au bureau', style: theme.textTheme.titleLarge)),
              const SizedBox(height: 8),
              // Message de visibilité à côté du champ personnel (charte).
              _champ(
                _telephonePerso,
                'Téléphone personnel (facultatif)',
                clavier: TextInputType.phone,
                aide: "Visible uniquement par le bureau du club, jamais dans l'annuaire.",
              ),
              if (_erreur != null)
                Semantics(
                  liveRegion: true,
                  child: Text(_erreur!, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(onPressed: _enregistrer, child: const Text('Enregistrer')),
        ),
      ),
    );
  }
}
