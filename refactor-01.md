# Guía de Laboratorio — Sesión 02 · Unidad 3
**Formularios Validados y Navegación con go_router**

| Campo | Detalle |
|-------|---------|
| Asignatura | Desarrollo de Aplicaciones Móviles |
| Docente | Ing. Bonnier Nilss Mamani Larico |
| Semestre | 2026-1 · Unidad 3 |
| Fecha | 14 de junio de 2026 |
| Duración | 2 horas de práctica |
| Stack | Flutter 3.41.0 · Dart 3.11.0 · go_router 17.3.0 |

> **Objetivo:** Refactorizar los formularios del proyecto `sales` con validación estructurada, y migrar el sistema de navegación a `go_router` con un `AppShell` centralizado.

---

## Orden de Implementación

```
1. Formularios validados        Form · GlobalKey · TextFormField · validator
2. Instalar go_router           pubspec.yaml · flutter pub get
3. Crear app_router.dart        GoRouter · ShellRoute · AppShell · rutas
4. Modificar main.dart          MaterialApp → MaterialApp.router
5. Migrar las pantallas         Navigator → context.go · context.push · context.pop
```

---

## Parte 1 — Formularios Validados

### ¿Por qué cambiar de TextField a TextFormField?

El patrón anterior usaba `TextEditingController` + validación manual dentro del botón. Esto tiene tres problemas:

- El usuario no ve qué campo falló ni por qué
- La validación está mezclada con la lógica de envío
- No hay forma de validar todos los campos a la vez

El nuevo patrón usa el trío **`Form`** + **`GlobalKey<FormState>`** + **`TextFormField`**, que resuelve los tres problemas con un flujo limpio y consistente.

### El trío

| Widget / Clase | Responsabilidad |
|----------------|-----------------|
| `Form` | Agrupa los campos y los coordina. Widget invisible — solo coordina. |
| `GlobalKey<FormState>` | Llave que da acceso al estado del `Form` desde `_submit()`. Vive en el estado del `StatefulWidget`. |
| `TextFormField` | Campo con `validator` (reglas) y `onSaved` (extracción del valor). |

### El flujo de tres pasos

```dart
Future<void> _submit() async {
  // PASO 1 — VALIDATE
  // Ejecuta el validator de cada TextFormField.
  // Si alguno falla → mensaje bajo el campo → retorna false → no continúa.
  if (!_formKey.currentState!.validate()) return;

  // PASO 2 — SAVE
  // Ejecuta onSaved de cada campo.
  // Copia cada valor a su variable local (_name, _description, etc.)
  // Solo se ejecuta si validate() retornó true.
  _formKey.currentState!.save();

  // PASO 3 — SUBMIT
  // Con los valores ya extraídos, construir el objeto y llamar al Provider.
  // El formulario no conoce al Provider — solo extrae valores.
  setState(() => _isLoading = true);
  try {
    await context.read<CategoryProvider>().save(
      Category(0, _name, _description),
    );
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
```

---

### Paso 1.1 — Refactorizar CategoryFormScreen

