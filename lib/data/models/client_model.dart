/// Modèle représentant un client
class ClientModel {
  final String id;
  final String nom;
  final String adresse;
  final String? telephone;
  final double solde; // solde/crédit du client (positif = doit de l'argent)
  final DateTime dateCreation;
  final bool isSynced;

  ClientModel({
    required this.id,
    required this.nom,
    required this.adresse,
    this.telephone,
    this.solde = 0,
    required this.dateCreation,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'telephone': telephone,
      'solde': solde,
      'date_creation': dateCreation.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'],
      nom: map['nom'],
      adresse: map['adresse'],
      telephone: map['telephone'],
      solde: map['solde'] ?? 0,
      dateCreation: DateTime.parse(map['date_creation']),
      isSynced: map['is_synced'] == 1,
    );
  }
}