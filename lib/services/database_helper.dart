import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/recipe.dart';

class DatabaseHelper {
  static const _dbName = 'recipes.db';
  static const _tableName = 'favorites';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return await openDatabase(inMemoryDatabasePath, version: 1, onCreate: _onCreate);
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        name TEXT,
        category TEXT,
        area TEXT,
        instructions TEXT,
        thumbUrl TEXT,
        videoUrl TEXT,
        ingredients TEXT,
        measures TEXT
      )
    ''');
  }

  Future<int> insertFavorite(Recipe recipe) async {
    final db = await database;
    return await db.insert(_tableName, recipe.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> removeFavorite(String id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Recipe>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) => Recipe.fromDbMap(maps[i]));
  }

  Future<bool> isFavorite(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty;
  }
}