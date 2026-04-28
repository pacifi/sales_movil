// /lib/services/category_service
import 'package:sales/models/category.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class CategoryService {
  Future<List<Category>> all() async {
    var url = Uri.http('192.168.18.114:8000', '/product/categories/');
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
    var url = Uri.http('192.168.18.114:8000', '/product/categories/$id/');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body) as dynamic;

      Category category = Category.fromJson(jsonResponse);

      return category;
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

}
