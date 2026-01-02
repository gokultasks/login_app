import '../models/item_model.dart';
import 'database_helper.dart';

class LocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;


  Future<void> cacheItems(List<ItemModel> items) async {
    for (final item in items) {
      await _dbHelper.insertItem(item);
    }
  }


  Future<List<ItemModel>> getCachedItems({
    required String userId,
    String? category,
    bool? isActive,
    int? limit,
  }) async {
    return await _dbHelper.getItems(
      userId: userId,
      category: category,
      isActive: isActive,
      limit: limit,
    );
  }


  Future<ItemModel?> getCachedItemById(String id) async {
    return await _dbHelper.getItemById(id);
  }


  Future<void> updateCachedItem(ItemModel item) async {
    await _dbHelper.updateItem(item);
  }


  Future<void> deleteCachedItem(String id) async {
    await _dbHelper.deleteItem(id);
  }


  Future<void> clearCache(String userId) async {
    await _dbHelper.clearItems(userId);
  }


  Future<void> addPendingOperation({
    required String operation,
    String? itemId,
    required Map<String, dynamic> itemData,
  }) async {
    await _dbHelper.insertPendingOperation(
      operation: operation,
      itemId: itemId,
      itemData: itemData,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    return await _dbHelper.getPendingOperations();
  }

  Future<void> removePendingOperation(int id) async {
    await _dbHelper.deletePendingOperation(id);
  }

  Future<void> clearPendingOperations() async {
    await _dbHelper.clearPendingOperations();
  }

  Future<void> incrementOperationRetry(int operationId) async {
    await _dbHelper.incrementRetryCount(operationId);
  }
}
