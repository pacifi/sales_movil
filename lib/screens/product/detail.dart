import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales/screens/product/form.dart';
import '../../providers/product_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final int idProduct;

  const ProductDetailScreen({super.key, required this.idProduct});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().getById(widget.idProduct);

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle de Producto"),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [Text("ID: "), Text(product.id.toString())]),
            Row(children: [Text("Nombre: "), Text(product.name)]),
            Row(children: [Text("Categoría: "), Text(product.category.name)]),
            Row(children: [Text("Precio: "), Text(product.price.toString())]),
            Row(children: [Text("Descripción: "), Text(product.description)]),
            Row(
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.red),
                  ),
                  onPressed: () async {
                    await context.read<ProductProvider>().delete(product.id);
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
                        builder: (context) => ProductFormScreen(product: product),
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