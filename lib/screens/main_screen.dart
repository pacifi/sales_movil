import 'package:flutter/material.dart';
import 'package:sales/screens/category/list.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sistema de Ventas")),
      body: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryListScreen(),
                    ),
                  );
                },
                child: Text("Categorias"),
              ),
              ElevatedButton(onPressed: () {}, child: Text("Productos")),
            ],
          ),
          Row(
            children: [ElevatedButton(onPressed: () {}, child: Text("Ventas"))],
          ),
        ],
      ),
    );
  }
}
