// lib/providers/product_provider.dart
// Mismo patrón que CategoryProvider.

import 'package:flutter/material.dart';
import 'package:sales/models/product.dart';
import 'package:sales/providers/auth_provider.dart';
import 'package:sales/services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> get products => _products;

  final ProductService productService = ProductService();
  final AuthProvider _authProvider;

  ProductProvider(this._authProvider);

  String get _token => _authProvider.token!;

  Future<void> loadAll() async {
    _products = await productService.all(_token);
    notifyListeners();
  }

  Future<void> save(Product product) async {
    await productService.save(product, _token);
    await loadAll();
  }

  Future<void> edit(int id, Product product) async {
    await productService.edit(id, product, _token);
    await loadAll();
  }

  Product getById(int id) {
    return _products.firstWhere((p) => p.id == id);
  }

  Future<void> delete(int id) async {
    await productService.delete(id, _token);
    await loadAll();
  }
}