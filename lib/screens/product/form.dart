import 'package:flutter/material.dart';
import 'package:sales/models/product.dart';
import 'package:sales/services/product_service.dart';

import '../../models/category.dart';
import '../../services/category_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final CategoryService _serviceCategory = CategoryService();
  late Future<List<Category>> categories;

  final ProductService _service = ProductService();

  TextEditingController controllerName = TextEditingController();
  TextEditingController controllerDescription = TextEditingController();
  TextEditingController controllerPrice = TextEditingController();
  Category? selectedCategory;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    categories = _serviceCategory.all();

    final product = widget.product;
    if (product != null) {
      controllerName.text = product.name;
      controllerDescription.text = product.description;
      controllerPrice.text = product.price.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Formulario"), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            FutureBuilder(
              future: categories,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                if (selectedCategory == null && snapshot.hasData && widget.product != null) {
                  selectedCategory = snapshot.data!.firstWhere(
                        (cat) => cat.id == widget.product!.category.id,
                    orElse: () => snapshot.data!.first,
                  );
                }

                return DropdownButton(
                  value: selectedCategory,
                  items: snapshot.data!
                      .map(
                        (cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat.name)),
                      )
                      .toList(),
                  onChanged: (cat) => setState(() {
                    selectedCategory = cat;
                  }),
                );
              },
            ),
            TextField(
              controller: controllerName,
              decoration: InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: controllerPrice,
              decoration: InputDecoration(
                labelText: "Precio",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: controllerDescription,
              decoration: InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (widget.product == null) {
                  Product productAdd = Product(
                    0,
                    controllerName.text,
                    double.parse(controllerPrice.text),
                    controllerDescription.text,
                    selectedCategory!,
                  );
                  await _service.save(productAdd);
                } else {
                  Product productUpd = Product(
                    widget.product!.id,
                    controllerName.text,
                    double.parse(controllerPrice.text),
                    controllerDescription.text,
                    selectedCategory!,
                  );
                  await _service.edit(widget.product!.id, productUpd);
                }

                Navigator.pop(context);
              },
              child: Text(widget.product == null ? "Crear" : "Editar"),
            ),
          ],
        ),
      ),
    );
  }
}
