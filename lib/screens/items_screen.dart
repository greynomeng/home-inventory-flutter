// lib/screens/items_screen.dart

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../models/location.dart';
import '../services/api_service.dart';
import '../widgets/item_form.dart';

class ItemsScreen extends StatefulWidget {
  final ApiService apiService;

  const ItemsScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<Item> _items = [];
  List<Category> _categories = [];
  List<Location> _locations = [];

  bool _loading = true;
  String? _error;

  String _search = '';
  String _categoryFilter = '';
  String _locationFilter = '';
  bool _assetsOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.apiService.getItems(
          search: _search.trim().isEmpty ? null : _search.trim(),
          category: _categoryFilter.isEmpty ? null : _categoryFilter,
          location: _locationFilter.isEmpty ? null : _locationFilter,
          asset: _assetsOnly ? true : null,
        ),
        widget.apiService.getCategories(),
        widget.apiService.getLocations(),
      ]);

      final items = (results[0] as List<Map<String, dynamic>>)
          .map(Item.fromJson)
          .toList();

      if (!mounted) return;

      setState(() {
        _items = items;
        _categories = results[1] as List<Category>;
        _locations = results[2] as List<Location>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Item? item}) async {
    // Ensure the form has up-to-date category and location options.
    if (_categories.isEmpty || _locations.isEmpty) {
      try {
        final results = await Future.wait([
          widget.apiService.getCategories(),
          widget.apiService.getLocations(),
        ]);

        if (!mounted) return;

        setState(() {
          _categories = results[0] as List<Category>;
          _locations = results[1] as List<Location>;
        });
      } catch (error) {
        if (!mounted) return;
        _showMessage('Could not load categories and locations: $error');
        return;
      }
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ItemForm(
        initialItem: item,
        categories: _categories,
        locations: _locations,
        onSave: (value) async {
          if (item?.id == null) {
            await widget.apiService.createItem(value.toJson());
          } else {
            await widget.apiService.updateItem(
              item!.id!,
              value.toJson(),
            );
          }
        },
      ),
    );

    if (mounted) await _loadData();
  }

  Future<void> _deleteItem(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text(
          'Delete "${item.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || item.id == null) return;

    try {
      await widget.apiService.deleteItem(item.id!);
      if (!mounted) return;
      _showMessage('Item deleted');
      await _loadData();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not delete item: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _categoryFilter = '';
      _locationFilter = '';
      _assetsOnly = false;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search items',
                hintText: 'Search by item name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          setState(() => _search = '');
                          _loadData();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _search = value);
              },
              onSubmitted: (_) => _loadData(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: wide ? 210 : 155,
                  child: DropdownButtonFormField<String>(
                    initialValue: _categoryFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All categories'),
                      ),
                      ..._categories.map(
                        (category) => DropdownMenuItem(
                          value: category.name,
                          child: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _categoryFilter = value ?? '');
                      _loadData();
                    },
                  ),
                ),
                SizedBox(
                  width: wide ? 210 : 155,
                  child: DropdownButtonFormField<String>(
                    initialValue: _locationFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All locations'),
                      ),
                      ..._locations.map(
                        (location) => DropdownMenuItem(
                          value: location.name,
                          child: Text(
                            location.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _locationFilter = value ?? '');
                      _loadData();
                    },
                  ),
                ),
                FilterChip(
                  label: const Text('Assets only'),
                  selected: _assetsOnly,
                  onSelected: (value) {
                    setState(() => _assetsOnly = value);
                    _loadData();
                  },
                ),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 44),
              const SizedBox(height: 12),
              Text(
                'Could not load inventory.\n$_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.inventory_2_outlined, size: 60),
            SizedBox(height: 16),
            Center(child: Text('No items found')),
            SizedBox(height: 8),
            Center(
              child: Text('Try changing the search or filters.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 650
              ? 2
              : 1;

          if (columns == 1) {
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
              itemCount: _items.length,
              itemBuilder: (context, index) => _buildItemCard(_items[index]),
            );
          }

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) => _buildItemCard(_items[index]),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                child: Icon(
                  item.asset ? Icons.home_work_outlined : Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (item.make.isNotEmpty || item.model.isNotEmpty)
                      Text(
                        [
                          item.make,
                          item.model,
                        ].where((s) => s.isNotEmpty).join(' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      [
                            if (item.category.isNotEmpty) item.category,
                            if (item.location.isNotEmpty) item.location,
                          ].join(' • ').isEmpty
                          ? 'No category or location'
                          : [
                              if (item.category.isNotEmpty) item.category,
                              if (item.location.isNotEmpty) item.location,
                            ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Item actions',
                onSelected: (value) {
                  if (value == 'edit') _openForm(item: item);
                  if (value == 'delete') _deleteItem(item);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(Item item) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.name),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detail('Make / brand', item.make),
                _detail('Model', item.model),
                _detail('Serial number', item.serialNo),
                _detail('Category', item.category),
                _detail('Location', item.location),
                _detail('Purchase date', item.purchaseDate),
                _detail('Vendor', item.vendor),
                _detail('Warranty', item.warranty),
                _detail(
                  'Purchase price',
                  item.purchasePrice == null
                      ? ''
                      : item.purchasePrice!.toStringAsFixed(2),
                ),
                _detail(
                  'Replacement cost',
                  item.replacementCost == null
                      ? ''
                      : item.replacementCost!.toStringAsFixed(2),
                ),
                _detail('Asset', item.asset ? 'Yes' : 'No'),
                _detail('Notes', item.notes),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openForm(item: item);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
