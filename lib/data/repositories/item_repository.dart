import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/item_model.dart';
import '../../core/constants/app_constants.dart';
import '../local/local_data_source.dart';

class ItemRepository {
  final FirebaseFirestore _firestore;
  final LocalDataSource _localDataSource;
  final Connectivity _connectivity = Connectivity();

  ItemRepository({
    FirebaseFirestore? firestore,
    LocalDataSource? localDataSource,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localDataSource = localDataSource ?? LocalDataSource();

  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || 
           result.contains(ConnectivityResult.wifi);
  }

  Future<List<ItemModel>> fetchItems({
    required String userId,
    required int pageSize,
    DocumentSnapshot? lastDocument,
    String? categoryFilter,
    bool? isActiveFilter,
  }) async {
    try {
      final isOnline = await _isOnline();

      if (isOnline) {
        // Fetch from Firestore (force server fetch to get latest data after sync)
        Query query = _firestore
            .collection(AppConstants.itemsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(pageSize);

        if (categoryFilter != null && categoryFilter.isNotEmpty) {
          query = query.where('category', isEqualTo: categoryFilter);
        }

        if (isActiveFilter != null) {
          query = query.where('isActive', isEqualTo: isActiveFilter);
        }

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        // Force fetch from server, not Firestore cache
        final querySnapshot = await query.get(const GetOptions(source: Source.server));
        final items = querySnapshot.docs
            .map((doc) => ItemModel.fromFirestore(doc))
            .toList();
        
        // Cache the items locally
        await _localDataSource.cacheItems(items);

        return items;
      } else {
        // Return cached items when offline
        return await _localDataSource.getCachedItems(
          userId: userId,
          category: categoryFilter,
          isActive: isActiveFilter,
          limit: pageSize,
        );
      }
    } catch (e) {
      // On error, try to return cached data
      try {
        return await _localDataSource.getCachedItems(
          userId: userId,
          category: categoryFilter,
          isActive: isActiveFilter,
          limit: pageSize,
        );
      } catch (_) {
        throw Exception('Failed to fetch items: $e');
      }
    }
  }

  Future<DocumentSnapshot?> getLastDocument({
    required String userId,
    required int pageSize,
    String? categoryFilter,
    bool? isActiveFilter,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.itemsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        query = query.where('category', isEqualTo: categoryFilter);
      }

      if (isActiveFilter != null) {
        query = query.where('isActive', isEqualTo: isActiveFilter);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) return null;
      return querySnapshot.docs.last;
    } catch (e) {
      return null;
    }
  }

  Future<ItemModel> addItem({
    required String userId,
    required String title,
    required String description,
    required String category,
    required bool isActive,
  }) async {
    try {
      final docRef =
          _firestore.collection(AppConstants.itemsCollection).doc();

      final item = ItemModel(
        id: docRef.id,
        title: title,
        description: description,
        category: category,
        createdAt: DateTime.now(),
        isActive: isActive,
        userId: userId,
      );

      final isOnline = await _isOnline();

      if (isOnline) {
        // Add to Firestore
        await docRef.set(item.toFirestore());
        // Cache locally
        await _localDataSource.updateCachedItem(item);
      } else {
        // Store locally and queue for sync
        await _localDataSource.updateCachedItem(item);
        await _localDataSource.addPendingOperation(
          operation: 'create',
          itemData: jsonDecode(jsonEncode(item.toFirestore())),
        );
      }

      return item;
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  Future<void> updateItem({
    required String itemId,
    String? title,
    String? description,
    String? category,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (isActive != null) updates['isActive'] = isActive;

      if (updates.isEmpty) return;

      final isOnline = await _isOnline();

      if (isOnline) {
        // Update in Firestore
        await _firestore
            .collection(AppConstants.itemsCollection)
            .doc(itemId)
            .update(updates);
        
        // Update cache
        final item = await _localDataSource.getCachedItemById(itemId);
        if (item != null) {
          final updatedItem = ItemModel(
            id: item.id,
            userId: item.userId,
            title: title ?? item.title,
            description: description ?? item.description,
            category: category ?? item.category,
            isActive: isActive ?? item.isActive,
            createdAt: item.createdAt,
          );
          await _localDataSource.updateCachedItem(updatedItem);
        }
      } else {
        // Queue for sync
        await _localDataSource.addPendingOperation(
          operation: 'update',
          itemId: itemId,
          itemData: updates,
        );
        
        // Update local cache optimistically
        final item = await _localDataSource.getCachedItemById(itemId);
        if (item != null) {
          final updatedItem = ItemModel(
            id: item.id,
            userId: item.userId,
            title: title ?? item.title,
            description: description ?? item.description,
            category: category ?? item.category,
            isActive: isActive ?? item.isActive,
            createdAt: item.createdAt,
          );
          await _localDataSource.updateCachedItem(updatedItem);
        }
      }
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      final isOnline = await _isOnline();

      if (isOnline) {
        // Delete from Firestore
        await _firestore
            .collection(AppConstants.itemsCollection)
            .doc(itemId)
            .delete();
        // Delete from cache
        await _localDataSource.deleteCachedItem(itemId);
      } else {
        // Queue for sync
        await _localDataSource.addPendingOperation(
          operation: 'delete',
          itemId: itemId,
          itemData: {},
        );
        // Delete from cache optimistically
        await _localDataSource.deleteCachedItem(itemId);
      }
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  Future<ItemModel?> getItemById(String itemId) async {
    try {
      final isOnline = await _isOnline();

      if (isOnline) {
        final doc = await _firestore
            .collection(AppConstants.itemsCollection)
            .doc(itemId)
            .get();

        if (!doc.exists) return null;

        final item = ItemModel.fromFirestore(doc);
        // Cache it
        await _localDataSource.updateCachedItem(item);
        return item;
      } else {
        // Return from cache
        return await _localDataSource.getCachedItemById(itemId);
      }
    } catch (e) {
      // Try cache on error
      try {
        return await _localDataSource.getCachedItemById(itemId);
      } catch (_) {
        throw Exception('Failed to get item: $e');
      }
    }
  }

  Future<int> getItemsCount({
    required String userId,
    String? categoryFilter,
    bool? isActiveFilter,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.itemsCollection)
          .where('userId', isEqualTo: userId);

      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        query = query.where('category', isEqualTo: categoryFilter);
      }

      if (isActiveFilter != null) {
        query = query.where('isActive', isEqualTo: isActiveFilter);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get items count: $e');
    }
  }

  Stream<List<ItemModel>> watchItems({
    required String userId,
    int? limit,
    String? categoryFilter,
    bool? isActiveFilter,
  }) {
    Query query = _firestore
        .collection(AppConstants.itemsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      query = query.where('category', isEqualTo: categoryFilter);
    }

    if (isActiveFilter != null) {
      query = query.where('isActive', isEqualTo: isActiveFilter);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ItemModel.fromFirestore(doc))
              .toList(),
        );
  }
}
