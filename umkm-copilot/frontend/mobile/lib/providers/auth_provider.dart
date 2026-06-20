import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userProfile => _userProfile;

  Future<bool> checkAuthStatus() async {
    final token = await ApiService.getToken();
    if (token != null) {
      _isAuthenticated = true;
      notifyListeners();
      await fetchProfile();
      return true;
    }
    _isAuthenticated = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      _isLoading = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiService.saveToken(data['access_token']);
        _isAuthenticated = true;
        await fetchProfile();
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['detail'] ?? 'Login gagal. Coba lagi.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gangguan koneksi internet.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullname,
    required String businessName,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/api/auth/register', {
        'email': email,
        'password': password,
        'fullname': fullname,
        'business_name': businessName,
        'phone_number': phoneNumber,
      }, authRequired: false);
      _isLoading = false;

      if (response.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        _errorMessage = error['detail'] ?? 'Pendaftaran gagal.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gangguan koneksi internet.';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await ApiService.get('/api/auth/me');
      if (response.statusCode == 200) {
        _userProfile = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    await ApiService.removeToken();
    _isAuthenticated = false;
    _userProfile = null;
    notifyListeners();
  }
}
