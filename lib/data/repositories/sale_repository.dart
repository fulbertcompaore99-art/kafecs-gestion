import 'package:uuid/uuid.dart';

import '../../core/services/database_service.dart';
import '../models/sale_model.dart';
import '../models/sale_item_model.dart';
import 'product_repository.dart';

class SaleRepository {
  final _uuid = const Uuid();
  final _productRepository = ProductRepository();

  Future<String> genererNumeroFacture() async {
    final db = await DatabaseService.instance.database;
    final anneeActuelle = DateTime.now().year;
    final prefixe = '$anneeActuelle-';

    final resultats = await db.query(
      'sales',
      where: 'numero_facture LIKE ?',
      whereArgs: ['$prefixe%'],
    );

    int dernierNumero = 0;
    for (final ligne in resultats) {
      final numeroFacture = ligne['numero_facture'] as String;
      final suffixe = numeroFacture.replaceFirst(prefixe, '');
      final valeur = int.tryParse(suffixe);
      if (valeur != null && valeur > dernierNumero) {
        dernierNumero = valeur;
      }
    }

    final prochainNumero = dernierNumero + 1;
    final numeroFormate = prochainNumero.toString().padLeft(3, '0');
    return '$prefixe$numeroFormate';
  }

  /// Enregistre une nouvelle vente complète : facture + lignes + déduction du stock
  /// [montantPaye] : montant réellement versé par le client à l'instant de la vente.
  /// S'il est inférieur au total, la différence devient une dette client.
  Future<SaleModel> creerVente({
    required String clientId,
    required String clientNom,
    required String clientAdresse,
    required String vendeurId,
    required String vendeurNom,
    required List<SaleItemModel> articles,
    required double montantPaye,
  }) async {
    final db = await DatabaseService.instance.database;
    final numeroFacture = await genererNumeroFacture();
    final saleId = _uuid.v4();
    final total = articles.fold<double>(0, (somme, item) => somme + item.prixTotal);

    final vente = SaleModel(
      id: saleId,
      numeroFacture: numeroFacture,
      clientId: clientId,
      clientNom: clientNom,
      clientAdresse: clientAdresse,
      vendeurId: vendeurId,
      vendeurNom: vendeurNom,
      articles: articles,
      total: total,
      montantPaye: montantPaye,
      dateVente: DateTime.now(),
    );

    await db.insert('sales', vente.toMap());

    for (final item in articles) {
      final itemAvecSaleId = SaleItemModel(
        id: item.id,
        saleId: saleId,
        productId: item.productId,
        designation: item.designation,
        quantite: item.quantite,
        prixUnitaire: item.prixUnitaire,
      );
      await db.insert('sale_items', itemAvecSaleId.toMap());
      await _productRepository.ajusterStock(item.productId, -item.quantite);
    }

    return vente;
  }

  /// Enregistre un remboursement partiel ou total sur une facture existante
  Future<void> enregistrerPaiement(String saleId, double montantSupplementaire) async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query('sales', where: 'id = ?', whereArgs: [saleId], limit: 1);
    if (resultats.isEmpty) return;

    final montantActuel = resultats.first['montant_paye'] as double;
    final total = resultats.first['total'] as double;
    var nouveauMontant = montantActuel + montantSupplementaire;
    if (nouveauMontant > total) nouveauMontant = total;

    await db.update(
      'sales',
      {'montant_paye': nouveauMontant, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  Future<List<SaleModel>> listerToutesLesVentes() async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query('sales', orderBy: 'date_vente DESC');
    return _chargerVentesAvecArticles(resultats);
  }

  Future<List<SaleModel>> listerVentesParVendeur(String vendeurId) async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query(
      'sales',
      where: 'vendeur_id = ?',
      whereArgs: [vendeurId],
      orderBy: 'date_vente DESC',
    );
    return _chargerVentesAvecArticles(resultats);
  }

  Future<List<SaleModel>> listerVentesEntreDates(DateTime debut, DateTime fin) async {
    final toutes = await listerToutesLesVentes();
    return toutes.where((v) =>
      v.dateVente.isAfter(debut.subtract(const Duration(seconds: 1))) &&
      v.dateVente.isBefore(fin.add(const Duration(seconds: 1)))
    ).toList();
  }

  /// Liste toutes les factures qui ne sont pas encore intégralement payées
  Future<List<SaleModel>> listerVentesACredit() async {
    final toutes = await listerToutesLesVentes();
    return toutes.where((v) => v.estACredit).toList();
  }

  Future<void> supprimerVente(String saleId) async {
    final db = await DatabaseService.instance.database;
    await db.delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
    await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
  }

  Future<List<SaleModel>> _chargerVentesAvecArticles(
    List<Map<String, dynamic>> resultatsVentes,
  ) async {
    final db = await DatabaseService.instance.database;
    final ventes = <SaleModel>[];

    for (final map in resultatsVentes) {
      final itemsResultats = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [map['id']],
      );
      final articles = itemsResultats.map((e) => SaleItemModel.fromMap(e)).toList();
      ventes.add(SaleModel.fromMap(map, articles));
    }

    return ventes;
  }
}