import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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

/// Ligne du journal des actions du bureau (F18).
class EntreeJournal {
  const EntreeJournal({required this.auteur, required this.action, required this.cible, this.date});

  final String auteur; // e-mail du bénévole
  final String action;
  final String cible;
  final DateTime? date;
}

/// Erreur déjà traduite pour l'écran.
class AdminErreur implements Exception {
  const AdminErreur(this.message);
  final String message;
}

/// Seule classe du bureau qui connaît Firebase.
/// Forfait Spark (sans Cloud Functions) : les actions du bureau sont faites depuis son téléphone, et ce sont
/// les règles Firestore qui vérifient qu'il est bien admin. Masquer un bouton ne protège rien (OWASP M3).
class AdminRepository {
  AdminRepository([FirebaseFirestore? firestore, FirebaseAuth? auth])
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _horsLigne = 'Pas de connexion internet. Réessayez une fois en ligne.';

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

  /// F3. Le compte est créé avec un mot de passe aléatoire que personne ne voit ; le partenaire reçoit
  /// ensuite l'e-mail Firebase pour choisir le sien.
  Future<void> creerPartenaire({required String nom, required String email}) async {
    // Une seconde instance de Firebase : créer un compte connecte ce compte, et le bénévole doit rester connecté.
    final secondaire = await Firebase.initializeApp(
      name: 'creation-compte',
      options: Firebase.app().options,
    ).catchError((Object _) => Firebase.app('creation-compte'));
    final authSecondaire = FirebaseAuth.instanceFor(app: secondaire);
    final String uid;
    try {
      final compte = await authSecondaire.createUserWithEmailAndPassword(email: email, password: _motDePasseJetable());
      uid = compte.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AdminErreur(switch (e.code) {
        // Souvent un partenaire supprimé qui ne s'est pas reconnecté depuis : son compte de connexion existe encore
        // (forfait Spark, voir supprimerPartenaire) et seule la console peut l'effacer.
        'email-already-in-use' =>
          'Un compte de connexion existe déjà pour cet e-mail. S\'il s\'agit d\'un partenaire supprimé, '
              'effacez-le dans la console Firebase (Authentication), puis réessayez.',
        'invalid-email' => "Cet e-mail n'est pas valide.",
        'network-request-failed' => _horsLigne,
        _ => 'Le compte n\'a pas pu être créé. Réessayez.',
      });
    } finally {
      await authSecondaire.signOut();
    }

    final lot = _firestore.batch()
      ..set(_firestore.collection('users').doc(uid), {'email': email, 'role': 'partenaire', 'disabled': false})
      ..set(_firestore.collection('partners').doc(uid), {
        'nom': nom,
        'metier': '',
        'secteur': 'Autre',
        'description': '',
        'adresse': '',
        'ville': '',
        'telephone': '',
        'email': '',
        'site': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    _journal(lot, 'création du compte', nom);
    await _ecrire(lot);
    await envoyerLienMotDePasse(email);
  }

  /// F4. Les règles Firestore refusent aussitôt toute lecture et écriture au compte désactivé,
  /// et l'app le déconnecte dès qu'elle voit le changement.
  Future<void> changerAcces(String uid, {required bool actif, required String nom}) async {
    final lot = _firestore.batch()..update(_firestore.collection('users').doc(uid), {'disabled': !actif});
    _journal(lot, actif ? "réactivation de l'accès" : "désactivation de l'accès", nom);
    await _ecrire(lot);
  }

  /// F5. Efface la fiche (logo compris), le numéro privé, les réponses et le profil.
  /// Sans Cloud Functions, l'app ne peut pas supprimer le compte de connexion d'un autre : il s'efface
  /// lui-même à sa prochaine tentative de connexion (AuthRepository.connecter).
  Future<void> supprimerPartenaire(String uid, {required String nom}) async {
    try {
      final evenements = await _firestore.collection('events').get();
      final lot = _firestore.batch();
      // ponytail: un seul lot de 500 écritures, soit environ 495 événements ; découper au-delà.
      for (final e in evenements.docs) {
        lot.delete(e.reference.collection('responses').doc(uid));
      }
      lot
        ..delete(_firestore.collection('partners').doc(uid).collection('private').doc('contact'))
        ..delete(_firestore.collection('partners').doc(uid))
        ..delete(_firestore.collection('users').doc(uid));
      _journal(lot, 'suppression du partenaire', nom);
      await lot.commit();
    } on FirebaseException {
      throw const AdminErreur(_horsLigne);
    }
  }

  /// RGPD : les réponses sont effacées 12 mois après l'événement. Lancé à l'ouverture de l'espace bureau.
  Future<void> purgerReponsesAnciennes() async {
    final limite = DateTime.now().subtract(const Duration(days: 365));
    final anciens = await _firestore.collection('events').where('date', isLessThan: Timestamp.fromDate(limite)).get();
    for (final e in anciens.docs) {
      final reponses = await e.reference.collection('responses').get();
      if (reponses.docs.isEmpty) continue;
      final lot = _firestore.batch();
      for (final r in reponses.docs) {
        lot.delete(r.reference);
      }
      await lot.commit();
    }
  }

  /// F2 côté bureau : déclenche le lien, sans jamais voir de mot de passe.
  Future<void> envoyerLienMotDePasse(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      throw const AdminErreur("Le lien n'a pas pu être envoyé. Vérifiez la connexion et réessayez.");
    }
  }

  /// F7. Téléphone personnel d'un partenaire : lisible par lui et par le bureau seulement.
  Future<String> telephonePerso(String uid) async {
    final doc = await _firestore.collection('partners').doc(uid).collection('private').doc('contact').get();
    return doc.data()?['telephonePerso'] as String? ?? '';
  }

  /// F18. Les 100 dernières actions du bureau, les plus récentes d'abord.
  Stream<List<EntreeJournal>> ecouterJournal() => _firestore
      .collection('adminLogs')
      .orderBy('date', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs)
            EntreeJournal(
              auteur: doc.data()['auteurEmail'] as String? ?? '',
              action: doc.data()['action'] as String? ?? '',
              cible: doc.data()['cible'] as String? ?? '',
              date: (doc.data()['date'] as Timestamp?)?.toDate(),
            ),
        ],
      );

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

  /// Ajoute l'entrée du journal dans le même lot que l'action : les deux réussissent ou échouent ensemble.
  void _journal(WriteBatch lot, String action, String cible) => ajouterAuJournal(_firestore, _auth, lot, action, cible);

  Future<void> _ecrire(WriteBatch lot) async {
    try {
      await lot.commit();
    } on FirebaseException {
      throw const AdminErreur(_horsLigne);
    }
  }
}

/// Entrée du journal (F18). Les règles vérifient que l'auteur est bien le compte connecté.
void ajouterAuJournal(FirebaseFirestore firestore, FirebaseAuth auth, WriteBatch lot, String action, String cible) {
  final moi = auth.currentUser;
  lot.set(firestore.collection('adminLogs').doc(), {
    'auteur': moi?.uid,
    'auteurEmail': moi?.email ?? '',
    'action': action,
    'cible': cible,
    'date': FieldValue.serverTimestamp(),
  });
}

/// 32 caractères aléatoires (générateur cryptographique), jamais affichés ni stockés.
String _motDePasseJetable() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%&*';
  final hasard = Random.secure();
  return List.generate(32, (_) => alphabet[hasard.nextInt(alphabet.length)]).join();
}