**Archivo:** `lib/screens/category/form.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // se agrega en Parte 2
import 'package:provider/provider.dart';
import 'package:sales/models/category.dart';
import '../../providers/category_provider.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category; // null = crear, not null = editar

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  // GlobalKey: vive aquí para no recrearse en cada build()
  final _formKey = GlobalKey<FormState>();

  // Variables que recibirán los valores de onSaved
  String _name = '';
  String _description = '';

  // Controla el estado del botón durante la operación async
  bool _isLoading = false;

  Future<void> _submit() async {
    // validate() ejecuta todos los validators — retorna false si alguno falla
    if (!_formKey.currentState!.validate()) return;

    // save() ejecuta todos los onSaved — copia valores a _name y _description
    _formKey.currentState!.save();

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
      // context.pop() en Parte 2 reemplaza Navigator.pop(context)
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
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Form(
        key: _formKey, // conecta el Form con la GlobalKey
        // onUserInteraction: valida cuando el usuario sale del campo
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            TextFormField(
              // initialValue reemplaza al TextEditingController
              initialValue: widget.category?.name ?? '',
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                // null = válido · String = mensaje de error bajo el campo
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null; // válido
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
                // null deshabilita el botón mientras carga
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

### Paso 1.2 — Refactorizar ProductFormScreen

**Archivo:** `lib/screens/product/form.dart`

El formulario de Product tiene tres campos adicionales y un `DropdownButtonFormField`.

> **⚠️ Punto crítico — DropdownButtonFormField con objetos:**
>
> `DropdownButtonFormField` compara el `value` con los ítems usando `==`. Como `Category` no implementa `==`, Dart compara por referencia de objeto. Si guardas la instancia de `Category`, las instancias que vienen de la API después de cada `loadAll()` son objetos distintos en memoria y el dropdown falla con:
> ```
> There should be exactly one item with [DropdownButton]'s value.
> ```
>
> **Solución:** guardar solo el `id` (`int?`). En cada `build()`, resolver la instancia real buscando por `id` dentro de la lista actual del provider. Así el `value` y el ítem son siempre la misma instancia en memoria.

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // se agrega en Parte 2
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

  // Guardamos solo el id — NO la instancia de Category
  // Esto evita el bug de comparación por referencia en el DropdownButtonFormField
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().loadAll();
    // Inicializamos con el id de la categoría del producto (si estamos editando)
    _selectedCategoryId = widget.product?.category.id;
  }

  Future<void> _submit() async {
    // Validar dropdown manualmente — no forma parte del Form
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Resolver la instancia real desde la lista actual del provider
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
    // where().isNotEmpty previene el firstWhere fallando si la lista aún carga.
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
              // DropdownButtonFormField integra validator igual que TextFormField
              DropdownButtonFormField<Category>(
                value: selectedCategory, // instancia de la lista actual
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
                // Guardamos solo el id, no la instancia
                onChanged: (cat) => setState(() => _selectedCategoryId = cat?.id),
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
              // Teclado numérico con decimales
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

## Parte 2 — Migración a go_router

### ¿Por qué go_router?

| Navigator (imperativo) | go_router (declarativo) |
|------------------------|-------------------------|
| Le dices **cómo** navegar | Le dices **a dónde** ir |
| Stack implícito | Tabla de rutas central y explícita |
| Scaffold + Drawer repetido en cada pantalla | Un solo `Scaffold` en `AppShell` |
| Route guard = código duplicado | `redirect` en un solo lugar |

### Paso 2.1 — Instalar go_router

**Archivo:** `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.6.0
  provider: ^6.1.5+1
  sqflite: ^2.4.2+1
  path: ^1.9.1
  go_router: ^17.3.0    # ← agregar
```

```bash
flutter pub get
```

---

### Paso 2.2 — Crear app_router.dart

Crea el directorio `lib/router/` y dentro el archivo `app_router.dart`. Este archivo es el **único lugar** donde vive toda la navegación de la app.

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

// Rutas que muestran Drawer — las "pantallas raíz" de la app
const _rootRoutes = ['/', '/categories', '/products', '/clients'];

// Mapea cada ruta a su título de AppBar
// Se usa en AppShell para mostrar el título correcto según la ruta activa
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

// Instancia global del router — se pasa a MaterialApp.router en main.dart
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ShellRoute: envuelve todas las rutas hijas con AppShell.
    // AppShell provee el único Scaffold, AppBar y Drawer de la app.
    ShellRoute(
      builder: (context, state, child) => AppShell(
        // state.uri.toString() devuelve la ruta activa completa (/categories/form)
        // state.matchedLocation devuelve solo la ruta del shell (/categories) — incorrecto
        location: state.uri.toString(),
        child: child, // la pantalla activa renderiza aquí
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
              // path relativo — go_router lo concatena: /categories + form = /categories/form
              path: 'form',
              builder: (context, state) => CategoryFormScreen(
                // state.extra transporta objetos entre rutas
                // null = crear, Category = editar
                category: state.extra as dynamic,
              ),
            ),
            GoRoute(
              // :id es un parámetro de URL — se extrae con state.pathParameters['id']
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

// ─── AppShell — único Scaffold de la app ─────────────────────────────────────
// StatelessWidget que recibe la ubicación actual y la pantalla activa (child).
// Construye el Scaffold con AppBar y Drawer según si la ruta es raíz o hija.
class AppShell extends StatelessWidget {
  final String location; // ruta activa completa, ej: /categories/form
  final Widget child;    // pantalla activa — renderiza como body del Scaffold

  const AppShell({super.key, required this.location, required this.child});

  // true si la ruta activa es una pantalla raíz (muestra Drawer)
  // false si es formulario o detalle (muestra botón atrás)
  bool get _isRoot => _rootRoutes.contains(location);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(location)),
        backgroundColor: Colors.orange,
        // Pantalla raíz → leading null → Flutter pone el hamburger automáticamente
        // Pantalla hija → botón atrás manual con context.pop()
        leading: _isRoot
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        automaticallyImplyLeading: _isRoot,
      ),
      // Drawer solo en pantallas raíz
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
          // El Drawer es una ruta de Navigator interno — se cierra con Navigator.pop
          // LUEGO context.go() cambia la ruta en go_router
          // Este orden es crítico: cerrar primero, navegar después
          Navigator.of(context).pop();
          context.go(route);
        }
      },
    );
  }
}
```

---

