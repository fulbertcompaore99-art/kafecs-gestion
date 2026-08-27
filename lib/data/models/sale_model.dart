import 'sale_item_model.dart';

/// Modèle représentant une vente / facture
class SaleModel {
  final String id;
  final String numeroFacture; // format AAAA-NNN, ex: 2026-001
  final String clientId;
  final String clientNom; // dénormalisé pour affichage rapide sur la facture
  final String clientAdresse;
  final String vendeurId; // utilisateur connecté qui a fait la vente
  final String vendeurNom;
  final List<SaleItemModel> articles;
  final double total;
  final double montantPaye;
  final DateTime dateVente;
  final bool isSynced;

  SaleModel({
    required this.id,
    required this.numeroFacture,
    required this.clientId,
    required this.clientNom,
    required this.clientAdresse,
    required this.vendeurId,
    required this.vendeurNom,
    required this.articles,
    required this.total,
    required this.montantPaye,
    required this.dateVente,
    this.isSynced = false,
  });

  /// Montant restant dû sur cette facture
  double get montantRestant => total - montantPaye;

  /// Vrai si la facture n'est pas encore intégralement payée
  bool get estACredit => montantRestant > 0.01;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero_facture': numeroFacture,
      'client_id': clientId,
      'client_nom': clientNom,
      'client_adresse': clientAdresse,
      'vendeur_id': vendeurId,
      'vendeur_nom': vendeurNom,
      'total': total,
      'montant_paye': montantPaye,
      'date_vente': dateVente.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map, List<SaleItemModel> articles) {
    return SaleModel(
      id: map['id'],
      numeroFacture: map['numero_facture'],
      clientId: map['client_id'],
      clientNom: map['client_nom'],
      clientAdresse: map['client_adresse'],
      vendeurId: map['vendeur_id'],
      vendeurNom: map['vendeur_nom'],
      articles: articles,
      total: map['total'],
      montantPaye: (map['montant_paye'] ?? map['total']) * 1.0,
      dateVente: DateTime.parse(map['date_vente']),
      isSynced: map['is_synced'] == 1,
    );
  }
}