import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Secteurs proposés par les filtres de l'annuaire (maquette et fiches store).
const secteurs = ['Artisanat', 'Services', 'Restauration', 'Autre'];

/// Fiche publique d'un partenaire : `partners/{uid}`.
/// Le téléphone personnel n'est pas ici : il vit dans `partners/{uid}/private/contact` (F7).
class Partner {
  const Partner({
    required this.id,
    required this.nom,
    this.metier = '',
    this.secteur = 'Autre',
    this.description = '',
    this.adresse = '',
    this.ville = '',
    this.telephone = '',
    this.email = '',
    this.site = '',
    this.logo,
  });

  final String id; // = uid du compte du partenaire
  final String nom;
  final String metier;
  final String secteur;
  final String description;
  final String adresse;
  final String ville;
  final String telephone;
  final String email;
  final String site;

  /// Logo de l'entreprise (JPEG de 256 px au plus), rangé dans la fiche elle-même :
  /// forfait Spark, donc pas de Storage. Bonus : il s'affiche aussi hors ligne.
  final Uint8List? logo;

  factory Partner.fromMap(String id, Map<String, dynamic> data) {
    String texte(String cle) => data[cle] is String ? data[cle] as String : '';
    return Partner(
      id: id,
      nom: texte('nom'),
      metier: texte('metier'),
      secteur: secteurs.contains(data['secteur']) ? data['secteur'] as String : 'Autre',
      description: texte('description'),
      adresse: texte('adresse'),
      ville: texte('ville'),
      telephone: texte('telephone'),
      email: texte('email'),
      site: texte('site'),
      logo: data['logo'] is Blob ? (data['logo'] as Blob).bytes : null,
    );
  }
}
