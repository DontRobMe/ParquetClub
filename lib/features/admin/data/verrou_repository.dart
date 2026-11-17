import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// F17. Verrouillage biométrique du compte bureau.
/// Une biométrie réussie ne vaut qu'un « oui » local : elle verrouille l'app, elle ne remplace pas
/// les règles serveur (cours 6). La préférence est rangée dans Keystore / Keychain, jamais
/// dans shared_preferences (OWASP M9).
class VerrouRepository {
  VerrouRepository([LocalAuthentication? auth, FlutterSecureStorage? coffre])
    : _auth = auth ?? LocalAuthentication(),
      _coffre = coffre ?? const FlutterSecureStorage();

  static const _cle = 'verrouillage_biometrique';

  final LocalAuthentication _auth;
  final FlutterSecureStorage _coffre;

  /// Empreinte, visage ou, à défaut, code du téléphone.
  Future<bool> disponible() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> actif() async => await _coffre.read(key: _cle) == 'oui';

  Future<void> enregistrer({required bool actif}) =>
      actif ? _coffre.write(key: _cle, value: 'oui') : _coffre.delete(key: _cle);

  /// Renvoie true si l'utilisateur s'est authentifié.
  Future<bool> authentifier() async {
    try {
      return await _auth.authenticate(localizedReason: "Déverrouillez l'espace bureau de Parquet");
    } catch (_) {
      return false; // annulé, trop d'essais, biométrie retirée…
    }
  }
}
