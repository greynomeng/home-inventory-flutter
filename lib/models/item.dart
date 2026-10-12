// lib/models/item.dart

class ItemImage {
  final String caption;
  final String image;

  const ItemImage({
    this.caption = '',
    required this.image,
  });

  factory ItemImage.fromJson(Map<String, dynamic> json) {
    return ItemImage(
      caption: json['caption']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'caption': caption,
    'image': image,
  };
}

class Item {
  final String? id;
  final String name;
  final String make;
  final String model;
  final String serialNo;
  final String notes;
  final String photo;
  final String purchaseDate;
  final String vendor;
  final String warranty;
  final double? purchasePrice;
  final double? replacementCost;
  final String location;
  final String category;
  final bool asset;
  final List<ItemImage> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Item({
    this.id,
    required this.name,
    this.make = '',
    this.model = '',
    this.serialNo = '',
    this.notes = '',
    this.photo = 'no-image.png',
    this.purchaseDate = '',
    this.vendor = '',
    this.warranty = '',
    this.purchasePrice,
    this.replacementCost,
    this.location = '',
    this.category = '',
    this.asset = false,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: (json['_id'] ?? json['id'])?.toString(),
      name: json['name']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      serialNo: json['serial_no']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      photo: json['photo']?.toString() ?? 'no-image.png',
      purchaseDate: _stringValue(json['purchase_date']),
      vendor: json['vendor']?.toString() ?? '',
      warranty: _stringValue(json['warranty']),
      purchasePrice: _parseDouble(json['purchase_price']),
      replacementCost: _parseDouble(json['replacement_cost']),
      location: json['location']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      asset: json['asset'] == true,
      images: _parseImages(json['images']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'make': make,
      'model': model,
      'serial_no': serialNo,
      'notes': notes,
      'photo': photo,
      'purchase_date': purchaseDate,
      'vendor': vendor,
      'warranty': warranty,
      'purchase_price': purchasePrice,
      'replacement_cost': replacementCost,
      'location': location,
      'category': category,
      'asset': asset,
      'images': images.map((image) => image.toJson()).toList(),
    };
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<ItemImage> _parseImages(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map(
          (image) => ItemImage.fromJson(
            Map<String, dynamic>.from(image),
          ),
        )
        .toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
