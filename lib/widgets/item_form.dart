// lib/widgets/item_form.dart

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../models/location.dart';

class ItemForm extends StatefulWidget {
  final Item? initialItem;
  final List<Category> categories;
  final List<Location> locations;
  final Future<void> Function(Item item) onSave;

  const ItemForm({
    super.key,
    this.initialItem,
    required this.categories,
    required this.locations,
    required this.onSave,
  });

  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _make;
  late final TextEditingController _model;
  late final TextEditingController _serialNo;
  late final TextEditingController _notes;
  late final TextEditingController _purchaseDate;
  late final TextEditingController _vendor;
  late final TextEditingController _warranty;
  late final TextEditingController _purchasePrice;
  late final TextEditingController _replacementCost;

  String _category = '';
  String _location = '';
  bool _asset = false;
  bool _saving = false;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();

    final item = widget.initialItem;

    _name = TextEditingController(text: item?.name ?? '');
    _make = TextEditingController(text: item?.make ?? '');
    _model = TextEditingController(text: item?.model ?? '');
    _serialNo = TextEditingController(text: item?.serialNo ?? '');
    _notes = TextEditingController(text: item?.notes ?? '');
    _purchaseDate = TextEditingController(text: item?.purchaseDate ?? '');
    _vendor = TextEditingController(text: item?.vendor ?? '');
    _warranty = TextEditingController(text: item?.warranty ?? '');
    _purchasePrice = TextEditingController(
      text: item?.purchasePrice?.toString() ?? '',
    );
    _replacementCost = TextEditingController(
      text: item?.replacementCost?.toString() ?? '',
    );

    _category = _validInitialValue(
      item?.category ?? '',
      widget.categories.map((c) => c.name).toList(),
    );
    _location = _validInitialValue(
      item?.location ?? '',
      widget.locations.map((l) => l.name).toList(),
    );

    _asset = item?.asset ?? false;
  }

  String _validInitialValue(String value, List<String> options) {
    return options.contains(value) ? value : '';
  }

  @override
  void dispose() {
    _name.dispose();
    _make.dispose();
    _model.dispose();
    _serialNo.dispose();
    _notes.dispose();
    _purchaseDate.dispose();
    _vendor.dispose();
    _warranty.dispose();
    _purchasePrice.dispose();
    _replacementCost.dispose();
    super.dispose();
  }

  double? _readPrice(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final previous = widget.initialItem;

    final item = Item(
      id: previous?.id,
      name: _name.text.trim(),
      make: _make.text.trim(),
      model: _model.text.trim(),
      serialNo: _serialNo.text.trim(),
      notes: _notes.text.trim(),
      photo: previous?.photo ?? 'no-image.png',
      purchaseDate: _purchaseDate.text.trim(),
      vendor: _vendor.text.trim(),
      warranty: _warranty.text.trim(),
      purchasePrice: _readPrice(_purchasePrice),
      replacementCost: _readPrice(_replacementCost),
      location: _location,
      category: _category,
      asset: _asset,
      images: previous?.images ?? const [],
    );

    try {
      await widget.onSave(item);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save item: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      title: Text(_isEditing ? 'Edit item' : 'Add item'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(
                  label: 'Item name *',
                  controller: _name,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an item name';
                    }
                    return null;
                  },
                ),
                _textField(label: 'Make / brand', controller: _make),
                _textField(label: 'Model', controller: _model),
                _textField(
                  label: 'Serial number',
                  controller: _serialNo,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('No category'),
                    ),
                    ...widget.categories.map(
                      (category) => DropdownMenuItem(
                        value: category.name,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _category = value ?? '');
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _location,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('No location'),
                    ),
                    ...widget.locations.map(
                      (location) => DropdownMenuItem(
                        value: location.name,
                        child: Text(location.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _location = value ?? '');
                  },
                ),
                const SizedBox(height: 12),
                _textField(
                  label: 'Purchase date',
                  controller: _purchaseDate,
                  hint: 'e.g. 2025-06-30',
                ),
                _textField(label: 'Vendor / supplier', controller: _vendor),
                _textField(
                  label: 'Warranty',
                  controller: _warranty,
                  hint: 'e.g. 2 years',
                ),
                _textField(
                  label: 'Purchase price',
                  controller: _purchasePrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value != null &&
                        value.trim().isNotEmpty &&
                        double.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                _textField(
                  label: 'Replacement cost',
                  controller: _replacementCost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value != null &&
                        value.trim().isNotEmpty &&
                        double.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                _textField(
                  label: 'Notes',
                  controller: _notes,
                  maxLines: 3,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Asset'),
                  subtitle: const Text('Mark this item as an asset'),
                  value: _asset,
                  onChanged: (value) => setState(() => _asset = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
