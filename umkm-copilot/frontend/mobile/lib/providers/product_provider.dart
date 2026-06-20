import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<dynamic> _products = [];
  bool _isLoading = false;

  List<dynamic> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/api/products');
      _isLoading = false;
      if (response.statusCode == 200) {
        _products = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(String name, String description, double price, int stock, String unit) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/api/products', {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'unit': unit,
      });

      _isLoading = false;
      if (response.statusCode == 201) {
        await fetchProducts();
        return true;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
