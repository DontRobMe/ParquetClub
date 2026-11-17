import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'un événement ; le `switch` sur cet enum doit couvrir tous les cas (cours 2).
enum EventStatut { prevu, modifie, annule }

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
  });

  final String id;
  final String titre;
  final String type; // Match en loge, Afterwork, Soirée partenaires…
  final DateTime date;
  final String lieu;
  final String description;
  final EventStatut statut;

  bool get annule => statut == EventStatut.annule;

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
    );
  }
}

/// Réponse du partenaire connecté : `events/{id}/responses/{uid}`.
class EventResponse {
  const EventResponse({required this.vient, required this.nbPersonnes, this.enAttente = false});

  final bool vient;
  final int nbPersonnes;

  /// Vrai tant que la réponse n'est que dans le cache local (réponse faite sans réseau).
  final bool enAttente;

  factory EventResponse.fromMap(Map<String, dynamic> data, {bool enAttente = false}) => EventResponse(
    vient: data['vient'] == true,
    nbPersonnes: data['nbPersonnes'] is int ? data['nbPersonnes'] as int : 0,
    enAttente: enAttente,
  );
}
