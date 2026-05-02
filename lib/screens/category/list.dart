import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales/providers/category_provider.dart';
import 'package:sales/screens/category/detail.dart';
import 'package:sales/screens/category/form.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {

  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Categorias"),
        backgroundColor: Colors.orange,
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CategoryFormScreen()),
          );
          context.read<CategoryProvider>().loadAll();
        },
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(categories[index].name),
            subtitle: Text(categories[index].description),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(
                    idCategory: categories[index].id,
                  ),
                ),
              );
              context.read<CategoryProvider>().loadAll();
            },
          );
        },
      ),
    );
  }
}