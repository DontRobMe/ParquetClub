import '../data/auth_repository.dart';

/// Qui utilise l'app : décide de l'écran d'arrivée et des onglets.
sealed class AuthState {
  const AuthState();
}

/// Session pas encore lue : écran de lancement.
class AuthInconnu extends AuthState {
  const AuthInconnu();
}

/// Aucun compte : accueil du club et annuaire en lecture seule.
class AuthVisiteur extends AuthState {
  const AuthVisiteur();
}

class AuthConnecte extends AuthState {
  const AuthConnecte(this.session);
  final Session session;
}
