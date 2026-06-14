// /lib/services/category_service
import 'package:sales/config/app_config.dart';
import 'package:sales/models/category.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class CategoryService {
  final String apiUrl = AppConfig.apiUrl;

  Future<List<Category>> all() async {
    var url = Uri.http(apiUrl, '/product/categories/');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body) as List<dynamic>;

      List<Category> categories = jsonResponse
          .map((catJson) => Category.fromJson(catJson))
          .toList();
      return categories;
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

  Future<Category> getById(int id) async {
    var url = Uri.http(apiUrl, '/product/categories/$id/');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body) as dynamic;

      Category category = Category.fromJson(jsonResponse);

      return category;
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

  Future<void> save(Category category) async {
    var url = Uri.http(apiUrl, '/product/categories/');

    var response = await http.post(
      url,
      body: convert.jsonEncode(category.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 201) {
      print("Guardado");
    } else {
      throw Exception('Error al guardar ');
    }
  }

  Future<void> edit(int id, Category category) async {
    var url = Uri.http(apiUrl, '/product/categories/${id}/');

    var response = await http.put(
      url,
      body: convert.jsonEncode(category.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      print("Guardado");
    } else {
      throw Exception('Error al editar ');
    }
  }

  Future<void> delete(int id) async {
    var url = Uri.http(apiUrl, '/product/categories/${id}/');

    var response = await http.delete(url);
    if (response.statusCode == 204) {
      print("Eliminado");
    } else {
      throw Exception('Error al eliminar ');
    }
  }
}
