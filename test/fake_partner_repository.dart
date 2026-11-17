import 'dart:async';

import 'package:parquet/features/partners/data/partner.dart';
import 'package:parquet/features/partners/data/partner_repository.dart';

/// Faux repository : les tests poussent eux-mêmes ce que « Firestore » renvoie, sans émulateur.
class FakePartnerRepository implements PartnerRepository {
  final controller = StreamController<AnnuaireSnapshot>.broadcast();
  final fiche = StreamController<Partner?>.broadcast();
  final telephone = StreamController<String>.broadcast();
  final fichesEnregistrees = <Partner>[];
  final telephonesEnregistres = <String>[];
  String? refusLogo;
  var logosEnvoyes = 0;

  @override
  Stream<AnnuaireSnapshot> ecouterPartenaires() => controller.stream;

  void envoyer(List<Partner> partenaires, {bool horsLigne = false}) =>
      controller.add((partenaires: partenaires, horsLigne: horsLigne));

  @override
  Stream<Partner?> ecouterFiche(String uid) => fiche.stream;

  @override
  Stream<String> ecouterTelephonePerso(String uid) => telephone.stream;

  @override
  Future<void> mettreAJourFiche(Partner p) async => fichesEnregistrees.add(p);

  @override
  Future<void> enregistrerTelephonePerso(String uid, String tel) async => telephonesEnregistres.add(tel);

  @override
  Future<bool> choisirEtEnvoyerLogo(String uid) async {
    final message = refusLogo;
    if (message != null) throw PartnerErreur(message);
    logosEnvoyes++;
    return true;
  }
}

const atelier = Partner(id: 'a', nom: 'Atelier Martin', metier: 'Menuiserie', secteur: 'Artisanat', ville: 'Limoges');
const cap = Partner(
  id: 'c',
  nom: 'Cap Conseil',
  metier: 'Expertise comptable',
  secteur: 'Services',
  ville: 'Panazol',
  telephone: '05 55 00 00 00',
  site: 'https://cap-conseil.example',
);
const grain = Partner(id: 'g', nom: 'Grain & Match', metier: 'Torréfacteur', secteur: 'Restauration', ville: 'Limoges');

/// Fiche du partenaire connecté dans les tests (uid p1, voir fake_auth_repository.dart).
const maFiche = Partner(id: 'p1', nom: 'Cap Conseil', metier: 'Expertise comptable', ville: 'Panazol');
