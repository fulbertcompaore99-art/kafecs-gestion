import 'package:uuid/uuid.dart';

import '../../core/services/database_service.dart';
import '../models/product_model.dart';

/// Gère toutes les opérations sur les produits dans la base locale
class ProductRepository {
  final _uuid = const Uuid();

  /// Crée un nouveau produit
  Future<ProductModel> creerProduit({
    required String nom,
    String? categorieId,
    required double prixAchat,
    required double prixVente,
    required int quantiteStock,
    required String unite,
    String? reference,
    int seuilAlerte = 5,
  }) async {
    final produit = ProductModel(
      id: _uuid.v4(),
      nom: nom,
      categorieId: categorieId,
      prixAchat: prixAchat,
      prixVente: prixVente,
      quantiteStock: quantiteStock,
      unite: unite,
      reference: reference,
      seuilAlerte: seuilAlerte,
      dateCreation: DateTime.now(),
    );

    final db = await DatabaseService.instance.database;
    await db.insert('products', produit.toMap());
    return produit;
  }

  /// Liste tous les produits, triés par nom
  Future<List<ProductModel>> listerTousLesProduits() async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query('products', orderBy: 'nom ASC');
    return resultats.map((e) => ProductModel.fromMap(e)).toList();
  }

  /// Recherche des produits par nom (pour la vente)
  Future<List<ProductModel>> rechercherProduits(String recherche) async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query(
      'products',
      where: 'nom LIKE ?',
      whereArgs: ['%$recherche%'],
      orderBy: 'nom ASC',
    );
    return resultats.map((e) => ProductModel.fromMap(e)).toList();
  }

  /// Récupère un produit par son id
  Future<ProductModel?> trouverParId(String id) async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    if (resultats.isEmpty) return null;
    return ProductModel.fromMap(resultats.first);
  }

  /// Modifie un produit existant
  Future<void> modifierProduit(ProductModel produit) async {
    final db = await DatabaseService.instance.database;
    await db.update('products', produit.toMap(), where: 'id = ?', whereArgs: [produit.id]);
  }

  /// Supprime un produit
  Future<void> supprimerProduit(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Ajuste le stock (utilisé après une vente ou un ajustement manuel)
  /// [quantiteDelta] : négatif pour une sortie (vente), positif pour une entrée
  Future<void> ajusterStock(String produitId, int quantiteDelta) async {
    final db = await DatabaseService.instance.database;
    final produit = await trouverParId(produitId);
    if (produit == null) return;

    final nouvelleQuantite = produit.quantiteStock + quantiteDelta;
    await db.update(
      'products',
      {'quantite_stock': nouvelleQuantite < 0 ? 0 : nouvelleQuantite},
      where: 'id = ?',
      whereArgs: [produitId],
    );
  }

  /// Liste les produits en stock bas (pour les alertes)
  Future<List<ProductModel>> listerProduitsStockBas() async {
    final tousLesProduits = await listerTousLesProduits();
    return tousLesProduits.where((p) => p.stockBas).toList();
  }
}