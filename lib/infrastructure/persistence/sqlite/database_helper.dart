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
    String path = join(await getDatabasesPath(), 'cash_organizer_v4.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // accounts: id es local (puede ser negativo para offline creates),
    // server_id es el ID del backend (null mientras pending_sync=1)
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
        pending_sync INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL
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
        to_account_id INTEGER,
        to_account_name TEXT,
        pending_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE accounts ADD COLUMN pending_sync INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE accounts ADD COLUMN account_type TEXT');
      await db.execute('ALTER TABLE accounts ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN subcategory_id INTEGER');
      await db.execute('ALTER TABLE transactions ADD COLUMN to_account_id INTEGER');
      await db.execute('ALTER TABLE transactions ADD COLUMN to_account_name TEXT');
    }
    if (oldVersion < 3) {
      // Añade server_id a accounts; para registros ya sincronizados server_id = id
      await db.execute('ALTER TABLE accounts ADD COLUMN server_id INTEGER');
      await db.execute('UPDATE accounts SET server_id = id WHERE pending_sync = 0 OR pending_sync IS NULL');
    }
  }

  Future<void> clearDatabase() async {
    String path = join(await getDatabasesPath(), 'cash_organizer_v4.db');
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await deleteDatabase(path);
    print('[DatabaseHelper] Base de datos local eliminada con éxito.');
  }
}
