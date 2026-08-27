import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'database_service.dart';

class SyncService {
  static final SyncService instance = SyncService._interne();
  SyncService._interne();

  final _firestore = FirebaseFirestore.instance;
  bool _synchronisationEnCours = false;
  Timer? _minuteur;

  static const List<String> _tablesSynchronisees = [
    'users',
    'products',
    'clients',
    'sales',
    'sale_items',
    'cash_sessions',
    'expenses',
  ];

  Future<void> _assurerConnexionFirebase() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      print("SYNC: Connexion Firebase anonyme réussie");
    }
  }

  void demarrerEcouteAutomatique() async {
    try {
      await _assurerConnexionFirebase();
    } catch (e) {
      print("ERREUR CONNEXION FIREBASE: $e");
    }

    Connectivity().onConnectivityChanged.listen((resultats) {
      final connecte = resultats.any((r) => r != ConnectivityResult.none);
      if (connecte) {
        synchroniserMaintenant();
      }
    });

    synchroniserMaintenant();

    _minuteur?.cancel();
    _minuteur = Timer.periodic(const Duration(seconds: 20), (_) {
      synchroniserMaintenant();
    });
  }

  void arreter() {
    _minuteur?.cancel();
  }

  Future<void> synchroniserMaintenant() async {
    if (_synchronisationEnCours) {
      print("SYNC: déjà en cours, on saute");
      return;
    }

    final connectivite = await Connectivity().checkConnectivity();
    final estConnecte = connectivite.any((r) => r != ConnectivityResult.none);
    if (!estConnecte) {
      print("SYNC: pas de connexion réseau");
      return;
    }

    _synchronisationEnCours = true;
    print("SYNC: démarrage de la synchronisation...");
    try {
      await _assurerConnexionFirebase();

      for (final table in _tablesSynchronisees) {
        await _pousserVersCloud(table);
        await _recupererDepuisCloud(table);
      }
      print("SYNC: terminée avec succès");
    } catch (e) {
      print("ERREUR SYNCHRONISATION: $e");
    } finally {
      _synchronisationEnCours = false;
    }
  }

  Future<void> _pousserVersCloud(String table) async {
    final db = await DatabaseService.instance.database;
    final nonSynchronises = await db.query(table, where: 'is_synced = 0');

    for (final ligne in nonSynchronises) {
      final id = ligne['id'] as String;
      await _firestore.collection(table).doc(id).set(ligne);
      await db.update(table, {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> _recupererDepuisCloud(String table) async {
    final db = await DatabaseService.instance.database;
    final snapshot = await _firestore.collection(table).get();

    for (final doc in snapshot.docs) {
      final donnees = doc.data();
      final existeLocalement = await db.query(
        table,
        where: 'id = ?',
        whereArgs: [doc.id],
        limit: 1,
      );

      if (existeLocalement.isEmpty) {
        final donneesAvecSync = Map<String, dynamic>.from(donnees);
        donneesAvecSync['is_synced'] = 1;
        await db.insert(table, donneesAvecSync);
      }
    }
  }
  
  /// Supprime TOUS les documents de toutes les collections Firestore.
  /// Utilisé lors d'une réinitialisation complète de l'application.
  Future<void> viderToutLeCloud() async {
    for (final table in _tablesSynchronisees) {
      final snapshot = await _firestore.collection(table).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }
}