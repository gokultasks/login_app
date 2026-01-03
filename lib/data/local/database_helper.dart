import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'items.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER,
        dueDate INTEGER,
        estimatedHours REAL,
        budget REAL,
        attachments TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        itemId TEXT,
        itemData TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retryCount INTEGER DEFAULT 0
      )
    ''');

   
    await db.execute('CREATE INDEX idx_userId ON items(userId)');
    await db.execute('CREATE INDEX idx_category ON items(category)');
    await db.execute('CREATE INDEX idx_isActive ON items(isActive)');
    await db.execute('CREATE INDEX idx_createdAt ON items(createdAt)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE items ADD COLUMN dueDate INTEGER');
      await db.execute('ALTER TABLE items ADD COLUMN estimatedHours REAL');
      await db.execute('ALTER TABLE items ADD COLUMN budget REAL');
      await db.execute('ALTER TABLE items ADD COLUMN attachments TEXT');
    }
  }

 
  Future<int> insertItem(ItemModel item) async {
    final db = await database;
    return await db.insert(
      'items',
      _itemToMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ItemModel>> getItems({
    required String userId,
    String? category,
    bool? isActive,
    int? limit,
  }) async {
    final db = await database;
    
    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    if (isActive != null) {
      whereClause += ' AND isActive = ?';
      whereArgs.add(isActive ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
      limit: limit,
    );

    return maps.map((map) => _mapToItem(map)).toList();
  }

  Future<ItemModel?> getItemById(String id) async {
    final db = await database;
    final maps = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _mapToItem(maps.first);
  }

  Future<int> updateItem(ItemModel item) async {
    final db = await database;
    return await db.update(
      'items',
      _itemToMap(item),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(String id) async {
    final db = await database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearItems(String userId) async {
    final db = await database;
    await db.delete(
      'items',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }


  Future<int> insertPendingOperation({
    required String operation,
    String? itemId,
    required Map<String, dynamic> itemData,
  }) async {
    final db = await database;
    return await db.insert('pending_operations', {
      'operation': operation,
      'itemId': itemId,
      'itemData': jsonEncode(itemData),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    return await db.query(
      'pending_operations',
      orderBy: 'timestamp ASC',
    );
  }

  Future<int> deletePendingOperation(int id) async {
    final db = await database;
    return await db.delete(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearPendingOperations() async {
    final db = await database;
    await db.delete('pending_operations');
  }

  Future<int> incrementRetryCount(int operationId) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE pending_operations SET retryCount = retryCount + 1 WHERE id = ?',
      [operationId],
    );
  }


  Map<String, dynamic> _itemToMap(ItemModel item) {
    return {
      'id': item.id,
      'userId': item.userId,
      'title': item.title,
      'description': item.description,
      'category': item.category,
      'isActive': item.isActive ? 1 : 0,
      'createdAt': item.createdAt.millisecondsSinceEpoch,
      'updatedAt': null,
      'dueDate': item.dueDate?.millisecondsSinceEpoch,
      'estimatedHours': item.estimatedHours,
      'budget': item.budget,
      'attachments': item.attachments != null && item.attachments!.isNotEmpty
          ? item.attachments!.join(',')
          : null,
    };
  }

  ItemModel _mapToItem(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
          : null,
      estimatedHours: map['estimatedHours'] as double?,
      budget: map['budget'] as double?,
      attachments: map['attachments'] != null
          ? (map['attachments'] as String).split(',')
          : null,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
