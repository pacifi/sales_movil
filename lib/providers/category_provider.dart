// lib/providers/category_provider.dart
//
// Cambio: recibe el AuthProvider en el constructor para poder leer
// el token actual antes de cada operación de red.
// El token no se guarda como campo — se lee en el momento de uso
// para garantizar que siempre sea el valor más reciente.

import 'package:flutter/cupertino.dart';
import 'package:sales/models/category.dart';
import 'package:sales/providers/auth_provider.dart';
import 'package:sales/services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  final CategoryService categoryService = CategoryService();

  // Referencia al AuthProvider para obtener el token en cada operación.
  final AuthProvider _authProvider;

  CategoryProvider(this._authProvider);

  // Obtiene el token actual. Si es null lanza excepción —
  // esto no debería ocurrir porque el redirect guard protege todas las rutas.
  String get _token => _authProvider.token!;

  Future<void> loadAll() async {
    _categories = await categoryService.all(_token);
    notifyListeners();
  }

  Future<void> save(Category category) async {
    await categoryService.save(category, _token);
    await loadAll();
  }

  Future<void> edit(int id, Category category) async {
    await categoryService.edit(id, category, _token);
    await loadAll();
  }

  Category getById(int id) {
    return _categories.firstWhere((c) => c.id == id);
  }

  Future<void> delete(int id) async {
    await categoryService.delete(id, _token);
    await loadAll();
  }
}