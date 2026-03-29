import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Cambia esta URL a la URL de tu backend Go en produccion
  static const String _baseUrl = 'http://localhost:8080/api/v1';

  final String? _idToken;

  ApiService({String? idToken}) : _idToken = idToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_idToken != null) 'Authorization': 'Bearer $_idToken',
      };

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateCurrentUser({
    String? displayName,
    String? photoUrl,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (photoUrl != null) body['photoUrl'] = photoUrl;

    final response = await http.put(
      Uri.parse('$_baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['error'] ?? 'Error desconocido del servidor');
  }
}
