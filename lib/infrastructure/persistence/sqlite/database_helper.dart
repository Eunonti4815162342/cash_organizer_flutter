import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Wipes every locally cached table. Must run on logout: this DB has no
  /// user_id column, so without this, the next account to sign in on this
  /// device would see the previous user's cached accounts/transactions.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('subcategories');
      await txn.delete('categories');
      await txn.delete('accounts');
      await txn.delete('beneficiaries');
      await txn.delete('entities');
    });
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'natave_v1.db');
    return await openDatabase(
      path,
      version: 9, // Subimos a la versión 9
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE entities (id INTEGER PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL)');
    await db.execute('''
      CREATE TABLE beneficiaries (
        id INTEGER PRIMARY KEY, 
        name TEXT NOT NULL,
        last_category_id INTEGER,
        last_subcategory_id INTEGER,
        last_type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY,
        server_id INTEGER UNIQUE,
        name TEXT NOT NULL,
        amount_value INTEGER NOT NULL,
        amount_currency TEXT NOT NULL,
        is_negative INTEGER DEFAULT 0,
        description TEXT,
        account_type TEXT,
        notes TEXT,
        last_updated TEXT,
        pending_sync INTEGER DEFAULT 0,
        entity_id INTEGER,
        entity_name TEXT
      )
    ''');

    // Categorías con soporte para Entidades
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY, 
        name TEXT NOT NULL, 
        type TEXT NOT NULL,
        financial_entity_id INTEGER,
        financial_entity_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE subcategories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        amount_value INTEGER NOT NULL,
        amount_currency TEXT NOT NULL,
        is_negative INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        account_id INTEGER NOT NULL,
        account_name TEXT,
        category_id INTEGER,
        category_name TEXT,
        subcategory_id INTEGER,
        subcategory_name TEXT,
        beneficiary_id INTEGER,
        beneficiary_name TEXT,
        to_account_id INTEGER,
        to_account_name TEXT,
        pending_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('CREATE TABLE IF NOT EXISTS entities (id INTEGER PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL)');
    }
    if (oldVersion < 6) {
      try { await db.execute('ALTER TABLE transactions ADD COLUMN subcategory_name TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE transactions ADD COLUMN beneficiary_id INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE transactions ADD COLUMN beneficiary_name TEXT'); } catch (_) {}
    }
    if (oldVersion < 7) {
      await db.execute('CREATE TABLE IF NOT EXISTS beneficiaries (id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    }
    if (oldVersion < 8) {
      try { await db.execute('ALTER TABLE beneficiaries ADD COLUMN last_category_id INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE beneficiaries ADD COLUMN last_subcategory_id INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE beneficiaries ADD COLUMN last_type TEXT'); } catch (_) {}
    }
    // MIGRACIÓN VERSIÓN 9: Añadir soporte de entidades a categorías
    if (oldVersion < 9) {
      try { await db.execute('ALTER TABLE categories ADD COLUMN financial_entity_id INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE categories ADD COLUMN financial_entity_name TEXT'); } catch (_) {}
    }
  }
}
