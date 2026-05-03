import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales/models/category.dart';
import 'package:sales/screens/category/form.dart';

import '../../providers/category_provider.dart';

class CategoryDetailScreen extends StatefulWidget {
  final int idCategory;

  const CategoryDetailScreen({super.key, required this.idCategory});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final category = context.watch<CategoryProvider>().getById(
      widget.idCategory,
    );

/*
    final categories = context.watch<CategoryProvider>().categories;

    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Detalle de Categorias"),
          backgroundColor: Colors.orange,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final category = context.read<CategoryProvider>().getById(widget.idCategory);
*/

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle de Categorias"),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [Text("ID: "), Text(category.id.toString())]),
            Row(children: [Text("Nombre: "), Text(category.name)]),
            Row(children: [Text("Descripción: "), Text(category.description)]),
            Row(
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.red),
                  ),
                  onPressed: () async {
                    await context.read<CategoryProvider>().delete(category.id);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Eliminar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CategoryFormScreen(category: category),
                      ),
                    );
                  },
                  child: Text("Editar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}