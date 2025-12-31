import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/item_model.dart';
import '../../data/repositories/item_repository.dart';
import '../bloc/item_list/item_list_bloc.dart';
import '../bloc/item_list/item_list_event.dart';
import '../bloc/item_list/item_list_state.dart';
import '../bloc/item_form/item_form_bloc.dart';
import 'item_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ItemListBloc>().add(const LoadMoreItems());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB74D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              context.read<ItemListBloc>().add(const RefreshItems());
            },
          ),
        ],
      ),
      body: BlocBuilder<ItemListBloc, ItemListState>(
        builder: (context, state) {
          switch (state.status) {
            case ItemListStatus.loading:
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB74D)),
                ),
              );

            case ItemListStatus.failure:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading items',
                      style: TextStyle(fontSize: 18, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ItemListBloc>().add(const LoadItems());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB74D),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );

            case ItemListStatus.success:
            case ItemListStatus.loadingMore:
              if (state.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first item',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFFFFB74D),
                onRefresh: () async {
                  context.read<ItemListBloc>().add(const RefreshItems());
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.hasReachedMax
                      ? state.items.length
                      : state.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFB74D),
                            ),
                          ),
                        ),
                      );
                    }

                    final item = state.items[index];
                    return _ItemCard(item: item);
                  },
                ),
              );

            default:
              return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => ItemFormBloc(
                  itemRepository: context.read<ItemRepository>(),
                ),
                child: const ItemFormScreen(),
              ),
            ),
          );

          if (result != null && result is ItemModel) {
            if (mounted) {
              context.read<ItemListBloc>().add(AddNewItem(result));
            }
          }
        },
        backgroundColor: const Color(0xFFFFB74D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ItemModel item;

  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB74D).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.category,
                        size: 14,
                        color: Color(0xFFFF8A00),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF8A00),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(item.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
