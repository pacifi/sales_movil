# Guía de Laboratorio — Sesión 02 · Unidad 3
**Formularios Validados y Navegación con go_router**

| Campo | Detalle |
|-------|---------|
| Asignatura | Desarrollo de Aplicaciones Móviles |
| Docente | Ing. Bonnier Nilss Mamani Larico |
| Semestre | 2026-1 · Unidad 3 |
| Fecha | 14 de junio de 2026 |
| Duración | 2 horas de práctica |
| Stack | Flutter 3.41.0 · Dart 3.11.0 · go_router 17.3.0 · Provider 6.1.5 |

> **Objetivo:** Migrar el sistema de navegación del proyecto `sales` a `go_router` con un `AppShell` centralizado, y refactorizar los formularios con validación estructurada usando `Form` + `GlobalKey<FormState>` + `TextFormField`.

---

## Orden de Implementación

El sistema de navegación es la columna vertebral de la app. Se establece primero, antes de modificar cualquier pantalla. Una vez que el router está en su lugar, las pantallas se adaptan a él.

```
Paso 1 — Instalar go_router              pubspec.yaml
Paso 2 — Crear app_router.dart           GoRouter · ShellRoute · AppShell · rutas
Paso 3 — Modificar main.dart             MaterialApp → MaterialApp.router
Paso 4 — Modificar main_screen.dart      solo body, sin Scaffold
Paso 5 — Migrar las pantallas            Navigator → context.go · context.push · context.pop
Paso 6 — Formularios validados           Form · GlobalKey · TextFormField · validator
```

---

## ¿Por qué go_router?

Flutter ofrece dos modelos de navegación:

**Navigator — imperativo:** le dices *cómo* navegar paso a paso. El stack de pantallas es implícito y difícil de rastrear.

**go_router — declarativo:** le dices *a dónde* ir. El router resuelve cómo. Toda la navegación vive en una tabla de rutas central, igual que un router de Express o Django.

| Aspecto | Navigator | go_router |
|---------|-----------|-----------|
| Modelo | Imperativo — cómo navegar | Declarativo — a dónde ir |
| Navegación | `Navigator.push(MaterialPageRoute(...))` | `context.push('/ruta')` |
| Scaffold compartido | Repetido en cada pantalla | Un solo `AppShell` |
| Route guard (JWT) | Código duplicado en cada pantalla | `redirect` en un solo lugar |
| Deep linking | Manual y complejo | Incluido por defecto |

---

## Paso 1 — Instalar go_router

**Decisión técnica:** `go_router 17.x` es la versión compatible con Flutter 3.41 / Dart 3.11. Introduce `ShellRoute` estable y `state.uri.toString()` — ambos necesarios en esta sesión.

**Archivo:** `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.6.0
  provider: ^6.1.5+1
  sqflite: ^2.4.2+1
  path: ^1.9.1
  go_router: ^17.3.0    # ← agregar esta línea
```

**Terminal:**

```bash
flutter pub get
```

> **Verificación:** después de `flutter pub get`, el archivo `pubspec.lock` debe contener `go_router`. Si el comando falla por permisos o red, edita `pubspec.yaml` manualmente y vuelve a correr `flutter pub get`.

---

## Paso 2 — Crear app_router.dart

**Decisión técnica:** centralizar toda la navegación en un único archivo. Agregar un módulo nuevo = una ruta en este archivo. Sin tocar ninguna pantalla existente.

Crea el directorio `lib/router/` y dentro el archivo `app_router.dart`.

**Arquitectura — ShellRoute + AppShell:**

`ShellRoute` envuelve todas las rutas hijas con un widget compartido — `AppShell`. Este `AppShell` contiene el único `Scaffold` de la app con `AppBar` y `Drawer`. Cada ruta hija renderiza como el `body` de ese `Scaffold`.

