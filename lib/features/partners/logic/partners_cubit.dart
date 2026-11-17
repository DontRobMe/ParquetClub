import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/partner.dart';
import '../data/partner_repository.dart';
import 'partners_state.dart';

/// ViewModel de l'annuaire : partagé par la liste et la fiche détail, d'où sa place au-dessus de l'app.
class PartnersCubit extends Cubit<PartnersState> {
  PartnersCubit(this._repository) : super(const PartnersLoading());

  final PartnerRepository _repository;
  StreamSubscription<AnnuaireSnapshot>? _abonnement;

  List<Partner> _tous = const [];
  bool _recu = false;
  bool _horsLigne = false;
  DateTime? _derniereSynchro;
  String _recherche = '';
  String? _secteur;

  /// Démarre (ou relance après une erreur) l'écoute de l'annuaire.
  void charger() {
    emit(const PartnersLoading());
    _abonnement?.cancel();
    _abonnement = _repository.ecouterPartenaires().listen(
      (snap) {
        _tous = snap.partenaires;
        _horsLigne = snap.horsLigne;
        if (!snap.horsLigne) _derniereSynchro = DateTime.now();
        _recu = true;
        _emettre();
      },
      onError: (Object _) => emit(const PartnersError("Impossible de charger l'annuaire.")),
    );
  }

  void rechercher(String texte) {
    _recherche = texte;
    _emettre();
  }

  void filtrerSecteur(String? secteur) {
    _secteur = secteur;
    _emettre();
  }

  /// Utilisé par la fiche détail : l'identifiant voyage avec la navigation.
  Partner? partenaire(String id) {
    for (final p in _tous) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _emettre() {
    if (!_recu) return;
    if (_tous.isEmpty) {
      emit(PartnersEmpty(horsLigne: _horsLigne, derniereSynchro: _derniereSynchro));
      return;
    }
    final mots = _normaliser(_recherche).split(' ').where((m) => m.isNotEmpty);
    final visibles = _tous.where((p) {
      if (_secteur != null && p.secteur != _secteur) return false;
      final texte = _normaliser('${p.nom} ${p.metier} ${p.ville}');
      return mots.every(texte.contains);
    }).toList();
    emit(PartnersSuccess(
      partenaires: visibles,
      recherche: _recherche,
      secteur: _secteur,
      horsLigne: _horsLigne,
      derniereSynchro: _derniereSynchro,
    ));
  }

  @override
  Future<void> close() {
    _abonnement?.cancel();
    return super.close();
  }
}

/// Minuscules et sans accents : « electricien » trouve « Électricien ».
String _normaliser(String s) {
  const avec = 'àâäáãéèêëíìîïóòôöõúùûüçñœ';
  const sans = 'aaaaaeeeeiiiiooooouuuucno';
  final buffer = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = avec.indexOf(c);
    buffer.write(i < 0 ? c : sans[i]);
  }
  return buffer.toString().trim();
}
