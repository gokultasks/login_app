import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/local_data_source.dart';
import '../repositories/item_repository.dart';

enum SyncOperationType { create, update, delete }

class SyncService {
  final LocalDataSource _localDataSource;
  final ItemRepository _itemRepository;
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required LocalDataSource localDataSource,
    required ItemRepository itemRepository,
  })  : _localDataSource = localDataSource,
        _itemRepository = itemRepository;

  /// Start listening to connectivity changes
  void startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.mobile) || 
          result.contains(ConnectivityResult.wifi)) {
        syncPendingOperations();
      }
    });
  }

  /// Stop listening to connectivity changes
  void stopListening() {
    _connectivitySubscription?.cancel();
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || 
           result.contains(ConnectivityResult.wifi);
  }

  /// Queue an operation for later sync
  Future<void> queueOperation({
    required SyncOperationType type,
    String? itemId,
    required Map<String, dynamic> itemData,
  }) async {
    await _localDataSource.addPendingOperation(
      operation: type.toString().split('.').last,
      itemId: itemId,
      itemData: itemData,
    );
  }

  /// Sync all pending operations
  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;
    if (!await isOnline()) return;

    _isSyncing = true;

    try {
      final pendingOps = await _localDataSource.getPendingOperations();

      for (final op in pendingOps) {
        try {
          await _executeOperation(op);
          await _localDataSource.removePendingOperation(op['id']);
        } catch (e) {
          // Increment retry count
          await _localDataSource.incrementOperationRetry(op['id']);
          
          // Remove if retry count exceeds limit (e.g., 5 attempts)
          if (op['retryCount'] >= 5) {
            await _localDataSource.removePendingOperation(op['id']);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _executeOperation(Map<String, dynamic> op) async {
    final operationType = op['operation'] as String;
    final itemData = _parseItemData(op['itemData'] as String);

    switch (operationType) {
      case 'create':
        await _itemRepository.addItem(
          userId: itemData['userId'],
          title: itemData['title'],
          description: itemData['description'],
          category: itemData['category'],
          isActive: itemData['isActive'],
        );
        break;

      case 'update':
        await _itemRepository.updateItem(
          itemId: op['itemId'],
          title: itemData.containsKey('title') ? itemData['title'] : null,
          description: itemData.containsKey('description') ? itemData['description'] : null,
          category: itemData.containsKey('category') ? itemData['category'] : null,
          isActive: itemData.containsKey('isActive') ? itemData['isActive'] : null,
        );
        break;

      case 'delete':
        await _itemRepository.deleteItem(op['itemId']);
        break;
    }
  }

  Map<String, dynamic> _parseItemData(String data) {
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      // Fallback parsing if stored as string representation
      return {};
    }
  }

  void dispose() {
    stopListening();
  }
}
