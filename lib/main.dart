// lib/main.dart
//
// ProxyProvider conecta AuthProvider con los providers que dependen de él.
// ProxyProvider<A, B> significa: "crea B usando A, y recrea B cada vez que A notifica".
// Esto garantiza que si el token cambia, los providers descendientes
// también se actualizan automáticamente.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales/providers/auth_provider.dart';
import 'package:sales/providers/category_provider.dart';
import 'package:sales/providers/client_provider.dart';
import 'package:sales/providers/product_provider.dart';
import 'package:sales/router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider se registra primero — los demás dependen de él.
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // ProxyProvider lee el AuthProvider ya instanciado y lo pasa al constructor.
        // update se ejecuta cada vez que AuthProvider notifica cambios.
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (ctx) => CategoryProvider(
            ctx.read<AuthProvider>(),
          ),
          update: (ctx, auth, previous) => previous ?? CategoryProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (ctx) => ProductProvider(
            ctx.read<AuthProvider>(),
          ),
          update: (ctx, auth, previous) => previous ?? ProductProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ClientProvider>(
          create: (ctx) => ClientProvider(
            ctx.read<AuthProvider>(),
          ),
          update: (ctx, auth, previous) => previous ?? ClientProvider(auth),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return _AppWithRouter(authProvider: authProvider);
        },
      ),
    );
  }
}

class _AppWithRouter extends StatefulWidget {
  final AuthProvider authProvider;
  const _AppWithRouter({required this.authProvider});

  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter> {
  late final _router = createRouter(widget.authProvider);

  @override
  void initState() {
    super.initState();
    // Restaura sesión persistida en SharedPreferences al arrancar la app.
    widget.authProvider.tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}