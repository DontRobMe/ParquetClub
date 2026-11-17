import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/features/partners/logic/partners_cubit.dart';
import 'package:parquet/features/partners/logic/partners_state.dart';

import '../../fake_partner_repository.dart';

Future<void> laisserPasser() => Future<void>.delayed(Duration.zero);

void main() {
  late FakePartnerRepository repository;
  late PartnersCubit cubit;

  setUp(() {
    repository = FakePartnerRepository();
    cubit = PartnersCubit(repository)..charger(); // Arrange
  });

  tearDown(() => cubit.close());

  test('démarre en chargement', () {
    expect(cubit.state, isA<PartnersLoading>());
  });

  test('affiche les partenaires reçus', () async {
    repository.envoyer([atelier, cap]); // Act
    await laisserPasser();
    final state = cubit.state as PartnersSuccess; // Assert
    expect(state.partenaires, [atelier, cap]);
    expect(state.horsLigne, isFalse);
  });

  test('annuaire vide donne l\'état vide', () async {
    repository.envoyer([]);
    await laisserPasser();
    expect(cubit.state, isA<PartnersEmpty>());
  });

  test('une erreur Firestore donne l\'état erreur', () async {
    repository.controller.addError(Exception('permission-denied'));
    await laisserPasser();
    expect(cubit.state, isA<PartnersError>());
  });

  test('données du cache signalées hors ligne', () async {
    repository.envoyer([atelier], horsLigne: true);
    await laisserPasser();
    expect((cubit.state as PartnersSuccess).horsLigne, isTrue);
  });

  test('recherche par métier, sans tenir compte des accents ni des majuscules', () async {
    repository.envoyer([atelier, cap, grain]);
    await laisserPasser();
    cubit.rechercher('TORREFACTEUR');
    expect((cubit.state as PartnersSuccess).partenaires, [grain]);
  });

  test('recherche par ville et filtre par secteur combinés', () async {
    repository.envoyer([atelier, cap, grain]);
    await laisserPasser();
    cubit
      ..rechercher('limoges')
      ..filtrerSecteur('Artisanat');
    expect((cubit.state as PartnersSuccess).partenaires, [atelier]);
  });

  test('retrouve un partenaire par son identifiant', () async {
    repository.envoyer([atelier, cap]);
    await laisserPasser();
    expect(cubit.partenaire('c'), cap);
    expect(cubit.partenaire('inconnu'), isNull);
  });
}
