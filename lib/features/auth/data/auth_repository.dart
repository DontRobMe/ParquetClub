import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Compte connecté. Le rôle et l'état actif viennent de `users/{uid}`, que seul le bureau peut écrire :
/// les règles Firestore interdisent à un partenaire de modifier son propre rôle (cahier des charges, partie 5).
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
  AuthRepository([FirebaseAuth? auth, FirebaseFirestore? firestore])
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profil(String uid) => _firestore.collection('users').doc(uid);

  /// Session courante : compte Firebase + profil `users/{uid}` (rôle, désactivé), suivis en temps réel.
  /// Un compte désactivé par le bureau est déconnecté aussitôt, même s'il était déjà ouvert (F4).
  Stream<Session?> session() {
    StreamSubscription<User?>? compte;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? profil;
    late final StreamController<Session?> sortie;
    sortie = StreamController<Session?>(
      onListen: () => compte = _auth.authStateChanges().listen((user) {
        profil?.cancel();
        if (user == null) {
          sortie.add(null);
          return;
        }
        profil = _profil(user.uid).snapshots().listen((doc) {
          // Hors ligne au premier lancement, le profil peut manquer du cache : on attend le réseau.
          if (!doc.exists && doc.metadata.isFromCache) return;
          final data = doc.data();
          if (data == null || data['disabled'] == true) {
            _auth.signOut();
            return;
          }
          sortie.add(Session(uid: user.uid, email: user.email ?? '', estAdmin: data['role'] == 'admin'));
        }, onError: (Object _) => sortie.add(null));
      }, onError: (Object _) => sortie.add(null)),
      onCancel: () {
        profil?.cancel();
        compte?.cancel();
      },
    );
    return sortie.stream;
  }

  /// F1. Pas d'inscription : les comptes sont créés par le bureau.
  Future<void> connecter(String email, String motDePasse) async {
    final UserCredential resultat;
    try {
      resultat = await _auth.signInWithEmailAndPassword(email: email, password: motDePasse);
    } on FirebaseAuthException catch (e) {
      throw AuthErreur(switch (e.code) {
        'network-request-failed' => 'Pas de connexion internet. Réessayez une fois en ligne.',
        'too-many-requests' => 'Trop de tentatives. Réessayez dans quelques minutes.',
        'user-disabled' => 'Ce compte est désactivé. Contactez le bureau du club.',
        // Même message que l'e-mail existe ou non : on ne révèle pas quels comptes existent.
        _ => 'E-mail ou mot de passe incorrect.',
      });
    }
    // Le mot de passe est bon, mais le bureau a peut-être désactivé ou supprimé l'accès.
    final profil = await _profil(resultat.user!.uid)
        .get()
        .catchError((Object _) => throw const AuthErreur('Pas de connexion internet. Réessayez une fois en ligne.'));
    if (!profil.exists) {
      // Partenaire supprimé par le bureau. Sans Cloud Functions (forfait Spark), seul le compte lui-même peut
      // effacer sa connexion : il le fait ici, juste après s'être connecté (Firebase l'exige).
      await resultat.user!.delete().catchError((Object _) => _auth.signOut());
      throw const AuthErreur('Ce compte a été supprimé. Contactez le bureau du club.');
    }
    if (profil.data()?['disabled'] == true) {
      await _auth.signOut();
      throw const AuthErreur('Ce compte est désactivé. Contactez le bureau du club.');
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
