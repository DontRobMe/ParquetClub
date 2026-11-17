import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/verrou_repository.dart';

/// État du verrou du compte bureau : pas un écran réseau, donc pas les 4 états, juste trois valeurs.
class VerrouState {
  const VerrouState({this.disponible = false, this.actif = false, this.verrouille = false});

  final bool disponible; // le téléphone sait authentifier
  final bool actif; // préférence du bénévole
  final bool verrouille; // écran de verrou affiché
}

/// F17. Verrouille l'espace bureau à l'ouverture et à chaque retour au premier plan (cycle de vie, cours 1).
class VerrouCubit extends Cubit<VerrouState> {
  VerrouCubit(this._repository) : super(const VerrouState());

  final VerrouRepository _repository;
  bool _enCours = false;

  /// À l'ouverture du compte : verrouillé tout de suite si la préférence est active.
  Future<void> demarrer() async {
    final disponible = await _repository.disponible();
    final actif = disponible && await _repository.actif();
    emit(VerrouState(disponible: disponible, actif: actif, verrouille: actif));
  }

  /// L'app passe en arrière-plan : elle sera verrouillée au retour.
  void verrouiller() {
    if (state.actif && !state.verrouille) {
      emit(VerrouState(disponible: state.disponible, actif: true, verrouille: true));
    }
  }

  Future<void> deverrouiller() async {
    if (_enCours || !state.verrouille) return;
    _enCours = true;
    final ok = await _repository.authentifier();
    _enCours = false;
    if (ok) emit(VerrouState(disponible: state.disponible, actif: true));
  }

  /// Activer demande d'abord une authentification réussie : on ne s'enferme pas dehors.
  /// Renvoie le message à afficher, ou null.
  Future<String?> changerPreference({required bool actif}) async {
    if (actif && !state.disponible) return "Ce téléphone n'a ni empreinte, ni visage, ni code configuré.";
    if (actif && !await _repository.authentifier()) return 'Authentification annulée : verrouillage non activé.';
    await _repository.enregistrer(actif: actif);
    emit(VerrouState(disponible: state.disponible, actif: actif));
    return null;
  }
}
