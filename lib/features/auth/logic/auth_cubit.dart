import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../notifications/data/notification_repository.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

/// Session et ce qui en dépend : rôle, notifications du compte.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository, this._notifications) : super(const AuthInconnu());

  final AuthRepository _repository;
  final NotificationRepository _notifications;
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

  /// Les notifications ne concernent que les partenaires (topic `partenaires`).
  bool get _partenaire => switch (state) {
    AuthConnecte(:final session) => !session.estAdmin,
    _ => false,
  };

  /// Vrai si l'écran doit d'abord expliquer pourquoi l'app demande les notifications (OWASP M6, cours 3).
  Future<bool> notificationsADemander() async {
    if (!_partenaire) return false;
    try {
      return await _notifications.permissionADemander();
    } catch (_) {
      return false;
    }
  }

  /// À chaque ouverture d'un compte partenaire : token à jour et abonnement aux invitations.
  Future<void> activerNotifications() async {
    final s = state;
    if (s is! AuthConnecte || !_partenaire) return;
    try {
      await _notifications.activer(s.session.uid);
    } catch (_) {
      // Sans réseau ou sans autorisation, l'app reste utilisable ; nouvel essai à la prochaine ouverture.
    }
  }

  /// Événements à ouvrir après un appui sur une notification.
  Stream<String> get evenementsOuverts => _notifications.evenementsOuverts();

  Future<void> deconnecter() async {
    try {
      await _notifications.desactiver();
    } catch (_) {
      // Hors ligne : l'abonnement reste côté serveur jusqu'au prochain token ; la session est quand même fermée.
    }
    await _repository.deconnecter();
  }

  @override
  Future<void> close() {
    _abonnement?.cancel();
    return super.close();
  }
}
