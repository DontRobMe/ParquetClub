import '../data/admin_repository.dart';

/// Les 4 états du tableau de bord du bureau.
sealed class AdminState {
  const AdminState();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

class AdminError extends AdminState {
  const AdminError(this.message);
  final String message;
}

class AdminEmpty extends AdminState {
  const AdminEmpty();
}

class AdminSuccess extends AdminState {
  const AdminSuccess(this.comptes);
  final List<Compte> comptes;

  int get actifs => comptes.where((c) => c.actif).length;
}

/// Les 4 états de la liste des réponses à un événement.
sealed class ReponsesState {
  const ReponsesState();
}

class ReponsesLoading extends ReponsesState {
  const ReponsesLoading();
}

class ReponsesError extends ReponsesState {
  const ReponsesError(this.message);
  final String message;
}

class ReponsesEmpty extends ReponsesState {
  const ReponsesEmpty();
}

class ReponsesSuccess extends ReponsesState {
  const ReponsesSuccess(this.reponses);
  final List<ReponseBureau> reponses;

  /// Total des participants, pour le traiteur.
  int get total => reponses.where((r) => r.vient).fold(0, (somme, r) => somme + r.nbPersonnes);
}