```
ShellRoute (AppShell — único Scaffold)
├── /                      → MainScreenBody
├── /categories            → CategoryListScreen
│   ├── /categories/form   → CategoryFormScreen   (extra: Category?)
│   └── /categories/:id    → CategoryDetailScreen
├── /products              → ProductListScreen
│   ├── /products/form     → ProductFormScreen    (extra: Product?)
│   └── /products/:id      → ProductDetailScreen
└── /clients               → ClientListScreen
    └── /clients/form      → ClientFormScreen     (extra: Client?)
```

**Archivo:** `lib/router/app_router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sales/screens/category/detail.dart';
import 'package:sales/screens/category/form.dart';
import 'package:sales/screens/category/list.dart';
import 'package:sales/screens/client/form.dart';
import 'package:sales/screens/client/list.dart';
import 'package:sales/screens/main_screen.dart';
import 'package:sales/screens/product/detail.dart';
import 'package:sales/screens/product/form.dart';
import 'package:sales/screens/product/list.dart';

// Rutas raíz — muestran Drawer y hamburger en el AppBar.
// Las rutas que no estén aquí (form, detail) muestran botón atrás.
const _rootRoutes = ['/', '/categories', '/products', '/clients'];

// Mapea la ruta activa completa a su título de AppBar.
// Decisión: centralizar los títulos aquí en lugar de definirlos en cada pantalla.
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

// Instancia global del router.
// Se pasa a MaterialApp.router en main.dart como routerConfig.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(
        // Decisión: state.uri.toString() en lugar de state.matchedLocation.
        // state.matchedLocation devuelve la ruta del shell (/categories),
        // no la ruta hija activa (/categories/form).
        // state.uri.toString() devuelve la ruta completa activa — correcto.
        location: state.uri.toString(),
        child: child, // pantalla activa — renderiza como body del Scaffold
      ),
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
              // Path relativo sin / inicial.
              // go_router lo concatena con el padre: /categories + form = /categories/form
              path: 'form',
              builder: (context, state) => CategoryFormScreen(
                // state.extra transporta objetos entre rutas.
                // null = crear nueva categoría · Category = editar existente.
                // pathParameters solo acepta strings — extra es para objetos completos.
                category: state.extra as dynamic,
              ),
            ),
            GoRoute(
              // :id es un parámetro de URL capturado en state.pathParameters['id']
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
              builder: (context, state) => ProductFormScreen(
                product: state.extra as dynamic,
              ),
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
              builder: (context, state) => ClientFormScreen(
                client: state.extra as dynamic,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

// ─── AppShell — único Scaffold de toda la app ────────────────────────────────
//
// Decisión arquitectónica: un solo Scaffold centralizado en lugar de uno
// por pantalla. Ventajas:
//   - AppBar y Drawer definidos una sola vez
//   - Agregar un módulo = una línea en el Drawer, una ruta en appRouter
//   - En la próxima sesión: JWT logout y nombre de usuario se agregan aquí
//
// StatelessWidget: AppShell no gestiona estado propio.
// El estado sigue viviendo en los Providers registrados en main.dart.
class AppShell extends StatelessWidget {
  final String location; // ruta activa completa, ej: /categories/form
  final Widget child;    // pantalla activa — renderiza como body

  const AppShell({super.key, required this.location, required this.child});

  // true  → ruta raíz → muestra Drawer + hamburger
  // false → ruta hija → muestra botón atrás, sin Drawer
  bool get _isRoot => _rootRoutes.contains(location);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(location)),
        backgroundColor: Colors.orange,
        // Ruta raíz: leading null → Flutter pone el hamburger automáticamente.
        // Ruta hija: botón atrás manual con context.pop().
        leading: _isRoot
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        automaticallyImplyLeading: _isRoot,
      ),
      // Drawer solo en rutas raíz — en formularios y detalles no aparece
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
          _drawerItem(context, icon: Icons.home,        label: 'Inicio',     route: '/'),
          _drawerItem(context, icon: Icons.category,    label: 'Categorías', route: '/categories'),
          _drawerItem(context, icon: Icons.inventory_2, label: 'Productos',  route: '/products'),
          _drawerItem(context, icon: Icons.people,      label: 'Clientes',   route: '/clients'),
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
          // Decisión: el Drawer es una ruta de Navigator interno del Scaffold.
          // context.go() opera sobre go_router — un nivel superior.
          // Se cierra el Drawer con Navigator.pop ANTES de navegar con context.go.
          // Este orden garantiza que el árbol del Drawer se destruya limpiamente
          // antes de que go_router cambie la ruta activa.
          Navigator.of(context).pop(); // cierra el Drawer
          context.go(route);           // cambia la ruta en go_router
        }
      },
    );
  }
}
```

