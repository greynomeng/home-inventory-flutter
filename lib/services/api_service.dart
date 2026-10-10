// lib/services/api_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/location.dart';
import '../utils/app_config.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final baseUri = Uri.parse(AppConfig.baseUrl);

    return baseUri.replace(
      path: '${baseUri.path}$path',
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final request = http.Request(method, _uri(path, queryParameters));

    request.headers['Accept'] = 'application/json';

    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    try {
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      final responseBody = response.body;

      dynamic data;

      if (responseBody.isNotEmpty) {
        try {
          data = jsonDecode(responseBody);
        } on FormatException {
          throw ApiException(
            'The server returned an invalid response.',
            statusCode: response.statusCode,
          );
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map<String, dynamic>
            ? data['error']?.toString() ?? data['message']?.toString()
            : null;

        throw ApiException(
          message ?? 'Request failed (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      return data;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        'Unable to connect to the server. '
        'Check your network connection and server address.',
        cause: error,
      );
    }
  }

  // --------------------------------------------------
  // Categories
  // --------------------------------------------------
  Future<List<Category>> getCategories() async {
    final data = await _request('GET', AppConfig.categoriesEndpoint);

    if (data is! List) {
      throw ApiException('Invalid categories response from server.');
    }

    return data
        .map(
          (json) => Category.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList();
  }

  Future<Category> createCategory(Category category) async {
    final data = await _request(
      'POST',
      AppConfig.categoriesEndpoint,
      body: category.toJson(),
    );

    return _parseCategory(data);
  }

  Future<Category> updateCategory(String id, Category category) async {
    final data = await _request(
      'PUT',
      '${AppConfig.categoriesEndpoint}/${Uri.encodeComponent(id)}',
      body: category.toJson(),
    );

    return _parseCategory(data);
  }

  Future<void> deleteCategory(String id) async {
    await _request(
      'DELETE',
      '${AppConfig.categoriesEndpoint}/${Uri.encodeComponent(id)}',
    );
  }

  Category _parseCategory(dynamic data) {
    if (data is! Map) {
      throw ApiException('Invalid category response from server.');
    }

    return Category.fromJson(Map<String, dynamic>.from(data));
  }

  // --------------------------------------------------
  // Locations
  // --------------------------------------------------
  Future<List<Location>> getLocations() async {
    final data = await _request('GET', AppConfig.locationsEndpoint);

    if (data is! List) {
      throw ApiException('Invalid locations response from server.');
    }

    return data
        .map(
          (json) => Location.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList();
  }

  Future<Location> createLocation(Location location) async {
    final data = await _request(
      'POST',
      AppConfig.locationsEndpoint,
      body: location.toJson(),
    );

    return _parseLocation(data);
  }

  Future<Location> updateLocation(String id, Location location) async {
    final data = await _request(
      'PUT',
      '${AppConfig.locationsEndpoint}/${Uri.encodeComponent(id)}',
      body: location.toJson(),
    );

    return _parseLocation(data);
  }

  Future<void> deleteLocation(String id) async {
    await _request(
      'DELETE',
      '${AppConfig.locationsEndpoint}/${Uri.encodeComponent(id)}',
    );
  }

  Location _parseLocation(dynamic data) {
    if (data is! Map) {
      throw ApiException('Invalid location response from server.');
    }

    return Location.fromJson(Map<String, dynamic>.from(data));
  }

  // --------------------------------------------------
  // Items
  // --------------------------------------------------
  Future<List<Map<String, dynamic>>> getItems({
    String? search,
    String? category,
    String? location,
    bool? asset,
  }) async {
    final queryParameters = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (category != null && category.isNotEmpty) {
      queryParameters['category'] = category;
    }

    if (location != null && location.isNotEmpty) {
      queryParameters['location'] = location;
    }

    if (asset != null) {
      queryParameters['asset'] = asset.toString();
    }

    final data = await _request(
      'GET',
      AppConfig.itemsEndpoint,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    if (data is! List) {
      throw ApiException('Invalid items response from server.');
    }

    return data.map((json) => Map<String, dynamic>.from(json as Map)).toList();
  }

  Future<Map<String, dynamic>> createItem(Map<String, dynamic> item) async {
    final data = await _request('POST', AppConfig.itemsEndpoint, body: item);

    return _parseItem(data);
  }

  Future<Map<String, dynamic>> updateItem(
    String id,
    Map<String, dynamic> item,
  ) async {
    final data = await _request(
      'PUT',
      '${AppConfig.itemsEndpoint}/${Uri.encodeComponent(id)}',
      body: item,
    );

    return _parseItem(data);
  }

  Future<void> deleteItem(String id) async {
    await _request(
      'DELETE',
      '${AppConfig.itemsEndpoint}/${Uri.encodeComponent(id)}',
    );
  }

  Map<String, dynamic> _parseItem(dynamic data) {
    if (data is! Map) {
      throw ApiException('Invalid item response from server.');
    }

    return Map<String, dynamic>.from(data);
  }

  // --------------------------------------------------
  // Cleanup
  // --------------------------------------------------
  void dispose() {
    _client.close();
  }
}

// ----------------------------------------------------
// API exception
// ----------------------------------------------------
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;

  const ApiException(this.message, {this.statusCode, this.cause});

  @override
  String toString() => message;
}
