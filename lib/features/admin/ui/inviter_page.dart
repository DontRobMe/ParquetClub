import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../logic/admin_cubit.dart';
import 'confirmer.dart';

/// F3. Le bureau saisit le nom et l'e-mail ; le partenaire reçoit un e-mail pour choisir son mot de passe.
class InviterPage extends StatefulWidget {
  const InviterPage({super.key});

  @override
  State<InviterPage> createState() => _InviterPageState();
}

class _InviterPageState extends State<InviterPage> {
  final _nom = TextEditingController();
  final _email = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _inviter() async {
    setState(() => _enCours = true);
    final erreur = await context.read<AdminCubit>().inviter(nom: _nom.text, email: _email.text);
    if (!mounted) return;
    if (erreur == null) {
      afficher(context, 'Invitation envoyée à ${_email.text.trim()}.');
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _enCours = false;
      _erreur = erreur;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const TitreParquet()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Semantics(header: true, child: Text('INVITER', style: theme.textTheme.displaySmall)),
          Text(
            "Le partenaire recevra un e-mail pour choisir son mot de passe. "
            "Sa fiche sera visible dans l'annuaire public ; il la complète lui-même.",
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nom,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 80,
            decoration: const InputDecoration(labelText: "Nom de l'entreprise"),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'E-mail du partenaire'),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(_erreur!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _enCours ? null : _inviter,
            child: Text(_enCours ? 'Envoi…' : "Envoyer l'invitation"),
          ),
        ),
      ),
    );
  }
}
