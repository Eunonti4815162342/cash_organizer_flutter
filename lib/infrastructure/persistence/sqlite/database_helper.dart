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

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cash_organizer.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Tabla de Cuentas
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        amount_value INTEGER NOT NULL,
        amount_currency TEXT NOT NULL,
        description TEXT,
        last_updated TEXT
      )
    ''');

    // Tabla de Categorías
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id INTEGER,
        type TEXT NOT NULL, -- INCOME, EXPENSE
        icon TEXT,
        FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de Subcategorías
    await db.execute('''
      CREATE TABLE subcategories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        icon TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de Transacciones con Flag de Sincronización (OFF-005)
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER, -- ID asignado por el backend
        amount_value INTEGER NOT NULL,
        amount_currency TEXT NOT NULL,
        type TEXT NOT NULL, -- INCOME, EXPENSE, TRANSFER
        description TEXT,
        date TEXT NOT NULL,
        account_id INTEGER NOT NULL,
        to_account_id INTEGER,
        category_id INTEGER,
        subcategory_id INTEGER,
        pending_sync INTEGER DEFAULT 0, -- 1 = Pendiente de subir, 0 = Sincronizado
        FOREIGN KEY (account_id) REFERENCES accounts (id),
        FOREIGN KEY (to_account_id) REFERENCES accounts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (subcategory_id) REFERENCES subcategories (id)
      )
    ''');
  }

  // Métodos de ayuda para debugging/inspección rápida
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('categories');
    await db.delete('accounts');
  }
}
