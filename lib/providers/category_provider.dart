import 'package:flutter/cupertino.dart';
import 'package:sales/models/category.dart';
import 'package:sales/services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];

  List<Category> get categories => _categories;

  CategoryService categoryService = CategoryService();

  Future<void> loadAll() async {
    _categories = await categoryService.all();
    notifyListeners();
  }

  Future<void> save(Category category) async {
    await categoryService.save(category);
    await loadAll();
  }

  Future<void> edit(int id, Category category) async {
    await categoryService.edit(id, category);
    await loadAll();
  }

  Category getById(int id) {
    return _categories.firstWhere((c) => c.id == id);
  }

  Future<void> delete(int id) async {
    await categoryService.delete(id);
    await loadAll();
  }
}
