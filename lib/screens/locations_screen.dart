// lib/screens/locations_screen.dart

import 'package:flutter/material.dart';

import '../models/location.dart';
import '../services/api_service.dart';

class LocationsScreen extends StatefulWidget {
  final ApiService apiService;

  const LocationsScreen({super.key, required this.apiService});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<Location> _locations = [];

  bool _isLoading = true;
  bool _isAdding = false;
  String? _errorMessage;
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locations = await widget.apiService.getLocations();

      if (!mounted) return;

      setState(() {
        _locations = locations;
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
        _errorMessage = 'Unable to load locations.';
        _isLoading = false;
      });
    }
  }

  Future<void> _showLocationForm({Location? location}) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _LocationFormDialog(
        location: location,
      ),
    );

    if (name == null || !mounted) return;

    final isEditing = location != null;

    setState(() {
      if (isEditing) {
        _processingId = location.id;
      } else {
        _isAdding = true;
      }
    });

    try {
      final updatedLocation = Location(
        id: location?.id,
        name: name,
      );

      if (isEditing) {
        final id = location.id;

        if (id == null || id.isEmpty) {
          throw const ApiException(
            'Cannot update a location without an ID.',
          );
        }

        await widget.apiService.updateLocation(
          id,
          updatedLocation,
        );
      } else {
        await widget.apiService.createLocation(updatedLocation);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Location updated successfulle.'
                : 'Location added successfulle.',
          ),
        ),
      );

      await _loadLocations();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError('Unable to save the location.');
    } finally {
      if (mounted) {
        setState(() {
          _processingId = null;
          _isAdding = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(Location location) async {
    final id = location.id;

    if (id == null || id.isEmpty) {
      _showError('Cannot delete a location without an ID.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete location?'),
        content: Text(
          'Are you sure you want to delete '
          '"${location.name}"?\n\n'
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
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processingId = id;
    });

    try {
      await widget.apiService.deleteLocation(id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text('Location "${location.name}" deleted.'),
        ),
      );

      await _loadLocations();
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError('Unable to delete the location.');
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
            padding: const EdgeInsetsGeometry.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_locations.length} '
                    '${_locations.length == 1 ? 'location' : 'locations'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh locations',
                  onPressed: _isLoading ? null : _loadLocations,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isAdding || _isLoading
                      ? null
                      : () => _showLocationForm(),
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
            Expanded(child: _buildErrorState())
          else if (_locations.isEmpty)
            ExcludeFocus(child: _buildEmptyState())
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLocations,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 600
                        ? 2
                        : 1;

                    if (columns == 1) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _locations.length,
                        itemBuilder: (context, index) {
                          return _buildLocationCard(
                            _locations[index],
                          );
                        },
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 100,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        return _buildLocationCard(_locations[index]);
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Location location) {
    final theme = Theme.of(context);
    final isProcessing = _processingId == location.id;

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
          child: const Icon(Icons.place_outlined),
        ),
        title: Text(
          location.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: location.createdAt != null
            ? Text('Added ${_formatDate(location.createdAt!)}')
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
                    tooltip: 'Edit location',
                    onPressed: _processingId != null
                        ? null
                        : () => _showLocationForm(location: location),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete location',
                    onPressed: _processingId != null
                        ? null
                        : () => _confirmDelete(location),
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
      onRefresh: _loadLocations,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.place_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'No locations yet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 32),
            child: Text(
              'Add locations such as the garage, kitchen, '
              'bedroom or storage room.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: _isAdding ? null : () => _showLocationForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add location'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsetsGeometry.all(24),
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
              'Could not load locations',
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
              onPressed: _loadLocations,
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

class _LocationFormDialog extends StatefulWidget {
  final Location? location;

  const _LocationFormDialog({this.location});

  @override
  State<_LocationFormDialog> createState() => __LocationFormDialogState();
}

class __LocationFormDialogState extends State<_LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.location?.name ?? '');
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
    final isEditing = widget.location != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Edit location' : 'Add location',
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
              labelText: 'Location name',
              hintText: 'e.g. Garage',
              prefixIcon: Icon(Icons.place_outlined),
              counterText: '',
            ),
            validator: (value) {
              final name = value?.trim() ?? '';

              if (name.isEmpty) {
                return 'Please enter a location name.';
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
