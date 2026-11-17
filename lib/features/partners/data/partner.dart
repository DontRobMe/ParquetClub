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
    this.logoUrl = '',
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
  final String logoUrl;

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
      logoUrl: texte('logoUrl'),
    );
  }
}
