// lib/services/product_service.dart
// Mismo patrón que CategoryService — token como parámetro en cada método.

import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:sales/config/app_config.dart';
import 'package:sales/models/product.dart';

class ProductService {
  final String apiUrl = AppConfig.apiUrl;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<Product>> all(String token) async {
    var url = Uri.http(apiUrl, '/product/products/');
    var response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body) as List<dynamic>;
      return jsonResponse.map((j) => Product.fromJson(j)).toList();
    } else {
      throw Exception('Error al cargar productos');
    }
  }

  Future<Product> getById(int id, String token) async {
    var url = Uri.http(apiUrl, '/product/products/$id/');
    var response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      return Product.fromJson(convert.jsonDecode(response.body));
    } else {
      throw Exception('Error al cargar producto');
    }
  }

  Future<void> save(Product product, String token) async {
    var url = Uri.http(apiUrl, '/product/products/');
    var response = await http.post(
      url,
      body: convert.jsonEncode(product.toJson()),
      headers: _headers(token),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al guardar producto');
    }
  }

  Future<void> edit(int id, Product product, String token) async {
    var url = Uri.http(apiUrl, '/product/products/$id/');
    var response = await http.put(
      url,
      body: convert.jsonEncode(product.toJson()),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al editar producto');
    }
  }

  Future<void> delete(int id, String token) async {
    var url = Uri.http(apiUrl, '/product/products/$id/');
    var response = await http.delete(url, headers: _headers(token));
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar producto');
    }
  }
}