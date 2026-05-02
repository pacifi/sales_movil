import 'package:flutter/material.dart';
import 'package:sales/screens/product/form.dart';
import 'package:sales/services/product_service.dart';

import '../../models/product.dart';
import 'detail.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _service = ProductService();
  late Future<List<Product>> products;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    products = _service.all();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Productos"),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder(
        future: products,
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
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  "${snapshot.data![index].category.name}  - ${snapshot.data![index].name}",
                ),
                subtitle: Text(snapshot.data![index].description),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        idProduct: snapshot.data![index].id,
                      ),
                    ),
                  );
                  setState(() {
                    products = _service.all();
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductFormScreen()),
          );
          setState(() {
            products = _service.all();
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
