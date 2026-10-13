// lib/services/image_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../utils/app_config.dart';

// -----------------------------------------------
// ImageService
// -----------------------------------------------
class ImageService {
  String get _baseUrl => AppConfig.baseUrl;

  Future<String> uploadImage(XFile file, {required String imageDir}) async {
    if (imageDir != 'photos' && imageDir != 'images') {
      throw ArgumentError('Invalid image directory: $imageDir');
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw Exception('Image must be no larger than 5 MB.');
    }

    final uri = Uri.parse('$_baseUrl${AppConfig.uploadEndpoint}');
    final request = http.MultipartRequest('POST', uri)
      ..fields['imageDir'] = imageDir
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final Map<String, dynamic> data = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw Exception(
        data['error']?.toString() ?? 'Image upload failed.',
      );
    }

    final url = data['url']?.toString();

    if (url == null || url.isEmpty) {
      throw Exception('The server did not return an image URL.');
    }

    return url;
  }

  // -----------------------------------------------
  // deleteImage
  // -----------------------------------------------
  Future<void> deleteImage(String url) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl${AppConfig.uploadEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    );

    if (response.statusCode != 200) {
      final data = _decodeResponse(response);

      throw Exception(data['error']?.toString() ?? 'Image deletion failed.');
    }
  }

  // -----------------------------------------------
  // absoluteUrl
  // -----------------------------------------------
  String absoluteUrl(String url) {
    if (url.startsWith('https://') || url.startsWith('http://')) {
      return url;
    }

    return '$_baseUrl/${url.replaceFirst(RegExp(r'^/+'), '')}';
  }

  // -----------------------------------------------
  // _decodeResponse
  // -----------------------------------------------
  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) return decoded;

      return {'error': 'Unexpected server response.'};
    } on FormatException {
      return {'error': 'The server returned an invalid response.'};
    }
  }
}
