import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/partner.dart';
import '../data/partner_repository.dart';

/// États de l'écran « Ma fiche ».
sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
}

class ProfileSuccess extends ProfileState {
  const ProfileSuccess({required this.fiche, this.telephonePerso = ''});
  final Partner fiche;
  final String telephonePerso; // visible seulement par le partenaire et le bureau
}

/// ViewModel de la fiche du partenaire connecté (F6, F7).
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository, this.uid) : super(const ProfileLoading());

  final PartnerRepository _repository;
  final String uid;
  StreamSubscription<Partner?>? _fiche;
  StreamSubscription<String>? _telephone;
  String _telephonePerso = '';

  void charger() {
    emit(const ProfileLoading());
    _fiche?.cancel();
    _telephone?.cancel();
    _fiche = _repository
        .ecouterFiche(uid)
        .listen(
          (fiche) => emit(
            fiche == null
                ? const ProfileError('Fiche introuvable. Contactez le bureau du club.')
                : ProfileSuccess(fiche: fiche, telephonePerso: _telephonePerso),
          ),
          onError: (Object _) => emit(const ProfileError('Impossible de charger votre fiche.')),
        );
    _telephone = _repository.ecouterTelephonePerso(uid).listen((tel) {
      _telephonePerso = tel;
      final s = state;
      if (s is ProfileSuccess) emit(ProfileSuccess(fiche: s.fiche, telephonePerso: tel));
    }, onError: (Object _) {});
  }

  /// Vérifie puis enregistre. Renvoie le message d'erreur à afficher, ou null.
  /// Pas d'attente du serveur : hors ligne, la fiche est enregistrée au retour du réseau.
  /// [surRefus] est appelé si le serveur refuse finalement l'écriture.
  String? enregistrer(Partner fiche, {required String telephonePerso, void Function()? surRefus}) {
    final erreur = verifierFiche(fiche, telephonePerso);
    if (erreur != null) return erreur;
    final propre = Partner(
      id: uid, // on ne modifie que sa propre fiche
      nom: fiche.nom.trim(),
      metier: fiche.metier.trim(),
      secteur: fiche.secteur,
      description: fiche.description.trim(),
      adresse: fiche.adresse.trim(),
      ville: fiche.ville.trim(),
      telephone: fiche.telephone.trim(),
      email: fiche.email.trim(),
      site: fiche.site.trim(),
      logoUrl: fiche.logoUrl,
    );
    _repository.mettreAJourFiche(propre).catchError((Object _) => surRefus?.call());
    _repository.enregistrerTelephonePerso(uid, telephonePerso.trim()).catchError((Object _) => surRefus?.call());
    return null;
  }

  /// Renvoie le message d'erreur à afficher, ou null (succès ou annulation).
  Future<String?> changerLogo() async {
    try {
      await _repository.choisirEtEnvoyerLogo(uid);
      return null;
    } on PartnerErreur catch (e) {
      return e.message;
    }
  }

  @override
  Future<void> close() {
    _fiche?.cancel();
    _telephone?.cancel();
    return super.close();
  }
}

final _telephoneValide = RegExp(r'^\+?[0-9 .\-]{6,20}$');

/// OWASP M4 : longueurs limitées et liens vérifiés, avant l'envoi. Les règles Firestore refont les mêmes contrôles.
String? verifierFiche(Partner p, String telephonePerso) {
  String? trop(String valeur, int max, String champ) =>
      valeur.trim().length > max ? '$champ : $max caractères maximum.' : null;

  if (p.nom.trim().isEmpty) return "Le nom de l'entreprise est obligatoire.";
  final longueur =
      trop(p.nom, 80, 'Nom') ??
      trop(p.metier, 60, 'Activité') ??
      trop(p.description, 1000, 'Description') ??
      trop(p.adresse, 120, 'Adresse') ??
      trop(p.ville, 60, 'Ville') ??
      trop(p.email, 254, 'E-mail') ??
      trop(p.site, 200, 'Site web');
  if (longueur != null) return longueur;
  for (final (tel, champ) in [(p.telephone, 'Téléphone professionnel'), (telephonePerso, 'Téléphone personnel')]) {
    if (tel.trim().isNotEmpty && !_telephoneValide.hasMatch(tel.trim())) return '$champ : numéro invalide.';
  }
  final email = p.email.trim();
  if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'E-mail invalide.';
  final site = p.site.trim();
  if (site.isNotEmpty) {
    final uri = Uri.tryParse(site);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'Site web : adresse complète en https:// (exemple : https://mon-entreprise.fr).';
    }
  }
  return null;
}
