import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInconnu());

  final AuthRepository _repository;
  StreamSubscription<Session?>? _abonnement;

  /// Écoute la session : Firebase la garde d'un lancement à l'autre, un compte connecté arrive donc sur ses onglets.
  void demarrer() {
    _abonnement?.cancel();
    _abonnement = _repository.session().listen(
      (session) => emit(session == null ? const AuthVisiteur() : AuthConnecte(session)),
      onError: (Object _) => emit(const AuthVisiteur()),
    );
  }

  /// Renvoie le message d'erreur à afficher, ou null si la connexion a réussi.
  /// Le changement d'écran vient ensuite tout seul de la session.
  Future<String?> connecter(String email, String motDePasse) async {
    if (email.trim().isEmpty || motDePasse.isEmpty) return 'Saisissez votre e-mail et votre mot de passe.';
    try {
      await _repository.connecter(email.trim(), motDePasse);
      return null;
    } on AuthErreur catch (e) {
      return e.message;
    }
  }

  /// Renvoie le message à afficher, neutre que le compte existe ou non.
  Future<String> envoyerLienReinitialisation(String email) async {
    if (!email.contains('@')) return 'Saisissez votre e-mail pour recevoir le lien.';
    try {
      await _repository.envoyerLienReinitialisation(email.trim());
      return "Si un compte existe pour cette adresse, un e-mail vient d'être envoyé.";
    } on AuthErreur catch (e) {
      return e.message;
    }
  }

  Future<void> deconnecter() => _repository.deconnecter();

  @override
  Future<void> close() {
    _abonnement?.cancel();
    return super.close();
  }
}
