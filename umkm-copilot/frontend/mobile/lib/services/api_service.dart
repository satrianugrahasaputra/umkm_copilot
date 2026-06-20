import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulators, localhost for Web/iOS/Desktop
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> _getHeaders({bool authRequired = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authRequired) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // POST Request
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool authRequired = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(authRequired: authRequired);
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // GET Request
  static Future<http.Response> get(String endpoint, {bool authRequired = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(authRequired: authRequired);
    return await http.get(url, headers: headers);
  }

  // OAuth2 URL Encoded POST (Specifically for login request)
  static Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': email,
        'password': password,
      },
    );
  }
}
