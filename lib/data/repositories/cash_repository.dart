import 'package:uuid/uuid.dart';

import '../../core/services/database_service.dart';
import '../models/cash_session_model.dart';
import '../models/sale_model.dart';
import 'sale_repository.dart';

class CashRepository {
  final _uuid = const Uuid();
  final _saleRepository = SaleRepository();

  /// Ouvre une nouvelle session de caisse pour un utilisateur
  Future<CashSessionModel> ouvrirSession({
    required String userId,
    required String userNom,
    required double fondOuverture,
  }) async {
    final session = CashSessionModel(
      id: _uuid.v4(),
      userId: userId,
      userNom: userNom,
      fondOuverture: fondOuverture,
      dateOuverture: DateTime.now(),
      statut: 'ouverte',
    );

    final db = await DatabaseService.instance.database;
    await db.insert('cash_sessions', session.toMap());
    return session;
  }

  /// Récupère la session de caisse actuellement ouverte pour un utilisateur (s'il y en a une)
  Future<CashSessionModel?> trouverSessionOuverte(String userId) async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query(
      'cash_sessions',
      where: 'user_id = ? AND statut = ?',
      whereArgs: [userId, 'ouverte'],
      orderBy: 'date_ouverture DESC',
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return CashSessionModel.fromMap(resultats.first);
  }

  /// Clôture une session de caisse avec le montant compté par l'utilisateur
  Future<void> cloturerSession(String sessionId, double montantCompte) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'cash_sessions',
      {
        'montant_cloture': montantCompte,
        'date_cloture': DateTime.now().toIso8601String(),
        'statut': 'cloturee',
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Calcule le total des ventes réalisées par un utilisateur depuis l'ouverture de sa session
  Future<double> calculerVentesDepuisOuverture(String userId, DateTime dateOuverture) async {
    final ventes = await _saleRepository.listerVentesParVendeur(userId);
    final ventesDepuisOuverture = ventes.where((v) => v.dateVente.isAfter(dateOuverture));
    return ventesDepuisOuverture.fold<double>(0, (somme, v) => somme + v.total);
  }

  /// Liste toutes les sessions de caisse (pour le Propriétaire)
  Future<List<CashSessionModel>> listerToutesLesSessions() async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query('cash_sessions', orderBy: 'date_ouverture DESC');
    return resultats.map((e) => CashSessionModel.fromMap(e)).toList();
  }
}