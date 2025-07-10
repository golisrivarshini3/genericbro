import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicine.dart';
import 'dart:developer' as developer;

class ApiService {
  static const String baseUrl = 'https://generic-bro.onrender.com/finder';
  static const String pharmacyBaseUrl = 'https://generic-bro.onrender.com/locator';
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration timeout = Duration(seconds: 10);

  static void _logRequest(String endpoint, dynamic body) {
    developer.log(
      'API Request',
      name: 'ApiService',
      error: {
        'endpoint': endpoint,
        'body': body,
      },
    );
  }

  static void _logResponse(String endpoint, int statusCode, String body) {
    developer.log(
      'API Response',
      name: 'ApiService',
      error: {
        'endpoint': endpoint,
        'statusCode': statusCode,
        'body': body,
      },
    );
  }

  static void _logError(String endpoint, dynamic error) {
    developer.log(
      'API Error',
      name: 'ApiService',
      error: {
        'endpoint': endpoint,
        'error': error.toString(),
      },
    );
  }

  static Future<T> _retryRequest<T>(Future<T> Function() request, String endpoint) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await request().timeout(timeout);
      } catch (e) {
        attempts++;
        _logError(endpoint, 'Attempt $attempts failed: $e');
        if (attempts == maxRetries) {
          _logError(endpoint, 'Max retries exceeded');
          rethrow;
        }
        await Future.delayed(retryDelay * attempts);
      }
    }
    throw Exception('Max retries exceeded');
  }

  // Fetch suggestions for autocomplete
  static Future<List<String>> fetchSuggestions(String field, String query) async {
    if (query.isEmpty) return [];

    final endpoint = '/suggestions/$field';
    _logRequest(endpoint, {'query': query});

    try {
      final response = await _retryRequest(() => http.get(
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: {'query': query}),
        headers: {'Content-Type': 'application/json'},
      ), endpoint);

      _logResponse(endpoint, response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['suggestions'] is List) {
          return List<String>.from(
            data['suggestions'].map((suggestion) => suggestion['value'] as String)
          );
        }
        return [];
      } else {
        final error = _parseErrorResponse(response);
        throw Exception(error);
      }
    } catch (e) {
      _logError(endpoint, e);
      throw Exception('Failed to fetch suggestions: $e');
    }
  }

  static String _parseErrorResponse(http.Response response) {
    try {
      final error = json.decode(response.body);
      return error['detail'] ?? 'Unknown error occurred';
    } catch (e) {
      return 'Error: ${response.statusCode}';
    }
  }

  // Search medicines
  static Future<Map<String, dynamic>> searchMedicines({
    String? name,
    String? formulation,
    String? type,
    String? dosage,
    String? sortOrder,
  }) async {
    const endpoint = '/search';
    
    // Log the raw type value
    if (type != null) {
      developer.log(
        'Type value details',
        name: 'ApiService',
        error: {
          'raw_type': type,
          'length': type.length,
          'codeUnits': type.codeUnits,
          'trimmed_length': type.trim().length,
        },
      );
    }
    
    final requestBody = {
      if (name?.isNotEmpty == true) 'name': name,
      if (formulation?.isNotEmpty == true) 'formulation': formulation,
      if (type?.isNotEmpty == true) 'type': type?.trim(),  // Trim any whitespace
      if (dosage?.isNotEmpty == true) 'dosage': dosage,
    };

    _logRequest(endpoint, {
      'raw_body': requestBody,
      'encoded_body': json.encode(requestBody),
      'sort_order': sortOrder,
    });

    try {
      final queryParams = sortOrder != null ? {'sort_order': sortOrder} : null;
      final response = await _retryRequest(() => http.post(
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ), endpoint);

      _logResponse(endpoint, response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'exact_match': data['exact_match'] != null 
              ? Medicine.fromJson(data['exact_match']) 
              : null,
          'similar_formulations': (data['similar_formulations'] as List)
              .map((m) => Medicine.fromJson(m))
              .toList(),
          'Uses': data['Uses'],
          'Side Effects': data['Side Effects'],
        };
      } else {
        final error = _parseErrorResponse(response);
        throw Exception(error);
      }
    } catch (e) {
      _logError(endpoint, e);
      throw Exception('Failed to search medicines: $e');
    }
  }

  // Get medicine details
  static Future<Medicine> getMedicineDetails(String name) async {
    final endpoint = '/medicine/$name';
    _logRequest(endpoint, null);

    try {
      final response = await _retryRequest(() => http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ), endpoint);

      _logResponse(endpoint, response.statusCode, response.body);

      if (response.statusCode == 200) {
        return Medicine.fromJson(json.decode(response.body));
      } else {
        final error = _parseErrorResponse(response);
        throw Exception(error);
      }
    } catch (e) {
      _logError(endpoint, e);
      throw Exception('Failed to get medicine details: $e');
    }
  }

  // New method for type-based filtering
  static Future<List<Medicine>> getMedicinesByType(String type, {String? sortOrder}) async {
    final endpoint = '/medicines/by_type';
    final queryParams = {
      'type': type,
      if (sortOrder != null) 'sort_order': sortOrder,
    };
    _logRequest(endpoint, {'type': type, 'sort_order': sortOrder});

    try {
      final response = await _retryRequest(() => http.get(
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      ), endpoint);

      _logResponse(endpoint, response.statusCode, response.body);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Medicine.fromJson(item)).toList();
      } else {
        final error = _parseErrorResponse(response);
        throw Exception(error);
      }
    } catch (e) {
      _logError(endpoint, e);
      throw Exception('Failed to fetch medicines by type: $e');
    }
  }

  // Pharmacy Locator Methods
  static Future<Map<String, dynamic>> searchPharmaciesByPincode(String pincode) async {
    final endpoint = '/search/by-pincode';
    _logRequest(endpoint, {'pincode': pincode});

    try {
      final response = await _retryRequest(() => http.get(
        Uri.parse('$pharmacyBaseUrl$endpoint').replace(queryParameters: {'pincode': pincode}),
        headers: {'Content-Type': 'application/json'},
      ), endpoint);

      _logResponse(endpoint, response.statusCode, response.body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = _parseErrorResponse(response);
        throw Exception(error);
      }
    } catch (e) {
      _logError(endpoint, e);
      throw Exception('Failed to search pharmacies by PIN code: $e');
    }
  }

  static Future<Map<String, dynamic>> searchPharmaciesByArea(String area) async {
    final endpoint = '/search/by-area';
    _logRequest(endpoint, {'area': area});

    try {
      final response = await _retryRequest(() => http.get(
        Uri.parse('$pharmacyBaseUrl$endpoint').replace(queryParameters: {'area': area}),
        headers: {'Content-Type': 'application/json'},
      ), endpoint);

      _logResponse(endpoint, response.statusCode, response.body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = _parseErrorResponse(response);
        throw Exception(error);
      }
    } catch (e) {
      _logError(endpoint, e);
      throw Exception('Failed to search pharmacies by area: $e');
    }
  }

  static Future<Map<String, dynamic>> searchPharmaciesByCoordinates(
    double latitude,
    double longitude,
    {double radiusKm = 5.0}
  ) async {
    final endpoint = '/search/by-coordinates';
    _logRequest(endpoint, {
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
    });

    try {
      final response = await _retryRequest(() => http.get(
        Uri.parse('$pharmacyBaseUrl$endpoint').replace(queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radius_km': radiusKm.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      ), endpoint);

      _logResponse(endpoint, response.statusCode, response.body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = _parseErrorResponse(response);
        throw Exception(error);
      }
    } catch (e) {
      _logError(endpoint, e);
      throw Exception('Failed to search pharmacies by coordinates: $e');
    }
  }

  static Future<List<String>> getPharmacySuggestions(String field, String query) async {
    if (query.isEmpty) return [];

    final endpoint = '/suggestions/$field';
    _logRequest(endpoint, {'query': query});

    try {
      final response = await _retryRequest(() => http.get(
        Uri.parse('$pharmacyBaseUrl$endpoint').replace(queryParameters: {'query': query}),
        headers: {'Content-Type': 'application/json'},
      ), endpoint);

      _logResponse(endpoint, response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['suggestions']);
      } else {
        final error = _parseErrorResponse(response);
        throw Exception(error);
      }
    } catch (e) {
      _logError(endpoint, e);
      throw Exception('Failed to fetch pharmacy suggestions: $e');
    }
  }

  static Future<List<String>> getSuggestions(String type, String input) async {
    try {
      final response = await http.get(
        Uri.parse('$pharmacyBaseUrl/suggest/$type?input=$input'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['suggestions']);
      } else {
        throw Exception('Failed to get suggestions');
      }
    } catch (e) {
      throw Exception('Error getting suggestions: $e');
    }
  }

  static Future<Map<String, dynamic>> searchByDistrict(String district) async {
    final endpoint = '/search/by-district';
    _logRequest(endpoint, {'district_name': district});

    try {
      final response = await _retryRequest(() => http.get(
        Uri.parse('$pharmacyBaseUrl$endpoint').replace(queryParameters: {'district_name': district}),
        headers: {'Content-Type': 'application/json'},
      ), endpoint);

      _logResponse(endpoint, response.statusCode, response.body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = _parseErrorResponse(response);
        throw Exception(error);
      }
    } catch (e) {
      _logError(endpoint, e);
      throw Exception('Failed to search pharmacies by district: $e');
    }
  }

  static Future<Map<String, dynamic>> searchByState(String state) async {
    final endpoint = '/search/by-state';
    _logRequest(endpoint, {'state_name': state});

    try {
      final response = await _retryRequest(() => http.get(
        Uri.parse('$pharmacyBaseUrl$endpoint').replace(queryParameters: {'state_name': state}),
        headers: {'Content-Type': 'application/json'},
      ), endpoint);

      _logResponse(endpoint, response.statusCode, response.body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = _parseErrorResponse(response);
        throw Exception(error);
      }
    } catch (e) {
      _logError(endpoint, e);
      throw Exception('Failed to search pharmacies by state: $e');
    }
  }
} 