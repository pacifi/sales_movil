import 'package:flutter/material.dart';
import 'package:sales/models/product.dart';
import 'package:sales/screens/product/form.dart';
import 'package:sales/services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final int idProduct;

  const ProductDetailScreen({super.key, required this.idProduct});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product> product;
  final ProductService _service = ProductService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    product = _service.getById(widget.idProduct);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle de Products"),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder(
        future: product,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 40),
                  SizedBox(height: 10),
                  Text("Ocurrio un errpr ${snapshot.error}"),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [Text("ID: "), Text(snapshot.data!.id.toString())],
                ),
                Row(children: [Text("Nombre: "), Text(snapshot.data!.name)]),
                Row(
                  children: [
                    Text("Descripción: "),
                    Text(snapshot.data!.description),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.red),
                      ),
                      onPressed: () async {
                        await _service.delete(snapshot.data!.id);
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
                                ProductFormScreen(product: snapshot.data),
                          ),
                        );
                        setState(() {
                          product = _service.getById(widget.idProduct);
                        });
                      },
                      child: Text("Editar"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
