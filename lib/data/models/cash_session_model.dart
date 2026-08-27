/// Modèle représentant une session de caisse (ouverture → clôture)
class CashSessionModel {
  final String id;
  final String userId;
  final String userNom; // dénormalisé pour affichage
  final double fondOuverture;
  final double? montantCloture;
  final DateTime dateOuverture;
  final DateTime? dateCloture;
  final String statut; // 'ouverte' ou 'cloturee'
  final bool isSynced;

  CashSessionModel({
    required this.id,
    required this.userId,
    required this.userNom,
    required this.fondOuverture,
    this.montantCloture,
    required this.dateOuverture,
    this.dateCloture,
    this.statut = 'ouverte',
    this.isSynced = false,
  });

  bool get estOuverte => statut == 'ouverte';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'fond_ouverture': fondOuverture,
      'montant_cloture': montantCloture,
      'date_ouverture': dateOuverture.toIso8601String(),
      'date_cloture': dateCloture?.toIso8601String(),
      'statut': statut,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory CashSessionModel.fromMap(Map<String, dynamic> map, {String userNom = ''}) {
    return CashSessionModel(
      id: map['id'],
      userId: map['user_id'],
      userNom: userNom,
      fondOuverture: map['fond_ouverture'],
      montantCloture: map['montant_cloture'],
      dateOuverture: DateTime.parse(map['date_ouverture']),
      dateCloture: map['date_cloture'] != null ? DateTime.parse(map['date_cloture']) : null,
      statut: map['statut'],
      isSynced: map['is_synced'] == 1,
    );
  }
}