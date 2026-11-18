import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:parquet/core/widgets/titre_parquet.dart';

import '../logic/auth_cubit.dart';

/// Connexion des partenaires et du bureau (F1) et mot de passe oublié (F2).
/// Champs, « en cours » et message : état purement local au formulaire, donc setState.
class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _enCours = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    setState(() => _enCours = true);
    final erreur = await context.read<AuthCubit>().connecter(_email.text, _motDePasse.text);
    // En cas de succès, la session change et l'app passe aux onglets du compte.
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _message = erreur;
    });
  }

  Future<void> _motDePasseOublie() async {
    setState(() => _enCours = true);
    final message = await context.read<AuthCubit>().envoyerLienReinitialisation(_email.text);
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const TitreParquet()),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Semantics(header: true, child: Text('CONNEXION', style: theme.textTheme.displaySmall)),
            Text(
              'Espace réservé aux partenaires et au bureau. Les comptes sont créés par le bureau du club.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            // Formulaire lisible : un champ par ligne, libellé au-dessus, clavier adapté (cours 5).
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _motDePasse,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _enCours ? null : _connecter(),
              decoration: const InputDecoration(labelText: 'Mot de passe'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _enCours ? null : _motDePasseOublie,
                child: const Text('Mot de passe oublié ?'),
              ),
            ),
            if (_message != null)
              Semantics(
                liveRegion: true,
                child: Text(_message!, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _enCours ? null : _connecter,
            child: _enCours
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Connexion en cours'),
                  )
                : const Text('Se connecter'),
          ),
        ),
      ),
    );
  }
}
