// lib/widgets/item_form.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../models/location.dart';
import '../services/image_service.dart';

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

  // Image handling
  final ImagePicker _picker = ImagePicker();
  final ImageService _imageService = ImageService();

  late String _photo;
  late List<ItemImage> _images;

  final Set<String> _newUploads = {};
  final Set<String> _pendingDeleteUrls = {};

  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();

    final item = widget.initialItem;

    _photo = item?.photo ?? 'no-image.png';
    _images = List<ItemImage>.from(item?.images ?? const []);

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
      // photo: previous?.photo ?? 'no-image.png',
      photo: _photo,
      purchaseDate: _purchaseDate.text.trim(),
      vendor: _vendor.text.trim(),
      warranty: _warranty.text.trim(),
      purchasePrice: _readPrice(_purchasePrice),
      replacementCost: _readPrice(_replacementCost),
      location: _location,
      category: _category,
      asset: _asset,
      // images: previous?.images ?? const [],
      images: List<ItemImage>.from(_images),
    );

    try {
      await widget.onSave(item);

      _newUploads.clear();

      // Remove old images only after item update has succeded.
      for (final url in _pendingDeleteUrls.toList()) {
        try {
          await _imageService.deleteImage(url);
        } catch (_) {
          // The item is saved; failed cleanup can be retried later.
        }
      }
      _pendingDeleteUrls.clear();

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

  Future<ImageSource?> _chooseImageSource() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose image source'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMainPhoto(ImageSource source) async {
    if (_uploadingImage) return;

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );

      if (file == null) return;

      setState(() => _uploadingImage = true);

      final url = await _imageService.uploadImage(
        file,
        imageDir: 'photos',
      );

      if (!mounted) {
        await _imageService.deleteImage(url);
        return;
      }

      setState(() {
        if (_photo != 'no-image.png' && _photo.isNotEmpty) {
          _pendingDeleteUrls.add(_photo);
        }
        _photo = url;
        _newUploads.add(url);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload photo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<String?> _askImageCaption() async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => const _ImageCaptionDialog(),
    );

    // final controller = TextEditingController();
    // try {
    //   return await showDialog(
    //     context: context,
    //     builder: (context) => AlertDialog(
    //       title: const Text('Image caption'),
    //       content: TextField(
    //         controller: controller,
    //         autofocus: true,
    //         decoration: const InputDecoration(
    //           labelText: 'Caption',
    //           hintText: 'e.g. Front view, serial number',
    //         ),
    //       ),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.pop(context),
    //           child: const Text('Cancel'),
    //         ),
    //         FilledButton(
    //           onPressed: () => Navigator.pop(context, controller.text.trim()),
    //           child: const Text('Contiue'),
    //         ),
    //       ],
    //     ),
    //   );
    // } finally {
    //   controller.dispose();
    // }
  }

  Future<void> _pickAdditionalImage({required bool receipt}) async {
    if (_uploadingImage) return;

    final caption = receipt ? 'Receipr' : await _askImageCaption();

    final source = await _chooseImageSource();
    if (source == null) return;

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );

      if (file == null) return;

      setState(() => _uploadingImage = true);

      final url = await _imageService.uploadImage(
        file,
        imageDir: 'images',
      );

      if (!mounted) {
        await _imageService.deleteImage(url);
        return;
      }

      setState(() {
        _images.add(ItemImage(caption: caption!, image: url));
        _newUploads.add(url);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add image: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() {
      final removed = _images.removeAt(index);
      _pendingDeleteUrls.add(removed.image);
    });
  }

  Future<void> _cancelForm() async {
    // Uploads made during this unsaved form should not be left behind.
    for (final url in _newUploads.toList()) {
      try {
        await _imageService.deleteImage(url);
      } catch (_) {
        // Cleanup is best-effort when cancelling.
      }
    }
    if (mounted) Navigator.of(context).pop();
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
                _imageSection(),
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
          onPressed: (_saving || _uploadingImage) ? null : _cancelForm,
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: (_saving || _uploadingImage) ? null : _submit,
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

  Widget _imageSection() {
    final photoUrl = _photo.isEmpty || _photo == 'no-image.png'
        ? null
        : _imageService.absoluteUrl(_photo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Main photo',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 120,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: photoUrl == null
                  ? const Icon(Icons.image_outlined, size: 48)
                  : Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined, size: 48),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploadingImage
                        ? null
                        : () => _pickMainPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _uploadingImage
                        ? null
                        : () => _pickMainPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_uploadingImage) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
          const SizedBox(height: 4),
          const Text('Uploading image...'),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Additional images and receipts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            PopupMenuButton<String>(
              enabled: !_uploadingImage,
              tooltip: 'Add image',
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onSelected: (value) {
                _pickAdditionalImage(receipt: value == 'receipt');
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'image',
                  child: ListTile(
                    leading: Icon(Icons.photo_library_outlined),
                    title: Text('Additional image'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'receipt',
                  child: ListTile(
                    leading: Icon(Icons.receipt_long_outlined),
                    title: Text('Receipt'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_images.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No additional images or receipts.'),
          )
        else
          ...List.generate(_images.length, (index) {
            final image = _images[index];

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 64,
                height: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    _imageService.absoluteUrl(image.image),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              title: Text(
                image.caption.isEmpty ? 'Image' : image.caption,
              ),
              subtitle: Text(
                image.caption.toLowerCase().contains('receipt')
                    ? 'Receipt'
                    : 'Additional image',
              ),
              trailing: IconButton(
                tooltip: 'Remove image',
                icon: const Icon(Icons.delete_outline),
                onPressed: _uploadingImage
                    ? null
                    : () => _removeAdditionalImage(index),
              ),
            );
          }),
        const Divider(height: 28),
      ],
    );
  }
}

class _ImageCaptionDialog extends StatefulWidget {
  const _ImageCaptionDialog();

  @override
  State<_ImageCaptionDialog> createState() => _ImageCaptionDialogState();
}

class _ImageCaptionDialogState extends State<_ImageCaptionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Image caption'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Caption',
          hintText: 'e.g. Front view, serial number',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _continue(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _continue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
