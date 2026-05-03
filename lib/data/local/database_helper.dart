import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/log_model.dart';

class DatabaseHelper {
  static const _dbName = 'powerlog.db';
  static const _dbVersion = 2; // bumped: added logs table

  static const tableUsers = 'users';
  static const tableLogs = 'logs';

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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createLogsTable(db);
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

  Future<int> deleteLog(int id) async {
    final db = await database;
    return db.delete(tableLogs, where: 'id = ?', whereArgs: [id]);
  }
}
