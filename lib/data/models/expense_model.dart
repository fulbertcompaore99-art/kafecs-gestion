
class ExpenseModel {
  final String id;
  final String libelle;
  final double montant;
  final String userId;
  final String userNom; // dénormalisé pour affichage
  final DateTime dateDepense;
  final bool isSynced;

  ExpenseModel({
    required this.id,
    required this.libelle,
    required this.montant,
    required this.userId,
    required this.userNom,
    required this.dateDepense,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libelle': libelle,
      'montant': montant,
      'user_id': userId,
      'user_nom': userNom,
      'date_depense': dateDepense.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      libelle: map['libelle'],
      montant: map['montant'],
      userId: map['user_id'],
      userNom: map['user_nom'],
      dateDepense: DateTime.parse(map['date_depense']),
      isSynced: map['is_synced'] == 1,
    );
  }
}