---

## Paso 3 — Modificar main.dart

**Decisión técnica:** `MaterialApp` usa `Navigator` internamente. `MaterialApp.router` delega el control de navegación al `routerConfig` — en este caso `appRouter`. El `MultiProvider` no cambia: los Providers viven por encima del sistema de navegación y todas las rutas tienen acceso a ellos.

**Archivo:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sales/providers/category_provider.dart';
import 'package:sales/providers/client_provider.dart';
import 'package:sales/providers/product_provider.dart';
import 'package:sales/router/app_router.dart'; // ← importar el router

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Los Providers no cambian — siguen registrados aquí.
        // Todas las rutas de go_router tienen acceso a ellos
        // porque el MultiProvider envuelve al MaterialApp.router.
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
      ],
      // MaterialApp.router en lugar de MaterialApp.
      // routerConfig recibe la instancia de GoRouter definida en app_router.dart.
      // Ya no se usa home: — el router define la pantalla inicial con initialLocation.
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}
```

---

## Paso 4 — Modificar main_screen.dart

**Decisión técnica:** `MainScreen` ya no necesita `Scaffold`, `AppBar` ni `Drawer`. El `AppShell` los provee. La clase se renombra a `MainScreenBody` para reflejar que solo es el contenido — el body que `AppShell` renderiza.

**Archivo:** `lib/screens/main_screen.dart`

```dart
import 'package:flutter/material.dart';

// MainScreenBody — solo el contenido de la pantalla de bienvenida.
// No necesita Scaffold, AppBar ni Drawer.
// AppShell provee todo eso automáticamente según la ruta activa.
class MainScreenBody extends StatelessWidget {
  const MainScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Bienvenido al Sistema de Ventas'),
    );
  }
}
```

---

## Paso 5 — Migrar las pantallas

**Decisión técnica:** con `AppShell` como único `Scaffold`, cada pantalla elimina su `Scaffold` propio. Las pantallas de lista mantienen un `Scaffold` sin `AppBar` — solo para el `FloatingActionButton`. Las pantallas de formulario y detalle retornan directamente su contenido.

**Tabla de equivalencias:**

| Navigator (antes) | go_router (ahora) | Cuándo |
|-------------------|-------------------|--------|
| `Navigator.push(context, MaterialPageRoute(builder: (_) => Screen()))` | `context.push('/ruta')` | Formularios y detalles — apila con botón atrás |
| `Navigator.push(..., extra: objeto)` | `context.push('/ruta', extra: objeto)` | Pasar objeto al editar |
| `Navigator.pop(context)` | `context.pop()` | Volver a la pantalla anterior |
| `Navigator.pushReplacement(...)` | `context.go('/ruta')` | Drawer — reemplaza el stack |

> **Diferencia clave:** `context.go()` reemplaza el stack — sin botón atrás — para navegar entre módulos desde el Drawer. `context.push()` apila — con botón atrás — para formularios y detalles.

---

### lib/screens/category/list.dart

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sales/providers/category_provider.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    // Scaffold sin AppBar — AppShell provee el AppBar.
    // El Scaffold aquí existe solo para el FloatingActionButton.
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        // context.push apila /categories/form — aparece botón atrás
        onPressed: () => context.push('/categories/form'),
        child: const Icon(Icons.add),
      ),
      body: categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  title: Text(cat.name),
                  subtitle: Text(cat.description),
                  // El id viaja en la URL — /categories/5
                  onTap: () => context.push('/categories/${cat.id}'),
                );
              },
            ),
    );
  }
}
```

