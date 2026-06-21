// lib/router/app_router.dart
//
// Tabla central de rutas de la app con go_router.
// La adición principal respecto a la versión anterior es:
// - Ruta /login fuera del ShellRoute (sin Drawer ni AppBar compartido).
// - redirect guard: intercepta toda navegación y redirige al login si no hay sesión.
// - refreshListenable: conecta AuthProvider con go_router para que el guard
//   se re-evalúe automáticamente cuando cambia el estado de autenticación.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';              // ← agrega este
import 'package:sales/providers/auth_provider.dart';
import 'package:sales/screens/category/detail.dart';
import 'package:sales/screens/category/form.dart';
import 'package:sales/screens/category/list.dart';
import 'package:sales/screens/client/form.dart';
import 'package:sales/screens/client/list.dart';
import 'package:sales/screens/login/login_screen.dart';
import 'package:sales/screens/main_screen.dart';
import 'package:sales/screens/product/detail.dart';
import 'package:sales/screens/product/form.dart';
import 'package:sales/screens/product/list.dart';

const _rootRoutes = ['/', '/categories', '/products', '/clients'];

String _titleFor(String location) {
  if (location == '/') return 'Sistema de Ventas';
  if (location == '/categories') return 'Lista de Categorías';
  if (location.startsWith('/categories/form')) return 'Formulario de Categoría';
  if (location.startsWith('/categories/')) return 'Detalle de Categoría';
  if (location == '/products') return 'Lista de Productos';
  if (location.startsWith('/products/form')) return 'Formulario de Producto';
  if (location.startsWith('/products/')) return 'Detalle de Producto';
  if (location == '/clients') return 'Lista de Clientes';
  if (location.startsWith('/clients/form')) return 'Formulario de Cliente';
  return 'Sales App';
}

// Recibe el AuthProvider para que el redirect guard pueda consultarlo.
// Se instancia en main.dart una vez que el provider ya existe en el árbol.
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',

    // refreshListenable conecta go_router con AuthProvider.
    // Cada vez que AuthProvider llama notifyListeners() (login/logout),
    // go_router re-evalúa el redirect automáticamente.
    refreshListenable: authProvider,

    // El redirect se ejecuta antes de cada navegación.
    // Es el único punto donde se decide si el usuario puede acceder a una ruta.
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == '/login';

      // Si no está autenticado y no va al login, redirige al login.
      if (!isAuthenticated && !isGoingToLogin) return '/login';

      // Si ya está autenticado e intenta ir al login, redirige al home.
      if (isAuthenticated && isGoingToLogin) return '/';

      // En cualquier otro caso, permite la navegación normalmente.
      return null;
    },

    routes: [
      // /login vive FUERA del ShellRoute — tiene su propio Scaffold independiente.
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ShellRoute envuelve todas las rutas protegidas con AppShell.
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.toString(), child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const MainScreenBody(),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoryListScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (context, state) =>
                    CategoryFormScreen(category: state.extra as dynamic),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => CategoryDetailScreen(
                  idCategory: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductListScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (context, state) =>
                    ProductFormScreen(product: state.extra as dynamic),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => ProductDetailScreen(
                  idProduct: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientListScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (context, state) =>
                    ClientFormScreen(client: state.extra as dynamic),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ─── AppShell — único Scaffold de la app ─────────────────────
class AppShell extends StatelessWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  bool get _isRoot => _rootRoutes.contains(location);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(location)),
        backgroundColor: Colors.orange,
        leading: _isRoot
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        automaticallyImplyLeading: _isRoot,
        // Botón de logout en el AppBar — disponible en toda la app.
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              // Lee el AuthProvider y ejecuta logout.
              // go_router detecta isAuthenticated = false y redirige al login.
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      drawer: _isRoot ? _buildDrawer(context) : null,
      body: child,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.orange),
            child: Text(
              'Sales App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _drawerItem(context, icon: Icons.home, label: 'Inicio', route: '/'),
          _drawerItem(
            context,
            icon: Icons.category,
            label: 'Categorías',
            route: '/categories',
          ),
          _drawerItem(
            context,
            icon: Icons.inventory_2,
            label: 'Productos',
            route: '/products',
          ),
          _drawerItem(
            context,
            icon: Icons.people,
            label: 'Clientes',
            route: '/clients',
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = location == route;

    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.orange : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.orange : null,
        ),
      ),
      selected: isActive,
      onTap: () {
        if (!isActive) {
          Navigator.of(context).pop();
          context.go(route);
        }
      },
    );
  }
}