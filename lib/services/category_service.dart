// lib/services/category_service.dart
//
// Cambio respecto a la versión anterior: todos los métodos reciben el token
// como parámetro String y lo inyectan en el header Authorization.
// Los services no leen el AuthProvider directamente — el provider o screen
// que invoca el service es responsable de pasar el token.
// Esto mantiene los services testeables e independientes del árbol de widgets.

import 'package:sales/config/app_config.dart';
import 'package:sales/models/category.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class CategoryService {
  final String apiUrl = AppConfig.apiUrl;

  // Construye los headers comunes para todas las peticiones autenticadas.
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        // El esquema Bearer es el estándar para JWT en APIs REST.
        'Authorization': 'Bearer $token',
      };

  Future<List<Category>> all(String token) async {
    var url = Uri.http(apiUrl, '/product/categories/');
    var response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body) as List<dynamic>;
      return jsonResponse.map((j) => Category.fromJson(j)).toList();
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

  Future<Category> getById(int id, String token) async {
    var url = Uri.http(apiUrl, '/product/categories/$id/');
    var response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      return Category.fromJson(convert.jsonDecode(response.body));
    } else {
      throw Exception('Error al cargar categoría');
    }
  }

  Future<void> save(Category category, String token) async {
    var url = Uri.http(apiUrl, '/product/categories/');
    var response = await http.post(
      url,
      body: convert.jsonEncode(category.toJson()),
      headers: _headers(token),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al guardar categoría');
    }
  }

  Future<void> edit(int id, Category category, String token) async {
    var url = Uri.http(apiUrl, '/product/categories/$id/');
    var response = await http.put(
      url,
      body: convert.jsonEncode(category.toJson()),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al editar categoría');
    }
  }

  Future<void> delete(int id, String token) async {
    var url = Uri.http(apiUrl, '/product/categories/$id/');
    var response = await http.delete(url, headers: _headers(token));
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar categoría');
    }
  }
}