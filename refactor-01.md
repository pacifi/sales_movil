# Guía Técnica — Migración a go_router y Formularios Validados

**Desarrollo de Aplicaciones Móviles · Unidad 3 · Sesión 02**

| Campo | Detalle |
|-------|---------|
| Autor | Ing. Bonnier Nilss Mamani Larico |
| Institución | Universidad Peruana Unión · EP Ingeniería de Sistemas |
| Semestre | 2026-1 |
| Stack | Flutter 3.41.0 · Dart 3.11.0 · go_router 17.3.0 · Provider 6.1.5 |

---

## Contenido

1. [Lección aprendida — La decisión arquitectónica va primero](#1-lección-aprendida--la-decisión-arquitectónica-va-primero)
2. [¿Qué es go_router y por qué lo usamos?](#2-qué-es-go_router-y-por-qué-lo-usamos)
3. [Paso 1 — Agregar go_router al proyecto](#3-paso-1--agregar-go_router-al-proyecto)
4. [Paso 2 — Crear app_router.dart](#4-paso-2--crear-app_routerdart)
5. [Paso 3 — Modificar main.dart](#5-paso-3--modificar-maindart)
6. [Paso 4 — Modificar main_screen.dart](#6-paso-4--modificar-main_screendart)
7. [Paso 5 — Eliminar scaffold_wrapper.dart](#7-paso-5--eliminar-scaffold_wrapperdart)
8. [Paso 6 — Modificar las pantallas](#8-paso-6--modificar-las-pantallas)
9. [Paso 7 — Formularios con validación](#9-paso-7--formularios-con-validación)
10. [Estructura final del proyecto](#10-estructura-final-del-proyecto)
11. [Próxima sesión — JWT + Route Guard](#11-próxima-sesión--jwt--route-guard)
12. [Referencias](#12-referencias)

---

## 1. Lección aprendida — La decisión arquitectónica va primero

Antes de documentar los pasos técnicos, es importante registrar el error de proceso que cometimos en esta sesión, porque es una lección de ingeniería de software que vale más que el código en sí.

### Lo que hicimos mal

Empezamos creando `ScaffoldWrapper` — un widget que encapsulaba `Scaffold`, `AppBar` y `Drawer` — como solución a la duplicación de código en las pantallas. Funcionó parcialmente con `Navigator`, pero cuando luego decidimos migrar a `go_router`, los dos sistemas colisionaron:

- `Navigator.pop()` del Drawer destruía el árbol de widgets de `go_router` antes de que terminara la animación de cierre.
- El error `FocusScopeNode was used after being disposed` se repetía en bucle.
- El Drawer no se cerraba al navegar.

El problema no era un bug — era una **incompatibilidad arquitectónica**. Dos sistemas de navegación no pueden coexistir en la misma app.

### El orden correcto

```
1. Decisión arquitectónica — ¿qué sistema de navegación usamos?
2. Instalar la dependencia
3. Crear el router central (app_router.dart)
4. Modificar main.dart
5. Eliminar todo lo que dependa del sistema anterior (ScaffoldWrapper)
6. Modificar las pantallas — una por una
7. Refactorizar los formularios dentro del nuevo sistema
```

> **Regla de ingeniería:** El sistema de navegación es la columna vertebral de la app. Se decide primero, antes de cualquier widget. Cambiarlo después obliga a reescribir todas las pantallas.

---

## 2. ¿Qué es go_router y por qué lo usamos?

`go_router` es el paquete de navegación declarativa oficial de Flutter, mantenido por el equipo de Google. Es el estándar recomendado para apps de producción desde Flutter 3.x.

### Diferencia fundamental

**Navegación imperativa — Navigator (lo que teníamos):**

```dart
// Le decimos CÓMO navegar paso a paso
Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryListScreen()));
Navigator.pop(context);
Navigator.pushReplacement(context, MaterialPageRoute(...));
```

**Navegación declarativa — go_router (lo que tenemos ahora):**

```dart
// Le decimos A DÓNDE ir — el router resuelve cómo
context.go('/categories');
context.push('/categories/form');
context.pop();
```

La diferencia no es solo sintáctica. Con `Navigator`, el estado del stack de pantallas es implícito — hay que leer el código para saber qué hay apilado. Con `go_router`, la app tiene una **tabla de rutas central** que define toda la navegación posible, como un router de Express o Django.

### Ventajas concretas para el proyecto `sales`

| Antes (Navigator) | Ahora (go_router) |
|-------------------|-------------------|
| Drawer repetido en cada pantalla | Un solo `AppShell` con Drawer centralizado |
| `Scaffold` en cada pantalla | Un solo `Scaffold` en `AppShell` |
| Botón atrás manual en cada pantalla | `AppShell` lo resuelve automáticamente según la ruta |
| Agregar módulo = modificar N pantallas | Agregar módulo = una ruta en `app_router.dart` |
| Route guard imposible sin duplicar código | `redirect` en `GoRouter` protege todas las rutas |

---

## 3. Paso 1 — Agregar go_router al proyecto

Abre `pubspec.yaml` y agrega la dependencia en la sección `dependencies`:

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

Luego ejecuta en la terminal:

```bash
flutter pub get
```

> **Nota:** Si `flutter pub add go_router` falla por permisos o red, edita el `pubspec.yaml` manualmente y corre `flutter pub get`. Ambos producen el mismo resultado.

**¿Por qué esta versión?**

`go_router 17.x` es compatible con Flutter 3.41 / Dart 3.11. Introduce `ShellRoute` estable y `state.uri.toString()` para obtener la ruta activa completa — ambos los usamos en esta sesión.

---

## 4. Paso 2 — Crear app_router.dart

Este es el archivo más importante de la migración. Centraliza **toda** la navegación de la app en un solo lugar.

Crea el archivo `lib/router/app_router.dart`:

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

// Rutas que muestran Drawer (pantallas raíz)
const _rootRoutes = ['/', '/categories', '/products', '/clients'];

// Mapeo ruta → título del AppBar
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

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(
        location: state.uri.toString(), // ruta activa completa
        child: child,
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

// ─── AppShell — único Scaffold de la app ─────────────────────────────────────
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
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
          Navigator.of(context).pop(); // cierra el drawer
          context.go(route);
        }
      },
    );
  }
}
```

### Decisiones técnicas clave

#### ¿Por qué `ShellRoute`?

`ShellRoute` es el patrón de go_router para compartir UI entre rutas. Su `builder` envuelve todas las rutas hijas con un widget común — en nuestro caso `AppShell`. Esto significa que el `Scaffold`, `AppBar` y `Drawer` se definen **una sola vez** y se reutilizan en todas las pantallas.

#### ¿Por qué `state.uri.toString()` y no `state.matchedLocation`?

`state.matchedLocation` devuelve la ruta del shell (`/categories`), no la ruta hija activa (`/categories/form`). Esto causaba que el `AppShell` mostrara el Drawer y el hamburger incluso en pantallas de formulario y detalle. `state.uri.toString()` devuelve la ruta completa activa, resolviendo el problema.

#### ¿Por qué rutas anidadas con path relativo?

Las rutas hijas usan path relativo sin `/` inicial (`'form'`, `':id'`). go_router las concatena automáticamente con la ruta padre, resultando en `/categories/form` y `/categories/:id`.

#### ¿Por qué `state.extra` para pasar objetos?

Los parámetros de URL (`pathParameters`) solo transportan strings. Para pasar objetos completos como `Category` o `Product` al formulario de edición, go_router provee `extra` — un campo `Object?` que viaja junto con la navegación:

```dart
// Navegar pasando el objeto
context.push('/categories/form', extra: category);

// Recibirlo en la ruta
CategoryFormScreen(category: state.extra as dynamic)
```

#### Lógica del botón atrás vs hamburger

- Ruta en `_rootRoutes` → `_isRoot = true` → hamburger del Drawer.
- Ruta fuera de `_rootRoutes` (form, detail) → `_isRoot = false` → botón atrás.
- El `Drawer` solo se asigna cuando `_isRoot = true`.

#### ¿Por qué `Navigator.of(context).pop()` para cerrar el Drawer?

```dart
onTap: () {
if (!isActive) {
Navigator.of(context).pop(); // cierra el drawer
context.go(route);
}
},
```

El `Drawer` en Flutter es una ruta de `Navigator` — se abre y cierra con el `Navigator` interno del `Scaffold`. `context.go()` opera sobre el router de go_router, que es un nivel superior. Por eso necesitamos `Navigator.of(context).pop()` para cerrar el drawer **antes** de que `context.go()` cambie la ruta — así el árbol de widgets del Drawer se destruye limpiamente antes de la transición.

---

## 5. Paso 3 — Modificar main.dart

`MaterialApp` se reemplaza por `MaterialApp.router`, que acepta un `routerConfig` en lugar de `home`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}
```

**¿Por qué `MaterialApp.router`?**

`MaterialApp` usa `Navigator` internamente. `MaterialApp.router` delega el control de navegación al `routerConfig` proporcionado. Esto le da a go_router control total sobre el stack de rutas.

> **Nota:** El `MultiProvider` no cambia. Los Providers viven por encima del sistema de navegación — todas las rutas tienen acceso a ellos.

---

## 6. Paso 4 — Modificar main_screen.dart

`MainScreen` ya no necesita `Scaffold` propio. El `AppShell` lo provee. Solo retorna el contenido:

```dart
import 'package:flutter/material.dart';

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

> **Nota:** La clase se renombra a `MainScreenBody` para reflejar que ya no es una pantalla completa sino solo el body que el `AppShell` renderiza.

---

## 7. Paso 5 — Eliminar scaffold_wrapper.dart

El archivo `lib/widgets/scaffold_wrapper.dart` se **elimina completamente**.

### ¿Por qué existió y por qué lo eliminamos?

`ScaffoldWrapper` fue creado como solución a la duplicación de `Scaffold`, `AppBar` y `Drawer` en cada pantalla. Era una solución válida para `Navigator` puro, pero **incompatible con go_router** por la misma razón que causó el bug del `FocusScopeNode`:

Cuando go_router cambia de ruta con `context.go()`, destruye el árbol de widgets de la ruta anterior. Si el `Drawer` estaba dentro de ese árbol y tenía el foco, Flutter intentaba notificar al `FocusScopeNode` ya destruido, causando el error en bucle:

```
[ERROR] Unhandled Exception: A FocusScopeNode was used after being disposed.
Once you have called dispose() on a FocusScopeNode, it can no longer be used.
```

La solución correcta no fue arreglar `ScaffoldWrapper` sino eliminar la necesidad de que existiera, moviendo el `Scaffold` al `AppShell` que vive **fuera** del árbol de rutas cambiantes.

---

## 8. Paso 6 — Modificar las pantallas

Con `AppShell` como único `Scaffold`, cada pantalla:

- **Elimina** su `Scaffold` propio
- **Elimina** imports de `scaffold_wrapper.dart`
- **Reemplaza** `Navigator.push` → `context.push`
- **Reemplaza** `Navigator.pop` → `context.pop`
- **Reemplaza** `Navigator.pushReplacement` → `context.go`

### Tabla de equivalencias Navigator → go_router

| Navigator (antes) | go_router (ahora) |
|-------------------|-------------------|
| `Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryFormScreen()))` | `context.push('/categories/form')` |
| `Navigator.pop(context)` | `context.pop()` |
| `Navigator.pushReplacement(context, MaterialPageRoute(...))` | `context.go('/categories')` |
| `CategoryFormScreen(category: cat)` pasado al constructor | `context.push('/categories/form', extra: cat)` |
| Recibir objeto vía constructor | `state.extra as dynamic` |

### Diferencia entre `context.go` y `context.push`

- **`context.go(route)`** — navega reemplazando el stack. No hay botón atrás. Se usa para navegación entre módulos desde el Drawer.
- **`context.push(route)`** — apila la nueva ruta. Aparece botón atrás. Se usa para formularios y detalles.

### Patrón resultante en pantallas de lista

Las pantallas de lista tienen un `Scaffold` propio pero **sin `AppBar` ni `Drawer`** — solo para el `FloatingActionButton`. Flutter permite anidar `Scaffold` cuando el interno no define `AppBar`. El `AppBar` visible es siempre el del `AppShell` externo:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(               // ← Scaffold sin AppBar
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.push('/categories/form'),
      child: const Icon(Icons.add),
    ),
    body: ListView.builder(...),
  );
}
```

### Patrón resultante en pantallas de detalle y formulario

No necesitan `Scaffold`. Retornan directamente su contenido:

```dart
@override
Widget build(BuildContext context) {
  return Padding(              // ← directo, sin Scaffold
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [...],
    ),
  );
}
```

---

## 9. Paso 7 — Formularios con validación

Independientemente de la migración a go_router, los formularios se refactorizaron del patrón `TextField` + `TextEditingController` al patrón `Form` + `GlobalKey<FormState>` + `TextFormField`.

### El problema con TextField simple

```dart
// ❌ Antes — validación manual, sin feedback visual bajo el campo
ElevatedButton(
onPressed: () {
if (controllerName.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Completa todos los campos')),
);
return;
}
provider.save(...);
},
)
```

Problemas concretos:

- Sin mensaje de error bajo el campo — el usuario no sabe qué falló.
- Validación mezclada con lógica de envío.
- Sin estado visual de error en el widget.
- Cada módulo repite el patrón de forma inconsistente.

### El trío Form + GlobalKey + TextFormField

**`Form`** — widget coordinador invisible. Conoce a todos sus `TextFormField` hijos y puede pedirles que validen o guarden al mismo tiempo.

**`GlobalKey<FormState>`** — llave única que permite acceder al estado interno del `Form` desde el método `_submit()`. Debe vivir en el estado del `StatefulWidget` para no recrearse en cada rebuild.

**`TextFormField`** — versión extendida de `TextField` que integra `validator` (reglas de validación) y `onSaved` (extracción del valor cuando se llama `form.save()`).

### El flujo de tres pasos

```dart
Future<void> _submit() async {
  // PASO 1 — VALIDATE
  // Ejecuta el validator de cada TextFormField.
  // Si alguno falla, muestra el mensaje bajo el campo y retorna false.
  if (!_formKey.currentState!.validate()) return;

  // PASO 2 — SAVE
  // Ejecuta onSaved de cada campo, transfiriendo valores a variables locales.
  // Solo se ejecuta si validate() retornó true.
  _formKey.currentState!.save();

  // PASO 3 — SUBMIT
  // Con los valores ya extraídos, construir el objeto y llamar al Provider.
  await provider.save(Category(0, _name, _description));

  if (context.mounted) context.pop();
}
```

### Ejemplo completo — CategoryFormScreen

```dart
class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _name = '';
  String _description = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            TextFormField(
              initialValue: widget.category?.name ?? '',
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.trim().length < 2) {
                  return 'Mínimo 2 caracteres';
                }
                return null; // válido
              },
              onSaved: (value) => _name = value!.trim(),
            ),
            // ... más campos
          ],
        ),
      ),
    );
  }
}
```

### El bug del DropdownButtonFormField con objetos

Al migrar el dropdown de categorías en `ProductFormScreen`, apareció este error:

```
There should be exactly one item with [DropdownButton]'s value.
Either zero or 2 or more [DropdownMenuItem]s were detected with the same value.
```

**Causa raíz:** `DropdownButtonFormField` compara el `value` con los ítems usando `==`. Como `Category` no implementa `==` ni `hashCode`, Dart compara por referencia de objeto. Las instancias que vienen de la API en cada `loadAll()` son objetos distintos en memoria aunque tengan el mismo `id`.

**Solución:** guardar solo el `id` de la categoría seleccionada, no la instancia. En cada `build()`, resolver la instancia real buscando por `id` dentro de la lista actual del provider:

```dart
// Estado — guardamos solo el id
int? _selectedCategoryId;

@override
void initState() {
  super.initState();
  _selectedCategoryId = widget.product?.category.id; // solo el id
}

@override
Widget build(BuildContext context) {
  final categories = context.watch<CategoryProvider>().categories;

  // Resolvemos la instancia real en cada rebuild
  // Garantiza que value y el ítem sean el mismo objeto en memoria
  final selectedCategory = _selectedCategoryId == null
      ? null
      : categories.where((c) => c.id == _selectedCategoryId).isNotEmpty
      ? categories.firstWhere((c) => c.id == _selectedCategoryId)
      : null;

  return DropdownButtonFormField<Category>(
    value: selectedCategory, // misma instancia que el ítem
    items: categories.map((cat) => DropdownMenuItem(
      value: cat,
      child: Text(cat.name),
    )).toList(),
    onChanged: (cat) => setState(() => _selectedCategoryId = cat?.id),
    validator: (value) => value == null ? 'Selecciona una categoría' : null,
  );
}
```

---

## 10. Estructura final del proyecto

```
lib/
├── config/
│   └── app_config.dart              # URL base de la API
├── database/
│   └── database_helper.dart         # SQLite para Client (offline-first)
├── models/
│   ├── category.dart
│   ├── product.dart
│   └── client.dart
├── providers/
│   ├── category_provider.dart
│   ├── product_provider.dart
│   └── client_provider.dart
├── router/
│   └── app_router.dart              # ← NUEVO: GoRouter + AppShell + rutas
├── screens/
│   ├── main_screen.dart             # solo body (MainScreenBody)
│   ├── category/
│   │   ├── list.dart                # sin Scaffold propio
│   │   ├── detail.dart              # sin Scaffold propio
│   │   └── form.dart                # Form + GlobalKey + TextFormField
│   ├── product/
│   │   ├── list.dart
│   │   ├── detail.dart
│   │   └── form.dart                # + fix DropdownButtonFormField
│   └── client/
│       ├── list.dart                # Dismissible + sincronización
│       └── form.dart                # Form + GlobalKey + TextFormField
├── services/
│   ├── category_service.dart
│   ├── product_service.dart
│   └── client_service.dart
└── main.dart                        # MaterialApp.router

ELIMINADO:
lib/widgets/scaffold_wrapper.dart    # incompatible con go_router
```

### Árbol de rutas

```
ShellRoute (AppShell — único Scaffold)
├── /                      → MainScreenBody
├── /categories            → CategoryListScreen
│   ├── /categories/form   → CategoryFormScreen  (extra: Category?)
│   └── /categories/:id    → CategoryDetailScreen
├── /products              → ProductListScreen
│   ├── /products/form     → ProductFormScreen   (extra: Product?)
│   └── /products/:id      → ProductDetailScreen
└── /clients               → ClientListScreen
    └── /clients/form      → ClientFormScreen    (extra: Client?)
```

---

## 11. Próxima sesión — JWT + Route Guard

Con go_router ya en su lugar, la siguiente sesión implementa autenticación JWT contra DRF. El route guard se agrega en un solo lugar:

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

Esta es la razón por la que migramos a go_router antes de implementar JWT — el guard vive en un solo lugar y protege todas las rutas automáticamente, incluyendo las que se agreguen en el futuro.

---

## 12. Referencias

| Recurso | URL |
|---------|-----|
| go_router documentación | https://pub.dev/packages/go_router |
| ShellRoute | https://pub.dev/documentation/go_router/latest/go_router/ShellRoute-class.html |
| Form widget | https://api.flutter.dev/flutter/widgets/Form-class.html |
| GlobalKey | https://api.flutter.dev/flutter/widgets/GlobalKey-class.html |
| TextFormField | https://api.flutter.dev/flutter/material/TextFormField-class.html |
| GoRouter migration guide | https://docs.flutter.dev/ui/navigation |