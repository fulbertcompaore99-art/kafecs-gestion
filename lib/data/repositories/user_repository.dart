import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../core/services/database_service.dart';
import '../models/user_model.dart';

/// Gère toutes les opérations sur les utilisateurs dans la base locale
class UserRepository {
  final _uuid = const Uuid();

  /// Transforme un mot de passe en clair en hash sécurisé (SHA-256)
  String hasherMotDePasse(String motDePasse) {
    final bytes = utf8.encode(motDePasse);
    return sha256.convert(bytes).toString();
  }

  /// Crée le compte propriétaire par défaut au tout premier lancement
  Future<UserModel> creerProprietaireParDefaut({
    required String nomComplet,
    required String identifiant,
    required String motDePasse,
  }) async {
    final user = UserModel(
      id: _uuid.v4(),
      nomComplet: nomComplet,
      identifiant: identifiant,
      motDePasseHash: hasherMotDePasse(motDePasse),
      role: 'proprietaire',
      actif: true,
      dateCreation: DateTime.now(),
    );
    await creerUtilisateur(user);
    return user;
  }

  /// Insère un nouvel utilisateur dans la base
  Future<void> creerUtilisateur(UserModel user) async {
    final db = await DatabaseService.instance.database;
    await db.insert('users', user.toMap());
  }

  /// Recherche un utilisateur par son identifiant (login)
  Future<UserModel?> trouverParIdentifiant(String identifiant) async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query(
      'users',
      where: 'identifiant = ?',
      whereArgs: [identifiant],
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return UserModel.fromMap(resultats.first);
  }

  /// Recherche un utilisateur par son id
  Future<UserModel?> trouverParId(String id) async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return UserModel.fromMap(resultats.first);
  }

  /// Vérifie si la base contient déjà au moins un utilisateur
  Future<bool> existeAuMoinsUnUtilisateur() async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query('users', limit: 1);
    return resultats.isNotEmpty;
  }

  /// Retourne tous les utilisateurs (pour l'écran "Gestion des utilisateurs")
  Future<List<UserModel>> listerTousLesUtilisateurs() async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query('users', orderBy: 'date_creation DESC');
    return resultats.map((e) => UserModel.fromMap(e)).toList();
  }

  /// Le propriétaire crée un compte secrétaire
  Future<UserModel> creerSecretaire({
    required String nomComplet,
    required String identifiant,
    required String motDePasse,
  }) async {
    final user = UserModel(
      id: _uuid.v4(),
      nomComplet: nomComplet,
      identifiant: identifiant,
      motDePasseHash: hasherMotDePasse(motDePasse),
      role: 'secretaire',
      actif: true,
      dateCreation: DateTime.now(),
    );
    await creerUtilisateur(user);
    return user;
  }

  /// Met à jour les infos d'un utilisateur (nom, identifiant)
  Future<void> modifierUtilisateur(UserModel user) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Le propriétaire réinitialise/change le mot de passe d'un secrétaire
  /// ou l'utilisateur change son propre mot de passe
  Future<void> changerMotDePasse(String userId, String nouveauMotDePasse) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'users',
      {'mot_de_passe_hash': hasherMotDePasse(nouveauMotDePasse)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Active ou désactive un compte (sans le supprimer)
  Future<void> changerStatutActif(String userId, bool actif) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'users',
      {'actif': actif ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Supprime définitivement un compte utilisateur
  Future<void> supprimerUtilisateur(String userId) async {
    final db = await DatabaseService.instance.database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  /// Met à jour la date de dernière connexion
  Future<void> mettreAJourDerniereConnexion(String userId) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'users',
      {'derniere_connexion': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}