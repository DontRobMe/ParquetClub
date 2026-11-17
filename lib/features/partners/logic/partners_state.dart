import '../data/partner.dart';

/// Les 4 états de l'écran annuaire (cours 1 et 4). Le switch de la vue doit tous les couvrir.
sealed class PartnersState {
  const PartnersState();
}

class PartnersLoading extends PartnersState {
  const PartnersLoading();
}

class PartnersError extends PartnersState {
  const PartnersError(this.message);
  final String message;
}

class PartnersEmpty extends PartnersState {
  const PartnersEmpty({this.horsLigne = false, this.derniereSynchro});
  final bool horsLigne;
  final DateTime? derniereSynchro;
}

class PartnersSuccess extends PartnersState {
  const PartnersSuccess({
    required this.partenaires,
    this.recherche = '',
    this.secteur,
    this.horsLigne = false,
    this.derniereSynchro,
  });

  /// Partenaires visibles après recherche et filtre (peut être vide : « Aucun résultat »).
  final List<Partner> partenaires;
  final String recherche;
  final String? secteur; // null = « Tous »
  final bool horsLigne;
  final DateTime? derniereSynchro;
}
