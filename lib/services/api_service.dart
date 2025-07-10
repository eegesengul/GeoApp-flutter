import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static String baseUrl =
      "https://10.0.2.2:7262/api"; // örnek, kendi API adresini gir!
  static String? token;

  static Map<String, String> getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<http.Response> post(String path, dynamic body) {
    return http.post(
      Uri.parse('$baseUrl/$path'),
      headers: getHeaders(),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> get(String path) {
    return http.get(
      Uri.parse('$baseUrl/$path'),
      headers: getHeaders(),
    );
  }

  static Future<http.Response> put(String path, dynamic body) {
    return http.put(
      Uri.parse('$baseUrl/$path'),
      headers: getHeaders(),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String path) {
    return http.delete(
      Uri.parse('$baseUrl/$path'),
      headers: getHeaders(),
    );
  }
}
