import 'package:flutter/material.dart';
import 'package:sales/screens/category/list.dart';
import 'package:sales/screens/product/list.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sistema de Ventas"),
        backgroundColor: Colors.orange,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.orange),
              child: Text(
                "Sistema de Ventas",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: Icon(Icons.category),
              title: Text("Categorías"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => CategoryListScreen(),
                ));
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag),
              title: Text("Productos"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ProductListScreen(),
                ));
              },
            ),
            ListTile(
              leading: Icon(Icons.point_of_sale),
              title: Text("Ventas"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text("Bienvenido al Sistema de Ventas"),
      ),
    );
  }
}