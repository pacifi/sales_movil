import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';

class CategoryDetailScreen extends StatelessWidget {
  final int idCategory;

  const CategoryDetailScreen({super.key, required this.idCategory});

  @override
  Widget build(BuildContext context) {
    final category = context.watch<CategoryProvider>().getById(idCategory);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${category.id}'),
          Text('Nombre: ${category.name}'),
          Text('Descripción: ${category.description}'),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.red),
                ),
                onPressed: () async {
                  await context.read<CategoryProvider>().delete(category.id);
                  if (context.mounted) context.pop();
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => context.push(
                  '/categories/form',
                  extra: category,
                ),
                child: const Text('Editar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}