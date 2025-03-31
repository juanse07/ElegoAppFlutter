import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // Direct URL for API access
  static const String apiBaseUrl = 'api.elegoprime.com';
  static const String apiFullUrl = 'https://$apiBaseUrl';
  static const String serviceRequestsEndpoint = '/new-service-request';

  // Process item data to ensure image paths are valid
  Map<String, dynamic> _sanitizeItemData(Map<String, dynamic> itemData) {
    // Skip processing if itemData is null
    if (itemData.containsKey('furnitureImageUrl') &&
        itemData['furnitureImageUrl'] != null) {
      String imageUrl = itemData['furnitureImageUrl'].toString();

      // Filter out example.com URLs
      if (imageUrl.contains('example.com')) {
        itemData['furnitureImageUrl'] = '';
      }

      // Only add image1Path if it doesn't already exist
      if ((!itemData.containsKey('image1Path') ||
              itemData['image1Path'] == null ||
              itemData['image1Path'].toString().isEmpty) &&
          imageUrl.isNotEmpty) {
        itemData['image1Path'] = imageUrl;
      }
    }

    // Sanitize image1Path
    if (itemData.containsKey('image1Path') && itemData['image1Path'] != null) {
      String imagePath = itemData['image1Path'].toString();
      if (imagePath.contains('example.com')) {
        itemData['image1Path'] = '';
      }
    }

    // Sanitize image2Path
    if (itemData.containsKey('image2Path') && itemData['image2Path'] != null) {
      String imagePath = itemData['image2Path'].toString();
      if (imagePath.contains('example.com')) {
        itemData['image2Path'] = '';
      }
    }

    return itemData;
  }

  // Get all service requests - sorted by newest first
  Future<List<dynamic>> getItems() async {
    try {
      final url = Uri.parse('$apiFullUrl$serviceRequestsEndpoint');

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load service requests: HTTP ${response.statusCode}',
        );
      }

      final List<dynamic> jsonData = jsonDecode(response.body);

      // Process each item for backwards compatibility with furnitureImageUrl
      // and sanitize image paths
      for (var i = 0; i < jsonData.length; i++) {
        if (jsonData[i] is Map<String, dynamic>) {
          jsonData[i] = _sanitizeItemData(jsonData[i]);
        }
      }

      // Sort data by createdAt date, newest first
      jsonData.sort((a, b) {
        // Try to get createdAt timestamp from each item
        DateTime dateA = _parseDate(a['createdAt']);
        DateTime dateB = _parseDate(b['createdAt']);

        // Sort in descending order (newest first)
        return dateB.compareTo(dateA);
      });

      return jsonData;
    } catch (e) {
      print('Exception during getItems: $e');
      rethrow;
    }
  }

  // Helper method to parse MongoDB date formats
  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is Map && dateValue['\$date'] != null) {
        if (dateValue['\$date'] is String) {
          return DateTime.parse(dateValue['\$date']);
        } else if (dateValue['\$date'] is Map &&
            dateValue['\$date']['\$numberLong'] != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            int.parse(dateValue['\$date']['\$numberLong']),
          );
        }
      }
    } catch (e) {
      // Silent error handling for date parsing
    }

    return DateTime.now();
  }

  // Get item by ID - simplified implementation
  Future<Map<String, dynamic>> getItemById(String id) async {
    try {
      // Use a proper query parameter format with the exact ID
      final url = Uri.parse('$apiFullUrl$serviceRequestsEndpoint?_id=$id');

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load service request: HTTP ${response.statusCode}',
        );
      }

      final jsonData = jsonDecode(response.body);

      // The response might be an array with one item instead of a single object
      Map<String, dynamic> itemData;
      if (jsonData is List) {
        if (jsonData.isEmpty) {
          throw Exception('No item found with ID: $id');
        }

        // Try to find the exact item with matching ID
        var exactItem = jsonData.firstWhere(
          (item) => _matchesId(item, id),
          orElse: () => jsonData.first,
        );

        itemData = exactItem;
      } else {
        itemData = jsonData;
      }

      // Sanitize image paths
      itemData = _sanitizeItemData(itemData);

      return itemData;
    } catch (e) {
      print('Exception during getItemById: $e');
      rethrow;
    }
  }

  // Helper to match an item ID against a target ID
  bool _matchesId(dynamic item, String targetId) {
    if (item is! Map<String, dynamic>) return false;

    try {
      String itemId;
      if (item['_id'] is String) {
        itemId = item['_id'];
      } else if (item['_id'] is Map && item['_id']['\$oid'] != null) {
        itemId = item['_id']['\$oid'];
      } else {
        itemId = item['_id'].toString();
      }

      return itemId == targetId;
    } catch (e) {
      return false;
    }
  }

  // Create new service request - simplified implementation
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$apiFullUrl$serviceRequestsEndpoint');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Failed to create service request: HTTP ${response.statusCode}',
        );
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Exception during createItem: $e');
      rethrow;
    }
  }

  // Delete service request - simplified implementation
  Future<void> deleteItem(String id) async {
    try {
      final url = Uri.parse('$apiFullUrl$serviceRequestsEndpoint/$id');
      final response = await http.delete(url);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete service request: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Exception during deleteItem: $e');
      rethrow;
    }
  }
}
