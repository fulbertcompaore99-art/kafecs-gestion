/// Modèle représentant un produit du stock
class ProductModel {
  final String id;
  final String nom;
  final String? categorieId;
  final double prixAchat;
  final double prixVente;
  final int quantiteStock;
  final String unite; // ex: pièce, sac, mètre, kg...
  final String? reference; // code produit / code-barres
  final int seuilAlerte; // seuil de stock bas
  final DateTime dateCreation;
  final bool isSynced;

  ProductModel({
    required this.id,
    required this.nom,
    this.categorieId,
    required this.prixAchat,
    required this.prixVente,
    required this.quantiteStock,
    required this.unite,
    this.reference,
    this.seuilAlerte = 5,
    required this.dateCreation,
    this.isSynced = false,
  });

  bool get stockBas => quantiteStock <= seuilAlerte;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'categorie_id': categorieId,
      'prix_achat': prixAchat,
      'prix_vente': prixVente,
      'quantite_stock': quantiteStock,
      'unite': unite,
      'reference': reference,
      'seuil_alerte': seuilAlerte,
      'date_creation': dateCreation.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      nom: map['nom'],
      categorieId: map['categorie_id'],
      prixAchat: map['prix_achat'],
      prixVente: map['prix_vente'],
      quantiteStock: map['quantite_stock'],
      unite: map['unite'],
      reference: map['reference'],
      seuilAlerte: map['seuil_alerte'] ?? 5,
      dateCreation: DateTime.parse(map['date_creation']),
      isSynced: map['is_synced'] == 1,
    );
  }
}