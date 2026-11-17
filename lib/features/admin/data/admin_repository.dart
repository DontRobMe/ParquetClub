import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Compte vu par le bureau : `users/{uid}`.
class Compte {
  const Compte({required this.uid, required this.email, required this.actif});

  final String uid;
  final String email;
  final bool actif;
}

/// Réponse d'un partenaire, vue par le bureau (F13).
class ReponseBureau {
  const ReponseBureau({required this.uid, required this.vient, required this.nbPersonnes});

  final String uid;
  final bool vient;
  final int nbPersonnes;
}

/// Erreur déjà traduite pour l'écran.
class AdminErreur implements Exception {
  const AdminErreur(this.message);
  final String message;
}

/// Seule classe du bureau qui connaît Firebase. Les actions sensibles passent par les Cloud Functions,
/// qui revérifient le rôle : masquer un bouton ne protège rien (OWASP M3).
class AdminRepository {
  AdminRepository([FirebaseFirestore? firestore, FirebaseFunctions? functions, FirebaseAuth? auth])
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west9'),
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  /// Comptes partenaires (les comptes du bureau ne sont pas listés).
  Stream<List<Compte>> ecouterComptes() => _firestore
      .collection('users')
      .where('role', isEqualTo: 'partenaire')
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs)
            Compte(uid: doc.id, email: doc.data()['email'] as String? ?? '', actif: doc.data()['disabled'] != true),
        ],
      );

  /// F3. Le partenaire reçoit ensuite l'e-mail Firebase pour choisir lui-même son mot de passe.
  Future<void> creerPartenaire({required String nom, required String email}) async {
    await _appeler('creerPartenaire', {'nom': nom, 'email': email});
    await envoyerLienMotDePasse(email);
  }

  /// F4.
  Future<void> changerAcces(String uid, {required bool actif}) =>
      _appeler('changerAcces', {'uid': uid, 'actif': actif});

  /// F5.
  Future<void> supprimerPartenaire(String uid) => _appeler('supprimerPartenaire', {'uid': uid});

  /// F2 côté bureau : déclenche le lien, sans jamais voir de mot de passe.
  Future<void> envoyerLienMotDePasse(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      throw const AdminErreur("Le lien n'a pas pu être envoyé. Vérifiez la connexion et réessayez.");
    }
  }

  /// F13. Réponses à un événement, en temps réel.
  Stream<List<ReponseBureau>> ecouterReponses(String eventId) => _firestore
      .collection('events')
      .doc(eventId)
      .collection('responses')
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs)
            ReponseBureau(
              uid: doc.id,
              vient: doc.data()['vient'] == true,
              nbPersonnes: doc.data()['nbPersonnes'] is int ? doc.data()['nbPersonnes'] as int : 0,
            ),
        ],
      );

  Future<void> _appeler(String fonction, Map<String, Object?> donnees) async {
    try {
      await _functions.httpsCallable(fonction).call<void>(donnees);
    } on FirebaseFunctionsException catch (e) {
      throw AdminErreur(switch (e.code) {
        'unavailable' || 'deadline-exceeded' => 'Pas de connexion internet. Réessayez une fois en ligne.',
        // Messages écrits par nos Cloud Functions, déjà en français.
        'already-exists' ||
        'invalid-argument' ||
        'failed-precondition' ||
        'permission-denied' => e.message ?? 'Action refusée.',
        _ => 'Action impossible pour le moment. Réessayez.',
      });
    }
  }
}
