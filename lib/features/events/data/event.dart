import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'un événement ; le `switch` sur cet enum doit couvrir tous les cas (cours 2).
enum EventStatut { prevu, modifie, annule }

const tailleMaxPhotoEvenement = 450000;
const dureeSuiviEvenement = Duration(days: 365);

/// Événement du club : `events/{id}`. Écrit par le bureau, lu par les comptes connectés.
class Event {
  const Event({
    required this.id,
    required this.titre,
    required this.date,
    this.type = '',
    this.lieu = '',
    this.description = '',
    this.statut = EventStatut.prevu,
    this.photo,
  });

  final String id;
  final String titre;
  final String type; // Match en loge, Afterwork, Soirée partenaires…
  final DateTime date;
  final String lieu;
  final String description;
  final EventStatut statut;
  final Uint8List? photo;

  bool get annule => statut == EventStatut.annule;
  bool estPasse(DateTime maintenant) => !date.isAfter(maintenant);

  DateTime get jour {
    final locale = date.toLocal();
    return DateTime(locale.year, locale.month, locale.day);
  }

  bool suiviDisponible(DateTime maintenant) => maintenant.isBefore(date.add(dureeSuiviEvenement));
  bool emargementOuvert(DateTime maintenant) => !annule && !maintenant.isBefore(jour) && suiviDisponible(maintenant);

  Map<String, Object> toMap() => {
    'titre': titre,
    'type': type,
    'date': Timestamp.fromDate(date),
    'lieu': lieu,
    'description': description,
    'statut': statut.name,
    if (photo != null) 'photo': Blob(photo!),
  };

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    String texte(String cle) => data[cle] is String ? data[cle] as String : '';
    final date = data['date'];
    return Event(
      id: id,
      titre: texte('titre'),
      type: texte('type'),
      date: date is Timestamp ? date.toDate() : DateTime.fromMillisecondsSinceEpoch(0),
      lieu: texte('lieu'),
      description: texte('description'),
      statut: EventStatut.values.firstWhere((s) => s.name == data['statut'], orElse: () => EventStatut.prevu),
      photo: data['photo'] is Blob ? (data['photo'] as Blob).bytes : null,
    );
  }
}

/// Réponse du partenaire connecté : `events/{id}/responses/{uid}`.
class EventResponse {
  const EventResponse({
    required this.vient,
    required this.nbPersonnes,
    this.enAttente = false,
    this.aRepondu = true,
    this.presence,
    this.avis,
  });

  final bool vient;
  final int nbPersonnes;
  final bool aRepondu;
  final bool? presence;
  final AvisEvenement? avis;

  /// Vrai tant que la réponse n'est que dans le cache local (réponse faite sans réseau).
  final bool enAttente;

  bool peutNoter(Event event, DateTime maintenant) =>
      presence == true && avis == null && event.emargementOuvert(maintenant);

  factory EventResponse.fromMap(Map<String, dynamic> data, {bool enAttente = false}) => EventResponse(
    vient: data['vient'] == true,
    nbPersonnes: data['nbPersonnes'] is int ? data['nbPersonnes'] as int : 0,
    enAttente: enAttente,
    aRepondu: data['vient'] is bool,
    presence: data['presence'] is bool ? data['presence'] as bool : null,
    avis: AvisEvenement.depuisReponse(data),
  );
}

class AvisEvenement {
  const AvisEvenement({required this.note, this.commentaire = ''});

  final int note;
  final String commentaire;

  Map<String, Object> toMap() => {'note': note, 'commentaire': commentaire};

  static AvisEvenement? depuisReponse(Map<String, dynamic>? data) {
    final note = data?['note'];
    final commentaire = data?['commentaire'];
    return switch (note) {
      int n when n >= 1 && n <= 5 => AvisEvenement(note: n, commentaire: commentaire is String ? commentaire : ''),
      _ => null,
    };
  }
}

class ErreurSuiviEvenement implements Exception {
  const ErreurSuiviEvenement(this.message);

  factory ErreurSuiviEvenement.depuisFirestore(String code) => ErreurSuiviEvenement(switch (code) {
    'permission-denied' => "Le serveur refuse cet enregistrement. Le bureau peut vérifier les droits Firebase.",
    'unauthenticated' => 'Reconnectez-vous pour enregistrer ce changement.',
    'unavailable' || 'deadline-exceeded' => 'La connexion au serveur a échoué. Réessayez une fois en ligne.',
    'aborted' => 'Cette fiche vient de changer. Réessayez.',
    _ => "L’enregistrement a échoué. Réessayez.",
  });

  final String message;
}
