import 'package:parquet/features/admin/data/verrou_repository.dart';

/// Faux capteur biométrique et faux coffre (Keystore / Keychain).
class FakeVerrouRepository implements VerrouRepository {
  FakeVerrouRepository({this.estDisponible = true, this.estActif = false, this.reussit = true});

  bool estDisponible;
  bool estActif; // contenu du coffre
  bool reussit; // résultat de la prochaine authentification
  var authentifications = 0;

  @override
  Future<bool> disponible() async => estDisponible;

  @override
  Future<bool> actif() async => estActif;

  @override
  Future<void> enregistrer({required bool actif}) async => estActif = actif;

  @override
  Future<bool> authentifier() async {
    authentifications++;
    return reussit;
  }
}
