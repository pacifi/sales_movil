import 'package:flutter/material.dart';
import 'package:sales/models/product.dart';
import 'package:sales/services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];

  List<Product> get products => _products;

  ProductService productService = ProductService();

  Future<void> loadAll() async {
    _products = await productService.all();
    notifyListeners();
  }

  Future<void> save(Product product) async {
    await productService.save(product);
    await loadAll();
  }

  Future<void> edit(int id, Product product) async {
    await productService.edit(id, product);
    await loadAll();
  }

  Product getById(int id) {
    return _products.firstWhere((p) => p.id == id);
  }

  Future<void> delete(int id) async {
    await productService.delete(id);
    await loadAll();
  }
}