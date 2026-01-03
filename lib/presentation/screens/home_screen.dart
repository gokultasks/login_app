import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/item_model.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/services/sync_service.dart';
import '../../data/local/draft_storage.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/item_list/item_list_bloc.dart';
import '../bloc/item_list/item_list_event.dart';
import '../bloc/item_list/item_list_state.dart';
import '../bloc/item_form/item_form_bloc.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import 'advanced_item_form_screen.dart';

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
    _loadInitialItems();
  }

  void _loadInitialItems() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      context.read<ItemListBloc>().add(LoadItems(authState.user.id));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthenticatedState) {
        context.read<ItemListBloc>().add(LoadMoreItems(authState.user.id));
      }
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
        title: Row(
          children: [
            const Text(
              'Home',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            BlocBuilder<ConnectivityBloc, ConnectivityState>(
              builder: (context, connectivityState) {
                if (connectivityState is ConnectivityOffline) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 14, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (connectivityState is ConnectivityOnline) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFB74D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthenticatedState) {
                context.read<ItemListBloc>().add(RefreshItems(authState.user.id));
                // Trigger sync when user manually refreshes
                context.read<SyncService>().syncPendingOperations();
              }
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
                        final authState = context.read<AuthBloc>().state;
                        if (authState is AuthenticatedState) {
                          context.read<ItemListBloc>().add(LoadItems(authState.user.id));
                        }
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
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthenticatedState) {
                    context.read<ItemListBloc>().add(RefreshItems(authState.user.id));
                  }
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
                    return _ItemCard(
                      key: ValueKey(item.id),
                      item: item,
                      onDelete: () {
                        context.read<ItemListBloc>().add(DeleteItem(item.id));
                      },
                      onEdit: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => ItemFormBloc(
                                itemRepository: context.read<ItemRepository>(),
                                draftStorage: DraftStorage(prefs: prefs),
                              ),
                              child: AdvancedItemFormScreen(item: item),
                            ),
                          ),
                        );
                        
                        if (result != null && mounted) {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthenticatedState) {
                            context.read<ItemListBloc>().add(RefreshItems(authState.user.id));
                          }
                        }
                      },
                    );
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
          final prefs = await SharedPreferences.getInstance();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => ItemFormBloc(
                  itemRepository: context.read<ItemRepository>(),
                  draftStorage: DraftStorage(prefs: prefs),
                ),
                child: const AdvancedItemFormScreen(),
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

  void _showFilterDialog(BuildContext context) {
    final itemListBloc = context.read<ItemListBloc>();
    final currentState = itemListBloc.state;
    
    String? selectedCategory = currentState.categoryFilter;
    bool? selectedIsActive = currentState.isActiveFilter;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Filter Items'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: selectedCategory == null,
                      onSelected: (selected) {
                        setState(() => selectedCategory = null);
                      },
                    ),
                    ...['Technology', 'Business', 'Health', 'Education', 'Entertainment']
                        .map((category) => FilterChip(
                              label: Text(category),
                              selected: selectedCategory == category,
                              onSelected: (selected) {
                                setState(() => selectedCategory = selected ? category : null);
                              },
                            )),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: selectedIsActive == null,
                      onSelected: (selected) {
                        setState(() => selectedIsActive = null);
                      },
                    ),
                    FilterChip(
                      label: const Text('Active'),
                      selected: selectedIsActive == true,
                      onSelected: (selected) {
                        setState(() => selectedIsActive = selected ? true : null);
                      },
                    ),
                    FilterChip(
                      label: const Text('Inactive'),
                      selected: selectedIsActive == false,
                      onSelected: (selected) {
                        setState(() => selectedIsActive = selected ? false : null);
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthenticatedState) {
                itemListBloc.add(ClearFilters(authState.user.id));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Clear All'),
          ),
          ElevatedButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthenticatedState) {
                itemListBloc.add(FilterItems(
                  userId: authState.user.id,
                  category: selectedCategory,
                  isActive: selectedIsActive,
                ));
              }
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB74D),
            ),
            child: const Text('Apply'),
          ),
        ],

      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ItemCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getCategoryGradient(item.category),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: item.isActive
                          ? Colors.green.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: item.isActive ? Colors.green : Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isActive ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: item.isActive ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: item.isActive ? Colors.green[700] : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              // Show budget and estimated hours if available
              if (item.budget != null || item.estimatedHours != null || item.dueDate != null) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (item.dueDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.orange[700]),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(item.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.estimatedHours != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: Colors.blue[700]),
                            const SizedBox(width: 6),
                            Text(
                              '${item.estimatedHours}h',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.budget != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_money, size: 14, color: Colors.green[700]),
                            const SizedBox(width: 6),
                            Text(
                              '\$${item.budget!.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(item.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onEdit,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Row(
                                  children: [
                                    Icon(Icons.warning_rounded, color: Colors.orange[700]),
                                    const SizedBox(width: 8),
                                    const Text('Delete Item'),
                                  ],
                                ),
                                content: const Text(
                                  'Are you sure you want to delete this item? This action cannot be undone.',
                                  style: TextStyle(fontSize: 15),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      onDelete();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[600],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.delete_rounded,
                              color: Colors.red[600],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getCategoryGradient(String category) {
    switch (category) {
      case 'Technology':
        return [Colors.blue[600]!, Colors.blue[800]!];
      case 'Business':
        return [Colors.purple[600]!, Colors.purple[800]!];
      case 'Health':
        return [Colors.green[600]!, Colors.green[800]!];
      case 'Education':
        return [Colors.orange[600]!, Colors.orange[800]!];
      case 'Entertainment':
        return [Colors.pink[600]!, Colors.pink[800]!];
      default:
        return [Colors.grey[600]!, Colors.grey[800]!];
    }
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
