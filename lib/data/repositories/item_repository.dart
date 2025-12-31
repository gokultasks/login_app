import '../models/item_model.dart';

class ItemRepository {
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  List<ItemModel> _generateMockItems(int start, int count) {
    final categories = [
      'Technology',
      'Business',
      'Health',
      'Education',
      'Entertainment',
    ];
    return List.generate(count, (index) {
      final actualIndex = start + index;
      return ItemModel(
        id: 'item_$actualIndex',
        title: 'Item ${actualIndex + 1}',
        description:
            'This is a detailed description for item ${actualIndex + 1}. '
            'It contains various information about this item.',
        category: categories[actualIndex % categories.length],
        createdAt: DateTime.now().subtract(Duration(days: actualIndex)),
        isActive: actualIndex % 3 != 0,
      );
    });
  }

  Future<List<ItemModel>> fetchItems({
    required int page,
    required int pageSize,
  }) async {
    await _simulateNetworkDelay();

    if (page > 10) {
      throw Exception('No more items available');
    }

    final startIndex = page * pageSize;
    return _generateMockItems(startIndex, pageSize);
  }

  Future<ItemModel> addItem({
    required String title,
    required String description,
    required String category,
    required bool isActive,
  }) async {
    await _simulateNetworkDelay();

    return ItemModel(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      category: category,
      createdAt: DateTime.now(),
      isActive: isActive,
    );
  }

  Future<void> deleteItem(String id) async {
    await _simulateNetworkDelay();
  }
}
