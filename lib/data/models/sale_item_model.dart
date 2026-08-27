/// Modèle représentant une ligne de facture (un produit vendu)
class SaleItemModel {
  final String id;
  final String saleId;
  final String productId;
  final String designation; // nom du produit au moment de la vente
  final int quantite;
  final double prixUnitaire;

  SaleItemModel({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
  });

  double get prixTotal => quantite * prixUnitaire;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'designation': designation,
      'quantite': quantite,
      'prix_unitaire': prixUnitaire,
    };
  }

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      designation: map['designation'],
      quantite: map['quantite'],
      prixUnitaire: map['prix_unitaire'],
    );
  }
}