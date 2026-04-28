import 'package:flutter/material.dart';
import 'package:sales/models/category.dart';
import 'package:sales/screens/category/form.dart';
import 'package:sales/services/category_service.dart';

class CategoryDetailScreen extends StatefulWidget {
  final int idCategory;

  const CategoryDetailScreen({super.key, required this.idCategory});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late Future<Category> category;
  CategoryService _service = CategoryService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    category = _service.getById(widget.idCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle de Producto"),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder(
        future: category,
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
                                CategoryFormScreen(category: snapshot.data),
                          ),
                        );
                        setState(() {
                          category = _service.getById(widget.idCategory);
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
