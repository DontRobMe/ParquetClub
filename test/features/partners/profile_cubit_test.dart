import 'package:flutter_test/flutter_test.dart';
import 'package:parquet/features/partners/data/partner.dart';
import 'package:parquet/features/partners/logic/profile_cubit.dart';

import '../../fake_partner_repository.dart';

Future<void> laisserPasser() => Future<void>.delayed(Duration.zero);

Partner avec({String nom = 'Cap Conseil', String site = '', String email = '', String telephone = ''}) =>
    Partner(id: 'p1', nom: nom, site: site, email: email, telephone: telephone);

void main() {
  late FakePartnerRepository repository;
  late ProfileCubit cubit;

  setUp(() {
    repository = FakePartnerRepository();
    cubit = ProfileCubit(repository, 'p1')..charger(); // Arrange
  });

  tearDown(() => cubit.close());

  test('affiche ma fiche et mon téléphone personnel', () async {
    repository.fiche.add(maFiche); // Act
    repository.telephone.add('06 00 00 00 00');
    await laisserPasser();
    final state = cubit.state as ProfileSuccess; // Assert
    expect(state.fiche.nom, 'Cap Conseil');
    expect(state.telephonePerso, '06 00 00 00 00');
  });

  test('fiche absente : erreur', () async {
    repository.fiche.add(null);
    await laisserPasser();
    expect(cubit.state, isA<ProfileError>());
  });

  test('enregistrer : valeurs nettoyées, uid du compte connecté', () async {
    final erreur = cubit.enregistrer(
      const Partner(id: 'autre', nom: '  Cap Conseil ', ville: ' Panazol '),
      telephonePerso: ' 06 00 00 00 00 ',
    );
    await laisserPasser();
    expect(erreur, isNull);
    expect(repository.fichesEnregistrees.single.id, 'p1'); // jamais la fiche d'un autre
    expect(repository.fichesEnregistrees.single.ville, 'Panazol');
    expect(repository.telephonesEnregistres.single, '06 00 00 00 00');
  });

  test('fiche invalide : rien n\'est envoyé', () async {
    expect(cubit.enregistrer(avec(nom: ''), telephonePerso: ''), isNotNull);
    expect(repository.fichesEnregistrees, isEmpty);
  });

  test('logo refusé : message affiché', () async {
    repository.refusLogo = 'Image trop lourde (1 Mo maximum).';
    expect(await cubit.changerLogo(), 'Image trop lourde (1 Mo maximum).');
  });

  group('vérification de la fiche (OWASP M4)', () {
    test('fiche correcte', () {
      expect(
        verifierFiche(
          avec(site: 'https://cap-conseil.fr', email: 'contact@cap.fr', telephone: '05 55 00 00 00'),
          '+33 6 00 00 00 00',
        ),
        isNull,
      );
    });

    test('site en http refusé', () => expect(verifierFiche(avec(site: 'http://cap.fr'), ''), isNotNull));

    test('lien javascript refusé', () => expect(verifierFiche(avec(site: 'javascript:alert(1)'), ''), isNotNull));

    test('e-mail invalide refusé', () => expect(verifierFiche(avec(email: 'cap.fr'), ''), isNotNull));

    test('téléphone avec des lettres refusé', () => expect(verifierFiche(avec(), 'appelez-moi'), isNotNull));

    test('nom trop long refusé', () => expect(verifierFiche(avec(nom: 'x' * 81), ''), isNotNull));
  });
}
