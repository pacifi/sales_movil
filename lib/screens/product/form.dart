import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales/models/category.dart';
import 'package:sales/models/product.dart';
import 'package:sales/providers/category_provider.dart';
import 'package:sales/providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  TextEditingController controllerName = TextEditingController();
  TextEditingController controllerDescription = TextEditingController();
  TextEditingController controllerPrice = TextEditingController();
  Category? selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().loadAll();

    final product = widget.product;
    if (product != null) {
      controllerName.text = product.name;
      controllerDescription.text = product.description;
      controllerPrice.text = product.price.toString();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedCategory == null) {
      final categories = context.read<CategoryProvider>().categories;
      if (categories.isNotEmpty) {
        selectedCategory = widget.product != null
            ? categories.firstWhere(
              (cat) => cat.id == widget.product!.category.id,
          orElse: () => categories.first,
        )
            : categories.first;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text("Formulario de Producto"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            if (categories.isEmpty)
              CircularProgressIndicator()
            else
              DropdownButton(
                value: selectedCategory,
                items: categories
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat.name),
                ))
                    .toList(),
                onChanged: (cat) => setState(() {
                  selectedCategory = cat;
                }),
              ),
            SizedBox(height: 10),
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
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: selectedCategory == null
                  ? null
                  : () async {
                if (widget.product == null) {
                  await context.read<ProductProvider>().save(
                    Product(
                      0,
                      controllerName.text,
                      double.parse(controllerPrice.text),
                      controllerDescription.text,
                      selectedCategory!,
                    ),
                  );
                } else {
                  await context.read<ProductProvider>().edit(
                    widget.product!.id,
                    Product(
                      widget.product!.id,
                      controllerName.text,
                      double.parse(controllerPrice.text),
                      controllerDescription.text,
                      selectedCategory!,
                    ),
                  );
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