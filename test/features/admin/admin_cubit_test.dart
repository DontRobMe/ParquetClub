import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/features/admin/data/admin_repository.dart';
import 'package:parquet/features/admin/logic/admin_cubit.dart';
import 'package:parquet/features/admin/logic/admin_state.dart';

import '../../fake_admin_repository.dart';

Future<void> laisserPasser() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAdminRepository repository;

  setUp(() => repository = FakeAdminRepository());

  group('AdminCubit', () {
    late AdminCubit cubit;
    setUp(() => cubit = AdminCubit(repository)..charger()); // Arrange
    tearDown(() => cubit.close());

    test('compte les partenaires actifs', () async {
      repository.comptes.add(const [
        Compte(uid: 'a', email: 'a@x.fr', actif: true),
        Compte(uid: 'b', email: 'b@x.fr', actif: false),
      ]); // Act
      await laisserPasser();
      expect((cubit.state as AdminSuccess).actifs, 1); // Assert
    });

    test('aucun partenaire donne l\'état vide', () async {
      repository.comptes.add(const []);
      await laisserPasser();
      expect(cubit.state, isA<AdminEmpty>());
    });

    test('erreur Firestore donne l\'état erreur', () async {
      repository.comptes.addError(Exception('permission-denied'));
      await laisserPasser();
      expect(cubit.state, isA<AdminError>());
    });

    test('inviter sans e-mail valide est refusé sans appeler le serveur', () async {
      expect(await cubit.inviter(nom: 'Cap Conseil', email: 'pas-un-mail'), isNotNull);
      expect(repository.appels, isEmpty);
    });

    test('inviter appelle la Cloud Function avec des valeurs nettoyées', () async {
      expect(await cubit.inviter(nom: ' Cap Conseil ', email: ' cap@x.fr '), isNull);
      expect(repository.appels, ['creer:Cap Conseil:cap@x.fr']);
    });

    test('un refus du serveur est renvoyé tel quel à l\'écran', () async {
      repository.refus = 'Un compte existe déjà avec cet e-mail.';
      expect(await cubit.supprimer('a'), 'Un compte existe déjà avec cet e-mail.');
    });
  });

  group('ReponsesCubit', () {
    test('total des participants : seuls ceux qui viennent comptent', () async {
      final cubit = ReponsesCubit(repository, 'loge')..charger();
      repository.reponses.add(const [
        ReponseBureau(uid: 'a', vient: true, nbPersonnes: 3),
        ReponseBureau(uid: 'b', vient: true, nbPersonnes: 2),
        ReponseBureau(uid: 'c', vient: false, nbPersonnes: 0),
      ]);
      await laisserPasser();
      expect((cubit.state as ReponsesSuccess).total, 5);
      await cubit.close();
    });

    test('aucune réponse donne l\'état vide', () async {
      final cubit = ReponsesCubit(repository, 'loge')..charger();
      repository.reponses.add(const []);
      await laisserPasser();
      expect(cubit.state, isA<ReponsesEmpty>());
      await cubit.close();
    });
  });
}
