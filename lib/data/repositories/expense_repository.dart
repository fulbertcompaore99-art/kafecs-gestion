import 'package:uuid/uuid.dart';

import '../../core/services/database_service.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final _uuid = const Uuid();

  Future<ExpenseModel> creerDepense({
    required String libelle,
    required double montant,
    required String userId,
    required String userNom,
  }) async {
    final depense = ExpenseModel(
      id: _uuid.v4(),
      libelle: libelle,
      montant: montant,
      userId: userId,
      userNom: userNom,
      dateDepense: DateTime.now(),
    );

    final db = await DatabaseService.instance.database;
    await db.insert('expenses', depense.toMap());
    return depense;
  }

  Future<List<ExpenseModel>> listerToutesLesDepenses() async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query('expenses', orderBy: 'date_depense DESC');
    return resultats.map((e) => ExpenseModel.fromMap(e)).toList();
  }

  Future<List<ExpenseModel>> listerDepensesEntreDates(DateTime debut, DateTime fin) async {
    final toutes = await listerToutesLesDepenses();
    return toutes.where((d) =>
      d.dateDepense.isAfter(debut.subtract(const Duration(seconds: 1))) &&
      d.dateDepense.isBefore(fin.add(const Duration(seconds: 1)))
    ).toList();
  }

  Future<void> supprimerDepense(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}