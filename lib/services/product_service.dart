import 'dart:convert' as convert;

import 'package:http/http.dart' as http;
import 'package:sales/config/app_config.dart';
import 'package:sales/models/product.dart';

class ProductService {
  final String apiUrl = AppConfig.apiUrl;

  Future<List<Product>> all() async {
    var url = Uri.http(apiUrl, '/product/products/');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body) as List<dynamic>;

      List<Product> products = jsonResponse
          .map((catJson) => Product.fromJson(catJson))
          .toList();
      return products;
    } else {
      throw Exception('Error al cargar products');
    }
  }

  Future<Product> getById(int id) async {
    var url = Uri.http(apiUrl, '/product/products/$id/');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body) as dynamic;

      Product product = Product.fromJson(jsonResponse);

      return product;
    } else {
      throw Exception('Error al cargar products');
    }
  }

  Future<void> save(Product product) async {
    var url = Uri.http(apiUrl, '/product/products/');

    var response = await http.post(
      url,
      body: convert.jsonEncode(product.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 201) {
      print("Guardado");
    } else {
      throw Exception('Error al guardar ');
    }
  }

  Future<void> edit(int id, Product product) async {
    var url = Uri.http(apiUrl, '/product/products/${id}/');

    var response = await http.put(
      url,
      body: convert.jsonEncode(product.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      print("Guardado");
    } else {
      throw Exception('Error al editar ');
    }
  }

  Future<void> delete(int id) async {
    var url = Uri.http(apiUrl, '/product/products/${id}/');

    var response = await http.delete(url);
    if (response.statusCode == 204) {
      print("Eliminado");
    } else {
      throw Exception('Error al eliminar ');
    }
  }
}
