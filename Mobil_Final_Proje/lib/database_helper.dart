import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'shopping_lists.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE shopping_lists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE shopping_list_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      listId INTEGER NOT NULL,
      itemName TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL NOT NULL,
      isChecked INTEGER NOT NULL,
      created_at TEXT NOT NULL, -- created_at sütunu eklendi
      FOREIGN KEY (listId) REFERENCES shopping_lists (id) ON DELETE CASCADE
    )
  ''');
  }

  Future<int> insertShoppingList(String title) async {
    final db = await database;
    final createdAt = DateTime.now().toIso8601String();
    return await db.insert('shopping_lists', {'title': title, 'created_at': createdAt});
  }

  Future<int> insertShoppingListItem(
      int listId, String itemName, int quantity, double price, bool isChecked) async {
    final db = await database;
    final createdAt = DateTime.now().toIso8601String();
    return await db.insert(
      'shopping_list_items',
      {
        'listId': listId,
        'itemName': itemName,
        'quantity': quantity,
        'price': price,
        'isChecked': isChecked ? 1 : 0,
        'created_at': createdAt,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getShoppingLists() async {
    final db = await database;
    return await db.query('shopping_lists', columns: ['id', 'title', 'created_at']);
  }

  Future<List<Map<String, dynamic>>> getShoppingItems(int listId) async {
    final db = await database;
    return await db.query(
      'shopping_list_items',
      columns: ['id', 'listId', 'itemName', 'quantity', 'price', 'isChecked', 'created_at'], // created_at sütunu eklendi
      where: 'listId = ?',
      whereArgs: [listId],
    );
  }

  Future<List<Map<String, dynamic>>> getItemsForList(int listId) async {
    final db = await database;
    return await db.query(
      'shopping_list_items',
      columns: ['id', 'listId', 'itemName', 'quantity', 'price', 'isChecked', 'created_at'], // created_at sütunu eklendi
      where: 'listId = ?',
      whereArgs: [listId],
    );
  }

  Future<void> updateItem(int id, int quantity, double price, int isChecked) async {
    final db = await database;
    try {
      await db.update(
        'shopping_list_items',
        {
          'quantity': quantity,
          'price': price,
          'isChecked': isChecked,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Hata (updateItem): $e');
    }
  }

  Future<int> deleteShoppingList(int id) async {
    final db = await database;
    return await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteItem(int itemId) async {
    final db = await database;
    return await db.delete('shopping_list_items', where: 'id = ?', whereArgs: [itemId]);
  }
}
