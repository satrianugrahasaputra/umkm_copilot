import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardProvider with ChangeNotifier {
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _reports = [];
  bool _isLoading = false;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<dynamic> get reports => _reports;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/dashboard');
      _isLoading = false;
      if (response.statusCode == 200) {
        _dashboardData = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateNewInsight() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/api/chat/insight', {});
      if (response.statusCode == 200) {
        await fetchDashboard();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/reports');
      _isLoading = false;
      if (response.statusCode == 200) {
        _reports = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generateReport(String type) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/api/reports/generate?type=$type', {});
      _isLoading = false;
      if (response.statusCode == 201) {
        await fetchReports();
        return true;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
