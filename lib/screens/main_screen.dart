import 'package:flutter/material.dart';
import 'package:sales/screens/category/list.dart';
import 'package:sales/screens/client/list.dart';
import 'package:sales/screens/product/list.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Ventas'),
        backgroundColor: Colors.orange,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.orange),
              child: Text(
                'Sistema de Ventas',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categorías'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const CategoryListScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Productos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Clientes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const ClientListScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Ventas'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Bienvenido al Sistema de Ventas'),
      ),
    );
  }
}