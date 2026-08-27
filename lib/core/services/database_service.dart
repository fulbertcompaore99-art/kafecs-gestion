import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

/// Service central de gestion de la base de données locale SQLite.
///
/// SYSTÈME DE MIGRATION : à chaque évolution du schéma (nouvelle table,
/// nouvelle colonne), on incrémente AppConstants.dbVersion et on ajoute
/// le code de migration correspondant dans _onUpgrade ci-dessous. Les
/// données existantes des utilisateurs ne sont JAMAIS effacées.
class DatabaseService {
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();

    // S'assure que le dossier existe réellement avant d'y créer la base
    // (nécessaire sur certaines configurations Windows où le dossier
    // Documents peut être redirigé ou absent au premier lancement).
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final path = join(directory.path, AppConstants.dbName);

    try {
      return await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw Exception("Impossible d'ouvrir la base de données au chemin : $path\nDétail : $e");
    }
  }

  /// Exécuté UNIQUEMENT lors de la toute première installation
  /// (base de données inexistante). Contient le schéma complet actuel.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        nom_complet TEXT NOT NULL,
        identifiant TEXT UNIQUE NOT NULL,
        mot_de_passe_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        actif INTEGER NOT NULL DEFAULT 1,
        date_creation TEXT NOT NULL,
        derniere_connexion TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        categorie_id TEXT,
        prix_achat REAL NOT NULL,
        prix_vente REAL NOT NULL,
        quantite_stock INTEGER NOT NULL DEFAULT 0,
        unite TEXT NOT NULL,
        reference TEXT,
        seuil_alerte INTEGER NOT NULL DEFAULT 5,
        date_creation TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (categorie_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        adresse TEXT NOT NULL,
        telephone TEXT,
        solde REAL NOT NULL DEFAULT 0,
        date_creation TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        numero_facture TEXT UNIQUE NOT NULL,
        client_id TEXT NOT NULL,
        client_nom TEXT NOT NULL,
        client_adresse TEXT NOT NULL,
        vendeur_id TEXT NOT NULL,
        vendeur_nom TEXT NOT NULL,
        total REAL NOT NULL,
        montant_paye REAL NOT NULL DEFAULT 0,
        date_vente TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (client_id) REFERENCES clients (id),
        FOREIGN KEY (vendeur_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        designation TEXT NOT NULL,
        quantite INTEGER NOT NULL,
        prix_unitaire REAL NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (sale_id) REFERENCES sales (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cash_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        fond_ouverture REAL NOT NULL,
        montant_cloture REAL,
        date_ouverture TEXT NOT NULL,
        date_cloture TEXT,
        statut TEXT NOT NULL DEFAULT 'ouverte',
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        libelle TEXT NOT NULL,
        montant REAL NOT NULL,
        user_id TEXT NOT NULL,
        user_nom TEXT NOT NULL,
        date_depense TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_counter (
        annee INTEGER PRIMARY KEY,
        dernier_numero INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Exécuté automatiquement quand AppConstants.dbVersion augmente sur un
  /// appareil ayant déjà une base existante. Chaque bloc "if (oldVersion < X)"
  /// correspond à une évolution du schéma, appliquée dans l'ordre, sans
  /// jamais supprimer les données existantes de l'utilisateur.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajout du suivi des paiements partiels (ventes à crédit)
      await db.execute("ALTER TABLE sales ADD COLUMN montant_paye REAL NOT NULL DEFAULT 0");
      // Les ventes déjà existantes sont considérées comme intégralement payées
      await db.execute("UPDATE sales SET montant_paye = total");
    }
  }

  /// Supprime TOUTES les données de toutes les tables (remet l'app à zéro,
  /// comme une nouvelle installation). Les comptes utilisateurs sont
  /// également effacés — au prochain lancement, l'écran de configuration
  /// initiale demandera de recréer le compte Propriétaire.
  Future<void> reinitialiserToutesLesDonnees() async {
    final db = await database;
    await db.delete('sale_items');
    await db.delete('sales');
    await db.delete('cash_sessions');
    await db.delete('expenses');
    await db.delete('products');
    await db.delete('categories');
    await db.delete('clients');
    await db.delete('invoice_counter');
    await db.delete('users');
  }
}