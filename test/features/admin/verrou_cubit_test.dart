import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/features/admin/logic/verrou_cubit.dart';

import '../../fake_verrou_repository.dart';

void main() {
  test("préférence active : verrouillé dès l'ouverture", () async {
    final cubit = VerrouCubit(FakeVerrouRepository(estActif: true)); // Arrange
    await cubit.demarrer(); // Act
    expect(cubit.state.verrouille, isTrue); // Assert
  });

  test('préférence inactive : jamais verrouillé', () async {
    final cubit = VerrouCubit(FakeVerrouRepository());
    await cubit.demarrer();
    cubit.verrouiller();
    expect(cubit.state.verrouille, isFalse);
  });

  test('biométrie réussie : déverrouillé', () async {
    final cubit = VerrouCubit(FakeVerrouRepository(estActif: true));
    await cubit.demarrer();
    await cubit.deverrouiller();
    expect(cubit.state.verrouille, isFalse);
  });

  test('biométrie échouée : reste verrouillé', () async {
    final cubit = VerrouCubit(FakeVerrouRepository(estActif: true, reussit: false));
    await cubit.demarrer();
    await cubit.deverrouiller();
    expect(cubit.state.verrouille, isTrue);
  });

  test('retour au premier plan : verrouillé à nouveau', () async {
    final cubit = VerrouCubit(FakeVerrouRepository(estActif: true));
    await cubit.demarrer();
    await cubit.deverrouiller();
    cubit.verrouiller(); // l'app est passée en arrière-plan
    expect(cubit.state.verrouille, isTrue);
  });

  test('activer exige une authentification réussie, rangée dans le coffre', () async {
    final repo = FakeVerrouRepository(reussit: false);
    final cubit = VerrouCubit(repo);
    await cubit.demarrer();
    expect(await cubit.changerPreference(actif: true), isNotNull);
    expect(repo.estActif, isFalse);

    repo.reussit = true;
    expect(await cubit.changerPreference(actif: true), isNull);
    expect(repo.estActif, isTrue);
    expect(cubit.state.verrouille, isFalse); // on vient de s'authentifier
  });

  test('téléphone sans biométrie : préférence ignorée', () async {
    final cubit = VerrouCubit(FakeVerrouRepository(estDisponible: false, estActif: true));
    await cubit.demarrer();
    expect(cubit.state.verrouille, isFalse);
    expect(await cubit.changerPreference(actif: true), isNotNull);
  });
}
