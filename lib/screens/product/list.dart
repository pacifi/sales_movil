import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales/providers/product_provider.dart';
import 'package:sales/screens/product/detail.dart';
import 'package:sales/screens/product/form.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {

  @override
  void initState() {
    super.initState();
    context.read<ProductProvider>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;

    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Productos"),
        backgroundColor: Colors.orange,
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductFormScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              "${products[index].category.name} - ${products[index].name}",
            ),
            subtitle: Text(products[index].description),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    idProduct: products[index].id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}