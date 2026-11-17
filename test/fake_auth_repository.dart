import 'dart:async';

import 'package:parquet/features/auth/data/auth_repository.dart';

const partenaire = Session(uid: 'p1', email: 'contact@cap-conseil.example', estAdmin: false);
const bureau = Session(uid: 'b1', email: 'bureau@club.example', estAdmin: true);

/// Faux Firebase Auth : un seul compte valide, `motDePasse` = « bon ».
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.compte = partenaire, this.connecteAuDemarrage = false});

  final Session compte;
  final bool connecteAuDemarrage;
  final _session = StreamController<Session?>.broadcast();
  final liensEnvoyes = <String>[];

  @override
  Stream<Session?> session() async* {
    yield connecteAuDemarrage ? compte : null;
    yield* _session.stream;
  }

  @override
  Future<void> connecter(String email, String motDePasse) async {
    if (email != compte.email || motDePasse != 'bon') throw const AuthErreur('E-mail ou mot de passe incorrect.');
    _session.add(compte);
  }

  @override
  Future<void> envoyerLienReinitialisation(String email) async => liensEnvoyes.add(email);

  @override
  Future<void> deconnecter() async => _session.add(null);
}