---

### lib/screens/category/detail.dart

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';

class CategoryDetailScreen extends StatelessWidget {
  final int idCategory;

  const CategoryDetailScreen({super.key, required this.idCategory});

  @override
  Widget build(BuildContext context) {
    final category = context.watch<CategoryProvider>().getById(idCategory);

    // Sin Scaffold — AppShell provee Scaffold con botón atrás automático.
    // La pantalla retorna directamente su contenido.
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${category.id}'),
          Text('Nombre: ${category.name}'),
          Text('Descripción: ${category.description}'),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.red),
                ),
                onPressed: () async {
                  await context.read<CategoryProvider>().delete(category.id);
                  // context.pop() reemplaza Navigator.pop(context)
                  if (context.mounted) context.pop();
                },
                child: const Text('Eliminar',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => context.push(
                  '/categories/form',
                  extra: category, // objeto completo via state.extra
                ),
                child: const Text('Editar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

### lib/screens/category/form.dart

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sales/models/category.dart';
import '../../providers/category_provider.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category; // null = crear · Category = editar

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  // GlobalKey: vive en el estado del StatefulWidget — nunca en build().
  // Si viviera en build(), se recrearía en cada rebuild y perdería la referencia al Form.
  final _formKey = GlobalKey<FormState>();

  // Variables que recibirán los valores cuando se ejecute _formKey.currentState!.save()
  String _name = '';
  String _description = '';

  // Controla el estado del botón — lo deshabilita durante la operación async
  bool _isLoading = false;

  Future<void> _submit() async {
    // PASO 1: validate() ejecuta el validator de cada TextFormField.
    // Si alguno falla → mensaje bajo el campo → retorna false → no continúa.
    if (!_formKey.currentState!.validate()) return;

    // PASO 2: save() ejecuta el onSaved de cada TextFormField.
    // Copia los valores a _name y _description.
    // Solo se ejecuta porque validate() retornó true.
    _formKey.currentState!.save();

    // PASO 3: construir el objeto y llamar al Provider.
    // El formulario no conoce al Provider — solo extrae valores.
    setState(() => _isLoading = true);
    try {
      final provider = context.read<CategoryProvider>();
      if (widget.category == null) {
        // Crear — id 0, el backend asigna el id real
        await provider.save(Category(0, _name, _description));
      } else {
        // Editar — mantener el id existente
        await provider.edit(
          widget.category!.id,
          Category(widget.category!.id, _name, _description),
        );
      }
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sin Scaffold — AppShell provee el Scaffold con botón atrás.
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Form(
        key: _formKey, // conecta el Form con la GlobalKey
        // onUserInteraction: valida cuando el usuario abandona el campo.
        // No espera a que presione el botón Guardar.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            TextFormField(
              // initialValue reemplaza al TextEditingController.
              // Si estamos editando, muestra el valor actual.
              // Si estamos creando, muestra vacío.
              initialValue: widget.category?.name ?? '',
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                // null → válido · String → mensaje de error bajo el campo
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
              // onSaved se ejecuta cuando se llama _formKey.currentState!.save()
              onSaved: (value) => _name = value!.trim(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.category?.description ?? '',
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La descripción es requerida';
                }
                return null;
              },
              onSaved: (value) => _description = value!.trim(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // null deshabilita el botón visualmente durante la carga
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.category == null ? 'Crear' : 'Editar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### lib/screens/product/list.dart

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sales/providers/product_provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductProvider>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/form'),
        child: const Icon(Icons.add),
      ),
      body: products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text('${product.category.name} — ${product.name}'),
                  subtitle: Text(product.description),
                  onTap: () => context.push('/products/${product.id}'),
                );
              },
            ),
    );
  }
}
```

---

### lib/screens/product/detail.dart

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final int idProduct;

  const ProductDetailScreen({super.key, required this.idProduct});

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().getById(idProduct);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${product.id}'),
          Text('Nombre: ${product.name}'),
          Text('Categoría: ${product.category.name}'),
          Text('Precio: S/ ${product.price}'),
          Text('Descripción: ${product.description}'),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.red),
                ),
                onPressed: () async {
                  await context.read<ProductProvider>().delete(product.id);
                  if (context.mounted) context.pop();
                },
                child: const Text('Eliminar',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => context.push('/products/form', extra: product),
                child: const Text('Editar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

### lib/screens/product/form.dart

**Decisión técnica — DropdownButtonFormField con objetos:**

`DropdownButtonFormField` compara el `value` con los ítems usando `==`. Como `Category` no implementa `==` ni `hashCode`, Dart compara por referencia de objeto. Las instancias que vienen de la API en cada `loadAll()` son objetos distintos en memoria aunque tengan el mismo `id`, causando que Flutter no encuentre el ítem seleccionado.

**Solución:** guardar solo el `id` (`int?`) en el estado. En cada `build()`, resolver la instancia real buscando por `id` dentro de la lista actual del provider. Así el `value` del dropdown y el ítem son siempre la misma instancia en memoria.

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String _name = '';
  String _description = '';
  double _price = 0.0;

  // Guardamos solo el id — NO la instancia de Category.
  // Esto evita el problema de comparación por referencia en DropdownButtonFormField.
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().loadAll();
    // Inicializamos con el id de la categoría del producto (si estamos editando)
    _selectedCategoryId = widget.product?.category.id;
  }

  Future<void> _submit() async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Resolvemos la instancia real desde la lista actual del provider
    final categories = context.read<CategoryProvider>().categories;
    final selectedCategory = categories.firstWhere(
      (cat) => cat.id == _selectedCategoryId,
    );

    setState(() => _isLoading = true);
    try {
      final provider = context.read<ProductProvider>();
      if (widget.product == null) {
        await provider.save(
          Product(0, _name, _price, _description, selectedCategory),
        );
      } else {
        await provider.edit(
          widget.product!.id,
          Product(widget.product!.id, _name, _price, _description, selectedCategory),
        );
      }
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    // Resolvemos la instancia en cada build() a partir del id guardado.
    // where().isNotEmpty previene que firstWhere falle si la lista aún está cargando.
    final selectedCategory = _selectedCategoryId == null
        ? null
        : categories.where((c) => c.id == _selectedCategoryId).isNotEmpty
            ? categories.firstWhere((c) => c.id == _selectedCategoryId)
            : null;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            if (categories.isEmpty)
              const CircularProgressIndicator()
            else
              DropdownButtonFormField<Category>(
                // value es la instancia de la lista actual — misma referencia que el ítem
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        ))
                    .toList(),
                // Al cambiar, guardamos solo el id — no la instancia
                onChanged: (cat) =>
                    setState(() => _selectedCategoryId = cat?.id),
                validator: (value) =>
                    value == null ? 'Selecciona una categoría' : null,
              ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.product?.name ?? '',
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.trim().length < 2) return 'Mínimo 2 caracteres';
                return null;
              },
              onSaved: (value) => _name = value!.trim(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.product?.price.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixText: 'S/ ',
                border: OutlineInputBorder(),
              ),
              // Teclado numérico con soporte para decimales
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El precio es requerido';
                }
                // tryParse retorna null si el texto no es un número válido
                final parsed = double.tryParse(value.trim());
                if (parsed == null) return 'Ingresa un número válido';
                if (parsed < 0) return 'El precio no puede ser negativo';
                return null;
              },
              onSaved: (value) => _price = double.parse(value!.trim()),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.product?.description ?? '',
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La descripción es requerida';
                }
                return null;
              },
              onSaved: (value) => _description = value!.trim(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.product == null ? 'Crear' : 'Editar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### lib/screens/client/list.dart

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sales/providers/client_provider.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    context.read<ClientProvider>().loadAll();
  }

  Future<void> _sincronizar() async {
    setState(() => _syncing = true);
    final result = await context.read<ClientProvider>().sincronizar();
    if (!mounted) return;
    setState(() => _syncing = false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sincronización completa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Creados: ${result['sincronizados']}'),
            Text('🔄 Actualizados: ${result['actualizados']}'),
            Text('⚠️ Ya existían: ${result['duplicados']}'),
            Text('❌ Errores: ${result['errores']}'),
          ],
        ),
        actions: [
          TextButton(
            // context.pop() cierra el diálogo — mismo comportamiento que Navigator.pop
            onPressed: () => context.pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarEliminar(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final clients = context.watch<ClientProvider>().clients;

    return Scaffold(
      // Decisión: dos FABs en Column — sync y agregar.
      // heroTag requerido cuando hay más de un FloatingActionButton en el mismo Scaffold.
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'sync',
            onPressed: _syncing ? null : _sincronizar,
            backgroundColor: Colors.blue,
            child: _syncing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sync),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => context.push('/clients/form'),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: clients.isEmpty
          ? const Center(child: Text('No hay clientes registrados'))
          : ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return Dismissible(
                  key: Key(client.id.toString()),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmarEliminar(context),
                  onDismissed: (_) async {
                    await context.read<ClientProvider>().delete(client);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: Icon(
                      client.isSynced ? Icons.cloud_done : Icons.cloud_off,
                      color: client.isSynced ? Colors.green : Colors.red,
                    ),
                    title: Text(client.name),
                    subtitle: Text(client.documentNumber),
                    // Pasar el objeto completo via extra para editar
                    onTap: () => context.push('/clients/form', extra: client),
                  ),
                );
              },
            ),
    );
  }
}
```

