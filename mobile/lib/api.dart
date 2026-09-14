import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl();

  String baseUrl;

  static String defaultBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE');
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'http://42.96.2.48:3001';
  }

  Uri _uri(String path) => Uri.parse('$baseUrl/api$path');

  Future<dynamic> _request(String path, {String method = 'GET', Object? body}) async {
    final uri = _uri(path);
    final headers = {'Content-Type': 'application/json'};
    late http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        response = await http.get(uri, headers: headers);
    }
    if (response.statusCode == 204) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = response.body.isEmpty ? 'API ${response.statusCode}' : response.body;
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map && parsed['error'] is String) {
          message = parsed['error'] as String;
        }
      } catch (_) {}
      throw ApiException(message);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<bool> health() async {
    final data = await _request('/health');
    return data is Map && data['ok'] == true;
  }

  Future<List<Place>> fetchPlaces() async {
    final data = await _request('/places');
    if (data is! List) return [];
    return data.map((item) => Place.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Place> createPlace(Map<String, dynamic> draft) async {
    final data = await _request('/places', method: 'POST', body: draft);
    return Place.fromJson(data as Map<String, dynamic>);
  }

  Future<Place> updatePlace(String id, Map<String, dynamic> draft) async {
    final data = await _request('/places/$id', method: 'PUT', body: draft);
    return Place.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deletePlace(String id) async {
    await _request('/places/$id', method: 'DELETE');
  }

  Future<String> chat(List<ChatTurn> messages, String playerName) async {
    final data = await _request(
      '/chat',
      method: 'POST',
      body: {
        'playerName': playerName,
        'messages': messages.map((m) => {'role': m.role, 'text': m.text}).toList(),
      },
    );
    return (data as Map)['text'] as String? ?? '';
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
