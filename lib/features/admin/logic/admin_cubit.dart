import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/admin_repository.dart';
import 'admin_state.dart';

/// ViewModel du bureau : comptes partenaires et actions sur ces comptes.
class AdminCubit extends Cubit<AdminState> {
  AdminCubit(this._repository) : super(const AdminLoading());

  final AdminRepository _repository;
  StreamSubscription<List<Compte>>? _abonnement;

  void charger() {
    // RGPD : réponses effacées 12 mois après l'événement. Sans serveur, le bureau s'en charge à l'ouverture.
    _repository.purgerReponsesAnciennes().catchError((Object _) {});
    emit(const AdminLoading());
    _abonnement?.cancel();
    _abonnement = _repository.ecouterComptes().listen(
      (comptes) => emit(comptes.isEmpty ? const AdminEmpty() : AdminSuccess(comptes)),
      onError: (Object _) => emit(const AdminError('Impossible de charger les comptes.')),
    );
  }

  Compte? compte(String uid) {
    final s = state;
    if (s is! AdminSuccess) return null;
    for (final c in s.comptes) {
      if (c.uid == uid) return c;
    }
    return null;
  }

  /// F7. Vide si le partenaire n'en a pas donné ou si la lecture échoue.
  Future<String> telephonePerso(String uid) => _repository.telephonePerso(uid).catchError((Object _) => '');

  /// Chaque action renvoie le message d'erreur à afficher, ou null si elle a réussi.
  Future<String?> inviter({required String nom, required String email}) {
    if (nom.trim().isEmpty || !email.contains('@')) {
      return Future.value("Saisissez le nom de l'entreprise et un e-mail valide.");
    }
    return _essayer(() => _repository.creerPartenaire(nom: nom.trim(), email: email.trim()));
  }

  Future<String?> changerAcces(String uid, {required bool actif, required String nom}) =>
      _essayer(() => _repository.changerAcces(uid, actif: actif, nom: nom));

  Future<String?> supprimer(String uid, {required String nom}) =>
      _essayer(() => _repository.supprimerPartenaire(uid, nom: nom));

  Future<String?> envoyerLien(String email) => _essayer(() => _repository.envoyerLienMotDePasse(email));

  Future<String?> _essayer(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AdminErreur catch (e) {
      return e.message;
    }
  }

  @override
  Future<void> close() {
    _abonnement?.cancel();
    return super.close();
  }
}

/// Réponses à un événement (F13). Créé par l'écran de suivi, fermé en le quittant.
class ReponsesCubit extends Cubit<ReponsesState> {
  ReponsesCubit(this._repository, this.eventId) : super(const ReponsesLoading());

  final AdminRepository _repository;
  final String eventId;
  StreamSubscription<List<ReponseBureau>>? _abonnement;

  void charger() {
    emit(const ReponsesLoading());
    _abonnement?.cancel();
    _abonnement = _repository
        .ecouterReponses(eventId)
        .listen(
          (reponses) => emit(reponses.isEmpty ? const ReponsesEmpty() : ReponsesSuccess(reponses)),
          onError: (Object _) => emit(const ReponsesError('Impossible de charger les réponses.')),
        );
  }

  @override
  Future<void> close() {
    _abonnement?.cancel();
    return super.close();
  }
}

/// Journal des actions du bureau (F18). Créé par l'écran du journal, fermé en le quittant.
class JournalCubit extends Cubit<JournalState> {
  JournalCubit(this._repository) : super(const JournalLoading());

  final AdminRepository _repository;
  StreamSubscription<List<EntreeJournal>>? _abonnement;

  void charger() {
    emit(const JournalLoading());
    _abonnement?.cancel();
    _abonnement = _repository.ecouterJournal().listen(
      (entrees) => emit(entrees.isEmpty ? const JournalEmpty() : JournalSuccess(entrees)),
      onError: (Object _) => emit(const JournalError('Impossible de charger le journal.')),
    );
  }

  @override
  Future<void> close() {
    _abonnement?.cancel();
    return super.close();
  }
}
