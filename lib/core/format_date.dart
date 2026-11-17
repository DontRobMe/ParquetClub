/// Dates en français sans dépendance supplémentaire (le paquet intl n'est pas dans la liste du cahier des charges).
const _jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _mois = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];
const _moisCourts = ['JANV', 'FÉVR', 'MARS', 'AVR', 'MAI', 'JUIN', 'JUIL', 'AOÛT', 'SEPT', 'OCT', 'NOV', 'DÉC'];

/// « vendredi 4 décembre »
String dateLongue(DateTime d) => '${_jours[d.weekday - 1]} ${d.day == 1 ? '1er' : d.day} ${_mois[d.month - 1]}';

/// « 19 h 30 »
String heure(DateTime d) => '${d.hour} h ${d.minute.toString().padLeft(2, '0')}';

/// « DÉC »
String moisCourt(DateTime d) => _moisCourts[d.month - 1];
