/// Modèle représentant un utilisateur (Propriétaire ou Secrétaire)
class UserModel {
  final String id;
  final String nomComplet;
  final String identifiant;
  final String motDePasseHash;
  final String role; // 'proprietaire' ou 'secretaire'
  final bool actif;
  final DateTime dateCreation;
  final DateTime? derniereConnexion;
  final bool isSynced;

  UserModel({
    required this.id,
    required this.nomComplet,
    required this.identifiant,
    required this.motDePasseHash,
    required this.role,
    this.actif = true,
    required this.dateCreation,
    this.derniereConnexion,
    this.isSynced = false,
  });

  bool get estProprietaire => role == 'proprietaire';
  bool get estSecretaire => role == 'secretaire';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom_complet': nomComplet,
      'identifiant': identifiant,
      'mot_de_passe_hash': motDePasseHash,
      'role': role,
      'actif': actif ? 1 : 0,
      'date_creation': dateCreation.toIso8601String(),
      'derniere_connexion': derniereConnexion?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      nomComplet: map['nom_complet'],
      identifiant: map['identifiant'],
      motDePasseHash: map['mot_de_passe_hash'],
      role: map['role'],
      actif: map['actif'] == 1,
      dateCreation: DateTime.parse(map['date_creation']),
      derniereConnexion: map['derniere_connexion'] != null
          ? DateTime.parse(map['derniere_connexion'])
          : null,
      isSynced: map['is_synced'] == 1,
    );
  }
}