### Paso 2.3 — Modificar main.dart

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
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
      ],
      // MaterialApp.router delega la navegación a go_router
      // Ya no usamos home: — el router define la pantalla inicial
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter, // ← instancia del GoRouter
      ),
    );
  }
}
```

---

### Paso 2.4 — Modificar main_screen.dart

`MainScreen` ya no necesita `Scaffold`. El `AppShell` lo provee. Solo retorna el contenido.

**Archivo:** `lib/screens/main_screen.dart`

```dart
import 'package:flutter/material.dart';

// MainScreenBody — solo el body que AppShell renderiza
// No necesita Scaffold, AppBar ni Drawer
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

### Paso 2.5 — Migrar las pantallas

**Tabla de equivalencias — Navigator → go_router**

| Navigator (antes) | go_router (ahora) | Cuándo usarlo |
|-------------------|-------------------|---------------|
| `Navigator.push(…, MaterialPageRoute(builder: (_) => Screen()))` | `context.push('/ruta')` | Formularios, detalles — apila con botón atrás |
| `Navigator.push(…, extra: objeto)` | `context.push('/ruta', extra: objeto)` | Pasar objeto al editar |
| `Navigator.pop(context)` | `context.pop()` | Volver a la pantalla anterior |
| `Navigator.pushReplacement(…)` | `context.go('/ruta')` | Drawer — reemplaza el stack |

**Diferencia clave:**
- `context.go()` — reemplaza el stack. Sin botón atrás. Para el Drawer.
- `context.push()` — apila. Botón atrás visible. Para formularios y detalles.

#### CategoryListScreen

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

    // Scaffold sin AppBar — el AppBar lo provee AppShell
    // El Scaffold aquí solo existe para el FloatingActionButton
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        // context.push apila la ruta — aparecerá botón atrás en CategoryFormScreen
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
                  // Navegar al detalle pasando el id en la URL
                  onTap: () => context.push('/categories/${cat.id}'),
                );
              },
            ),
    );
  }
}
```

#### CategoryDetailScreen

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

    // Sin Scaffold — AppShell provee el Scaffold con botón atrás
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
                  extra: category, // pasa el objeto via state.extra
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

#### ProductListScreen

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

#### ProductDetailScreen

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

#### ClientListScreen

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
            // context.pop() cierra el diálogo — funciona igual que Navigator.pop
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
      // Dos FABs — sync y agregar
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'sync', // heroTag requerido cuando hay más de un FAB
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
                    // Navegar al formulario pasando el objeto para editar
                    onTap: () => context.push('/clients/form', extra: client),
                  ),
                );
              },
            ),
    );
  }
}
```

#### ClientFormScreen

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sales/models/client.dart';
import 'package:sales/providers/client_provider.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;

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
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final provider = context.read<ClientProvider>();
      if (widget.client == null) {
        await provider.save(Client(0, _name, _documentNumber, false, null));
      } else {
        await provider.edit(
          widget.client!.id,
          Client(
            widget.client!.id, _name, _documentNumber,
            false, widget.client!.serverId,
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
│   └── app_router.dart          ← NUEVO: GoRouter + AppShell + rutas
├── screens/
│   ├── main_screen.dart         solo body (MainScreenBody)
│   ├── category/
│   │   ├── list.dart            Scaffold sin AppBar + context.push
│   │   ├── detail.dart          Padding directo + context.pop
│   │   └── form.dart            Form + GlobalKey + TextFormField
│   ├── product/
│   │   ├── list.dart
│   │   ├── detail.dart
│   │   └── form.dart            + fix DropdownButtonFormField
│   └── client/
│       ├── list.dart            Dismissible + sync + 2 FABs
│       └── form.dart            Form + GlobalKey + TextFormField
├── services/
│   ├── category_service.dart
│   ├── product_service.dart
│   └── client_service.dart
└── main.dart                    MaterialApp.router
```

---

## Trabajo Autónomo

Aplica el mismo patrón de formulario validado en `ClientFormScreen`. El código ya está incluido en esta guía — revísalo, entiende cada comentario y verifica que funcione correctamente en el emulador.

Criterios de verificación:

- [ ] Nombre vacío → error "El nombre es requerido"
- [ ] Nombre con 1 carácter → error "Mínimo 2 caracteres"
- [ ] Documento vacío → error "El número de documento es requerido"
- [ ] Documento con menos de 8 dígitos → error correspondiente
- [ ] Documento con letras → error "Solo se permiten números"
- [ ] Datos válidos → crea/edita correctamente sin regresión
- [ ] Navegación go_router funciona en todos los módulos

---

## Próxima sesión

**JWT + Autenticación contra DRF**

- Pantalla de login en Flutter
- Llamada al endpoint `/api/token/` de DRF
- Guardar el Bearer token en `SharedPreferences`
- Enviar el token en cada request HTTP con `Authorization: Bearer <token>`
- Route guard con `redirect` en go_router — protege todas las rutas automáticamente

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