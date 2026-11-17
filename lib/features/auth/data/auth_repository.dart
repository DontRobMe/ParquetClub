import 'package:firebase_auth/firebase_auth.dart';

/// Compte connecté. Le rôle vient du custom claim posé par la Cloud Function :
/// personne ne peut le modifier depuis l'app (cahier des charges, partie 5).
class Session {
  const Session({required this.uid, required this.email, required this.estAdmin});

  final String uid;
  final String email;
  final bool estAdmin;
}

/// Erreur déjà traduite pour l'écran : le Cubit ne connaît pas les codes Firebase.
class AuthErreur implements Exception {
  const AuthErreur(this.message);
  final String message;
}

/// Seule classe de la connexion qui connaît Firebase Auth (le faux repository des tests fait `implements`).
class AuthRepository {
  AuthRepository([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Session courante, mise à jour à chaque connexion, déconnexion ou rafraîchissement du jeton (rôle modifié).
  Stream<Session?> session() => _auth.idTokenChanges().asyncMap((user) async {
    if (user == null) return null;
    final jeton = await user.getIdTokenResult();
    return Session(uid: user.uid, email: user.email ?? '', estAdmin: jeton.claims?['role'] == 'admin');
  });

  /// F1. Pas d'inscription : les comptes sont créés par le bureau.
  Future<void> connecter(String email, String motDePasse) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: motDePasse);
    } on FirebaseAuthException catch (e) {
      throw AuthErreur(switch (e.code) {
        'network-request-failed' => 'Pas de connexion internet. Réessayez une fois en ligne.',
        'too-many-requests' => 'Trop de tentatives. Réessayez dans quelques minutes.',
        'user-disabled' => 'Ce compte est désactivé. Contactez le bureau du club.',
        // Même message que l'e-mail existe ou non : on ne révèle pas quels comptes existent.
        _ => 'E-mail ou mot de passe incorrect.',
      });
    }
  }

  /// F2. Firebase envoie le lien ; personne ne voit jamais le mot de passe.
  Future<void> envoyerLienReinitialisation(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const AuthErreur('Pas de connexion internet. Réessayez une fois en ligne.');
      }
      // Autres erreurs (adresse inconnue…) : on répond comme si l'envoi avait réussi.
    }
  }

  Future<void> deconnecter() => _auth.signOut();
}