---

## Paso 6 — Formularios Validados

### ¿Por qué Form + GlobalKey + TextFormField?

El patrón anterior usaba `TextEditingController` con validación manual dentro del botón. El nuevo patrón resuelve tres problemas concretos:

| Problema anterior | Solución nueva |
|-------------------|----------------|
| Sin mensaje de error bajo el campo | `TextFormField` muestra el error automáticamente |
| Validación mezclada con lógica de envío | Flujo limpio: `validate()` → `save()` → Provider |
| No hay forma de validar todos los campos a la vez | `_formKey.currentState!.validate()` los coordina |

### lib/screens/client/form.dart

Este es el formulario que el estudiante aplica de forma autónoma. El patrón es idéntico a `CategoryFormScreen`.

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sales/models/client.dart';
import 'package:sales/providers/client_provider.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client; // null = crear · Client = editar

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String _name = '';
  String _documentNumber = '';

  Future<void> _submit() async {
    // validate() — ejecuta todos los validators
    if (!_formKey.currentState!.validate()) return;

    // save() — ejecuta todos los onSaved, copia valores a _name y _documentNumber
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final provider = context.read<ClientProvider>();
      if (widget.client == null) {
        // Crear — id 0, isSynced false, serverId null
        await provider.save(Client(0, _name, _documentNumber, false, null));
      } else {
        // Editar — mantener id y serverId, marcar como no sincronizado
        await provider.edit(
          widget.client!.id,
          Client(
            widget.client!.id,
            _name,
            _documentNumber,
            false, // marcamos como pendiente de sincronización
            widget.client!.serverId,
          ),
        );
      }
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.client != null;

    // Sin Scaffold — AppShell provee el Scaffold con botón atrás
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            TextFormField(
              initialValue: widget.client?.name ?? '',
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.trim().length < 2) return 'Mínimo 2 caracteres';
                return null;
              },
              onSaved: (value) => _name = value!.trim(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.client?.documentNumber ?? '',
              decoration: const InputDecoration(
                labelText: 'Número de documento',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El número de documento es requerido';
                }
                if (value.trim().length < 8) {
                  return 'Debe tener al menos 8 dígitos';
                }
                // int.tryParse retorna null si el texto contiene letras
                if (int.tryParse(value.trim()) == null) {
                  return 'Solo se permiten números';
                }
                return null;
              },
              onSaved: (value) => _documentNumber = value!.trim(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Editar' : 'Crear'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Estructura final del proyecto

```
lib/
├── config/
│   └── app_config.dart
├── database/
│   └── database_helper.dart
├── models/
│   ├── category.dart
│   ├── product.dart
│   └── client.dart
├── providers/
│   ├── category_provider.dart
│   ├── product_provider.dart
│   └── client_provider.dart
├── router/
│   └── app_router.dart          ← NUEVO: GoRouter + ShellRoute + AppShell
├── screens/
│   ├── main_screen.dart         MainScreenBody — solo body
│   ├── category/
│   │   ├── list.dart            Scaffold sin AppBar + context.push
│   │   ├── detail.dart          Padding directo + context.pop/push
│   │   └── form.dart            Form + GlobalKey + TextFormField
│   ├── product/
│   │   ├── list.dart            Scaffold sin AppBar + context.push
│   │   ├── detail.dart          Padding directo
│   │   └── form.dart            + fix DropdownButtonFormField (int? id)
│   └── client/
│       ├── list.dart            Scaffold sin AppBar + 2 FABs + Dismissible
│       └── form.dart            Form + GlobalKey + TextFormField
├── services/
│   ├── category_service.dart    sin cambios
│   ├── product_service.dart     sin cambios
│   └── client_service.dart      sin cambios
└── main.dart                    MaterialApp.router + routerConfig: appRouter
```

---

## Checklist de Verificación

- [ ] `flutter pub get` ejecutado después de agregar `go_router`
- [ ] App compila sin errores
- [ ] Drawer abre y cierra correctamente en todas las pantallas raíz
- [ ] Navegar desde el Drawer cambia la pantalla sin apilar
- [ ] Botón atrás aparece en formularios y detalles
- [ ] Botón atrás NO aparece en pantallas raíz (muestra hamburger)
- [ ] Category: crear, editar y eliminar funcionan
- [ ] Product: crear, editar y eliminar funcionan — dropdown correcto
- [ ] Client: crear, editar, eliminar y sincronizar funcionan
- [ ] Validaciones muestran error bajo el campo — no en SnackBar ni diálogo
- [ ] Botón Guardar se deshabilita durante la operación async

---

## Próxima Sesión — JWT + Route Guard

Con `go_router` en su lugar, la siguiente sesión agrega autenticación JWT. El route guard se define en un solo lugar y protege todas las rutas automáticamente:

```dart
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final token = prefs.getString('token');
    final enLogin = state.uri.toString() == '/login';
    if (token == null && !enLogin) return '/login'; // sin token → login
    if (token != null && enLogin)  return '/';       // con token → app
    return null;                                     // dejar pasar
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    ShellRoute(...), // el shell actual sin cambios
  ],
);
```

---

## Referencias

| Recurso | URL |
|---------|-----|
| go_router | https://pub.dev/packages/go_router |
| ShellRoute | https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html |
| Form widget | https://api.flutter.dev/flutter/widgets/Form-class.html |
| GlobalKey | https://api.flutter.dev/flutter/widgets/GlobalKey-class.html |
| TextFormField | https://api.flutter.dev/flutter/material/TextFormField-class.html |
| AutovalidateMode | https://api.flutter.dev/flutter/widgets/AutovalidateMode.html |
| GoRouter navigation | https://docs.flutter.dev/ui/navigation |