import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category.dart';

class CategoriesScreen extends StatefulWidget {
  final ApiService apiService;

  const CategoriesScreen({super.key, required this.apiService});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];

  bool _isLoading = true;
  String? _errorMessage;
  String? _processingId;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await widget.apiService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load categories.';
        _isLoading = false;
      });
    }
  }

  Future<void> _showCategoryForm({Category? category}) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _CategoryFormDialog(
        category: category,
      ),
    );

    if (name == null || !mounted) return;

    final isEditing = category != null;

    setState(() {
      if (isEditing) {
        _processingId = category.id;
      } else {
        _isAdding = true;
      }
    });

    try {
      final updatedCategory = Category(
        id: category?.id,
        name: name,
      );

      if (isEditing) {
        final id = category.id;

        if (id == null || id.isEmpty) {
          throw const ApiException(
            'Cannot update a category without an ID.',
          );
        }

        await widget.apiService.updateCategory(
          id,
          updatedCategory,
        );
      } else {
        await widget.apiService.createCategory(
          updatedCategory,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Category updated successfully.'
                : 'Category added successfully.',
          ),
        ),
      );

      await _loadCategories();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError('Unable to save the category.');
    } finally {
      if (mounted) {
        setState(() {
          _processingId = null;
          _isAdding = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final id = category.id;

    if (id == null || id.isEmpty) {
      _showError('Cannot delete a category without an ID.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete category?'),
          content: Text(
            'Are you sure you want to delete '
            '"${category.name}"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processingId = id;
    });

    try {
      await widget.apiService.deleteCategory(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Category "${category.name}" deleted.',
          ),
        ),
      );

      await _loadCategories();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError('Unable to delete the category.');
    } finally {
      if (mounted) {
        setState(() {
          _processingId = null;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_categories.length} '
                    '${_categories.length == 1 ? 'category' : 'categories'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh categories',
                  onPressed: _isLoading ? null : _loadCategories,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isAdding || _isLoading
                      ? null
                      : () => _showCategoryForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Expanded(
              child: _buildErrorState(),
            )
          else if (_categories.isEmpty)
            Expanded(
              child: _buildEmptyState(),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCategories,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];

                    return _buildCategoryCard(category);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final theme = Theme.of(context);
    final isProcessing = _processingId == category.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: const Icon(Icons.category_outlined),
        ),
        title: Text(
          category.name,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: category.createdAt != null
            ? Text(
                'Added ${_formatDate(category.createdAt!)}',
              )
            : null,
        trailing: isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: 'Edit category',
                    onPressed: _processingId != null
                        ? null
                        : () => _showCategoryForm(
                            category: category,
                          ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete category',
                    onPressed: _processingId != null
                        ? null
                        : () => _confirmDelete(category),
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.category_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'No categories yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add a category to help organise your home inventory.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: _isAdding ? null : () => _showCategoryForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add category'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load categories',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final Category? category;

  const _CategoryFormDialog({
    this.category,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.category?.name ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _nameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Edit category' : 'Add category',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Category name',
              hintText: 'e.g. Electronics',
              prefixIcon: Icon(Icons.category_outlined),
              counterText: '',
            ),
            validator: (value) {
              final name = value?.trim() ?? '';

              if (name.isEmpty) {
                return 'Please enter a category name.';
              }

              if (name.length > 100) {
                return 'Name must not exceed 100 characters.';
              }

              return null;
            },
            onFieldSubmitted: (_) => _save(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Save changes' : 'Add'),
        ),
      ],
    );
  }
}
