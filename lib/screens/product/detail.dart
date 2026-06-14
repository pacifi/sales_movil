import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final int idProduct;

  const ProductDetailScreen({super.key, required this.idProduct});

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().getById(idProduct);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${product.id}'),
          Text('Nombre: ${product.name}'),
          Text('Categoría: ${product.category.name}'),
          Text('Precio: S/ ${product.price}'),
          Text('Descripción: ${product.description}'),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.red),
                ),
                onPressed: () async {
                  await context.read<ProductProvider>().delete(product.id);
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
                  '/products/form',
                  extra: product,
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