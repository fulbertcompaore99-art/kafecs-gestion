import 'package:uuid/uuid.dart';

import '../../core/services/database_service.dart';
import '../models/client_model.dart';

class ClientRepository {
  final _uuid = const Uuid();

  Future<ClientModel> creerClient({
    required String nom,
    required String adresse,
    String? telephone,
  }) async {
    final client = ClientModel(
      id: _uuid.v4(),
      nom: nom,
      adresse: adresse,
      telephone: telephone,
      dateCreation: DateTime.now(),
    );

    final db = await DatabaseService.instance.database;
    await db.insert('clients', client.toMap());
    return client;
  }

  Future<List<ClientModel>> listerTousLesClients() async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query('clients', orderBy: 'nom ASC');
    return resultats.map((e) => ClientModel.fromMap(e)).toList();
  }

  Future<List<ClientModel>> rechercherClients(String recherche) async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query(
      'clients',
      where: 'nom LIKE ?',
      whereArgs: ['%$recherche%'],
      orderBy: 'nom ASC',
    );
    return resultats.map((e) => ClientModel.fromMap(e)).toList();
  }

  Future<ClientModel?> trouverParId(String id) async {
    final db = await DatabaseService.instance.database;
    final resultats = await db.query('clients', where: 'id = ?', whereArgs: [id], limit: 1);
    if (resultats.isEmpty) return null;
    return ClientModel.fromMap(resultats.first);
  }

  Future<void> modifierClient(ClientModel client) async {
    final db = await DatabaseService.instance.database;
    await db.update('clients', client.toMap(), where: 'id = ?', whereArgs: [client.id]);
  }
  
  /// Supprime définitivement un client
  Future<void> supprimerClient(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }
}