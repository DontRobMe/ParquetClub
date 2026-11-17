import 'dart:async';

import 'package:parquet/features/partners/data/partner.dart';
import 'package:parquet/features/partners/data/partner_repository.dart';

/// Faux repository : les tests poussent eux-mêmes ce que « Firestore » renvoie, sans émulateur.
class FakePartnerRepository implements PartnerRepository {
  final controller = StreamController<AnnuaireSnapshot>.broadcast();

  @override
  Stream<AnnuaireSnapshot> ecouterPartenaires() => controller.stream;

  void envoyer(List<Partner> partenaires, {bool horsLigne = false}) =>
      controller.add((partenaires: partenaires, horsLigne: horsLigne));
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
