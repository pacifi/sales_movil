import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:sales/models/category.dart";
import "../../providers/category_provider.dart";

class CategoryFormScreen extends StatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  TextEditingController controllerName = TextEditingController();
  TextEditingController controllerDescription = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final category = widget.category;
    if (category != null) {
      controllerName.text = category.name;
      controllerDescription.text = category.description;
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
            TextField(
              controller: controllerName,
              decoration: InputDecoration(
                labelText: "Nombre",
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
                if (widget.category == null) {
                  await context.read<CategoryProvider>().save(
                    Category(
                      0,
                      controllerName.text,
                      controllerDescription.text,
                    ),
                  );
                } else {
                  await context.read<CategoryProvider>().edit(
                    widget.category!.id,
                    Category(
                      widget.category!.id,
                      controllerName.text,
                      controllerDescription.text,
                    ),
                  );
                }
                Navigator.pop(context);
              },
              child: Text(widget.category == null ? "Crear" : "Editar"),
            ),
          ],
        ),
      ),
    );
  }
}
