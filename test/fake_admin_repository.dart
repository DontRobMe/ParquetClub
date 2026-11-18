import 'dart:async';

import 'package:parquet/features/admin/data/admin_repository.dart';

/// Faux repository du bureau : simule les Cloud Functions sans réseau.
class FakeAdminRepository implements AdminRepository {
  final comptes = StreamController<List<Compte>>.broadcast();
  final reponses = StreamController<List<ReponseBureau>>.broadcast();
  final journal = StreamController<List<EntreeJournal>>.broadcast();
  final appels = <String>[];
  String? refus; // message d'erreur renvoyé par la prochaine action

  @override
  Stream<List<Compte>> ecouterComptes() => comptes.stream;

  @override
  Stream<List<ReponseBureau>> ecouterReponses(String eventId) => reponses.stream;

  Future<void> _action(String nom) async {
    final message = refus;
    if (message != null) throw AdminErreur(message);
    appels.add(nom);
  }

  @override
  Future<void> creerPartenaire({required String nom, required String email}) => _action('creer:$nom:$email');

  @override
  Future<void> changerAcces(String uid, {required bool actif, required String nom}) => _action('acces:$uid:$actif');

  @override
  Future<void> supprimerPartenaire(String uid, {required String nom}) => _action('supprimer:$uid');

  var purges = 0;

  @override
  Future<void> purgerReponsesAnciennes() async => purges++;

  @override
  Future<String> telephonePerso(String uid) async => '06 11 22 33 44';

  @override
  Future<void> envoyerLienMotDePasse(String email) => _action('lien:$email');

  @override
  Stream<List<EntreeJournal>> ecouterJournal() => journal.stream;
}
