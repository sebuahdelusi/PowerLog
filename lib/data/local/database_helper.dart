import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/log_model.dart';
import '../models/token_model.dart';

class DatabaseHelper {
  static const _dbName = 'powerlog.db';
  static const _dbVersion = 4; // bumped: added tokens table

  static const tableUsers = 'users';
  static const tableLogs = 'logs';
  static const tableAppliances = 'appliances';
  static const tableTokens = 'tokens';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async { 
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createLogsTable(db);
    await _createAppliancesTable(db);
    await _createTokensTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createLogsTable(db);
    }
    if (oldVersion < 3) {
      await _createAppliancesTable(db);
    }
    if (oldVersion < 4) {
      await _createTokensTable(db);
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        encrypted_password TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableLogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        kwh_usage REAL NOT NULL,
        estimated_cost REAL NOT NULL
      )
    ''');
  }

  Future<void> _createAppliancesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableAppliances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        wattage REAL NOT NULL,
        hours_per_day REAL NOT NULL
      )
    ''');
  }

  Future<void> _createTokensTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableTokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        token_date TEXT NOT NULL,
        amount_idr REAL NOT NULL,
        plan_code TEXT NOT NULL,
        rate_per_kwh REAL NOT NULL,
        tax_percent REAL NOT NULL,
        include_tax INTEGER NOT NULL,
        fixed_fee REAL NOT NULL,
        include_fixed_fee INTEGER NOT NULL
      )
    ''');
  }

  // ── Users ────────────────────────────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return db.insert(tableUsers, user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      tableUsers,
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<int> updateUserPassword(String username, String newHash) async {
    final db = await database;
    return db.update(
      tableUsers,
      {'encrypted_password': newHash},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<bool> usernameExists(String username) async {
    final user = await getUserByUsername(username);
    return user != null;
  }

  // ── Logs ─────────────────────────────────────────────────────────────────

  Future<int> insertLog(LogModel log) async {
    final db = await database;
    return db.insert(tableLogs, log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LogModel>> getAllLogs() async {
    final db = await database;
    final maps = await db.query(tableLogs, orderBy: 'date DESC');
    return maps.map(LogModel.fromMap).toList();
  }

  Future<LogModel?> getLogByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      tableLogs,
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return LogModel.fromMap(maps.first);
  }

  Future<int> updateLogByDate(String date, double kwh, double cost) async {
    final db = await database;
    return db.update(
      tableLogs,
      {'kwh_usage': kwh, 'estimated_cost': cost},
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  Future<int> updateLogById(int id, double kwh, double cost) async {
    final db = await database;
    return db.update(
      tableLogs,
      {'kwh_usage': kwh, 'estimated_cost': cost},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateLogByIdWithDate(
    int id,
    String date,
    double kwh,
    double cost,
  ) async {
    final db = await database;
    return db.update(
      tableLogs,
      {'date': date, 'kwh_usage': kwh, 'estimated_cost': cost},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteLog(int id) async {
    final db = await database;
    return db.delete(tableLogs, where: 'id = ?', whereArgs: [id]);
  }

  // ── Appliances ───────────────────────────────────────────────────────────

  Future<int> insertAppliance(Map<String, dynamic> applianceMap) async {
    final db = await database;
    return db.insert(tableAppliances, applianceMap,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllAppliances() async {
    final db = await database;
    return db.query(tableAppliances, orderBy: 'name ASC');
  }

  Future<int> deleteAppliance(int id) async {
    final db = await database;
    return db.delete(tableAppliances, where: 'id = ?', whereArgs: [id]);
  }

  // ── Tokens ─────────────────────────────────────────────────────────────

  Future<int> insertToken(TokenModel token) async {
    final db = await database;
    return db.insert(tableTokens, token.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllTokens() async {
    final db = await database;
    return db.query(tableTokens, orderBy: 'token_date DESC, id DESC');
  }

  Future<Map<String, dynamic>?> getLatestToken() async {
    final db = await database;
    final maps = await db.query(
      tableTokens,
      orderBy: 'token_date DESC, id DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<Map<String, dynamic>?> getTokenByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      tableTokens,
      where: 'token_date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<int> updateTokenByDate(String date, TokenModel token) async {
    final db = await database;
    return db.update(
      tableTokens,
      token.toMap()..remove('id'),
      where: 'token_date = ?',
      whereArgs: [date],
    );
  }

  Future<int> deleteToken(int id) async {
    final db = await database;
    return db.delete(tableTokens, where: 'id = ?', whereArgs: [id]);
  }
}
