import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/features/auth/logic/auth_cubit.dart';
import 'package:parquet/features/auth/logic/auth_state.dart';

import '../../fake_auth_repository.dart';

Future<void> laisserPasser() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAuthRepository repository;
  late AuthCubit cubit;

  setUp(() {
    repository = FakeAuthRepository();
    cubit = AuthCubit(repository)..demarrer(); // Arrange
  });

  tearDown(() => cubit.close());

  test('sans session enregistrée, on est visiteur', () async {
    await laisserPasser();
    expect(cubit.state, isA<AuthVisiteur>());
  });

  test('connexion réussie : session du partenaire', () async {
    await laisserPasser();
    final erreur = await cubit.connecter(' contact@cap-conseil.example ', 'bon'); // Act
    await laisserPasser();
    expect(erreur, isNull); // Assert
    expect((cubit.state as AuthConnecte).session.uid, 'p1');
  });

  test('mauvais mot de passe : message, on reste visiteur', () async {
    await laisserPasser();
    final erreur = await cubit.connecter('contact@cap-conseil.example', 'faux');
    expect(erreur, 'E-mail ou mot de passe incorrect.');
    expect(cubit.state, isA<AuthVisiteur>());
  });

  test('champs vides : refusé sans appeler le serveur', () async {
    expect(await cubit.connecter('', ''), isNotNull);
  });

  test('mot de passe oublié : réponse neutre et lien envoyé', () async {
    final message = await cubit.envoyerLienReinitialisation('inconnu@exemple.fr');
    expect(message, startsWith('Si un compte existe'));
    expect(repository.liensEnvoyes, ['inconnu@exemple.fr']);
  });

  test('déconnexion : retour visiteur', () async {
    await laisserPasser();
    await cubit.connecter('contact@cap-conseil.example', 'bon');
    await laisserPasser();
    await cubit.deconnecter();
    await laisserPasser();
    expect(cubit.state, isA<AuthVisiteur>());
  });
}
