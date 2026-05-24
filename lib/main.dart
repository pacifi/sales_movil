import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales/providers/category_provider.dart';
import 'package:sales/providers/client_provider.dart';
import 'package:sales/providers/product_provider.dart';
import 'package:sales/screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider()),
        ChangeNotifierProvider(create: (context) => ClientProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
      ),
    );
  }
}