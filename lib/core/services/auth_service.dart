import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

/// Service de gestion de l'authentification et de la session utilisateur
class AuthService extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  UserModel? _utilisateurConnecte;

  UserModel? get utilisateurConnecte => _utilisateurConnecte;
  bool get estConnecte => _utilisateurConnecte != null;
  bool get estProprietaire => _utilisateurConnecte?.estProprietaire ?? false;
  bool get estSecretaire => _utilisateurConnecte?.estSecretaire ?? false;

  String? erreurConnexion;

  /// Tente de connecter un utilisateur avec identifiant + mot de passe
  Future<bool> connexion(String identifiant, String motDePasse) async {
    erreurConnexion = null;

    final user = await _userRepository.trouverParIdentifiant(identifiant);

    if (user == null) {
      erreurConnexion = "Identifiant introuvable";
      notifyListeners();
      return false;
    }

    if (!user.actif) {
      erreurConnexion = "Ce compte a été désactivé";
      notifyListeners();
      return false;
    }

    final motDePasseHashe = _userRepository.hasherMotDePasse(motDePasse);
    if (motDePasseHashe != user.motDePasseHash) {
      erreurConnexion = "Mot de passe incorrect";
      notifyListeners();
      return false;
    }

    await _userRepository.mettreAJourDerniereConnexion(user.id);
    _utilisateurConnecte = user;
    notifyListeners();
    return true;
  }

  /// Recharge les informations de l'utilisateur connecté depuis la base
  /// (utile après une modification de profil, pour refléter les changements)
  Future<void> rafraichirUtilisateurConnecte() async {
    if (_utilisateurConnecte == null) return;
    final utilisateurAJour = await _userRepository.trouverParId(_utilisateurConnecte!.id);
    if (utilisateurAJour != null) {
      _utilisateurConnecte = utilisateurAJour;
      notifyListeners();
    }
  }

  void deconnexion() {
    _utilisateurConnecte = null;
    notifyListeners();
  }
}