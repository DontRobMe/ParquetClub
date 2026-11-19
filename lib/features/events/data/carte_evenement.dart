import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Aperçu IGN centré sur une adresse postale reconnue dans la Base Adresse Nationale.
class CarteEvenement {
  const CarteEvenement._(this.latitude, this.longitude, this.image);

  final double latitude;
  final double longitude;
  final Uint8List image;

  static final _adresse = RegExp(
    r'(?:^|[,·\n])\s*(?<adresse>(?<numero>\d{1,4})(?:\s*(?<suffixe>bis|ter|quater|[a-z](?=\s)))?\b.*)',
    caseSensitive: false,
    dotAll: true,
  );
  static final _codePostal = RegExp(r'\b\d{5}\b');

  static Future<CarteEvenement?> charger(String lieu) async {
    final saisie = _adresse.firstMatch(lieu);
    if (saisie == null) return null;
    final adresse = saisie.namedGroup('adresse')!.trim();
    final numeroSaisi = '${saisie.namedGroup('numero')}${saisie.namedGroup('suffixe') ?? ''}'.toLowerCase();
    final codePostal = _codePostal.firstMatch(adresse)?.group(0);
    final client = HttpClient();
    try {
      return await _chercher(client, adresse, numeroSaisi, codePostal).timeout(const Duration(seconds: 6));
    } on Exception {
      // L'adresse saisie reste affichée quand le géocodage ou le fond de carte est indisponible.
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<CarteEvenement?> _chercher(
    HttpClient client,
    String adresse,
    String numeroSaisi,
    String? codePostal,
  ) async {
    final url = Uri.https('data.geopf.fr', '/geocodage/search', {'q': adresse, 'index': 'address', 'limit': '1'});
    final resultat = jsonDecode(utf8.decode(await _lire(client, url)));
    if (resultat
        case {
          'features': [
            {
              'properties': {
                'type': 'housenumber',
                'score': num score,
                'housenumber': String numero,
                'postcode': String cp,
              },
              'geometry': {'coordinates': [num lon, num lat]},
            },
          ],
        }
        when score >= 0.75 &&
            numero.toLowerCase().replaceAll(' ', '') == numeroSaisi &&
            (codePostal == null || cp == codePostal)) {
      final image = await _lire(client, _urlFond(lat.toDouble(), lon.toDouble()));
      return CarteEvenement._(lat.toDouble(), lon.toDouble(), image);
    }
    return null;
  }

  static Uri _urlFond(double lat, double lon) {
    const largeur = 720;
    const hauteur = 352;
    const demiLatitude = 0.002;
    final demiLongitude = demiLatitude * largeur / hauteur / cos(lat * pi / 180);
    return Uri.https('data.geopf.fr', '/wms-r/wms', {
      'SERVICE': 'WMS',
      'VERSION': '1.3.0',
      'REQUEST': 'GetMap',
      'LAYERS': 'GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2',
      'STYLES': 'normal',
      'CRS': 'CRS:84',
      'BBOX': [
        lon - demiLongitude,
        lat - demiLatitude,
        lon + demiLongitude,
        lat + demiLatitude,
      ].map((coord) => coord.toStringAsFixed(6)).join(','),
      'WIDTH': '$largeur',
      'HEIGHT': '$hauteur',
      'FORMAT': 'image/png',
    });
  }

  static Future<Uint8List> _lire(HttpClient client, Uri url) async {
    final requete = await client.getUrl(url);
    final reponse = await requete.close();
    if (reponse.statusCode != HttpStatus.ok) {
      throw HttpException('Service IGN indisponible', uri: url);
    }
    final donnees = await reponse.fold(BytesBuilder(copy: false), (tampon, fragment) => tampon..add(fragment));
    return donnees.takeBytes();
  }
}
