================================================================================
Guía Técnica — Migración a go_router y Formularios Validados
Desarrollo de Aplicaciones Móviles · Unidad 3 · Sesión 02
================================================================================

:Autor: Ing. Bonnier Nilss Mamani Larico
:Institución: Universidad Peruana Unión · EP Ingeniería de Sistemas
:Semestre: 2026-1
:Stack: Flutter 3.41.0 · Dart 3.11.0 · go_router 17.3.0 · Provider 6.1.5

.. contents:: Contenido
   :depth: 3
   :local:

--------------------------------------------------------------------------------

Lección aprendida — La decisión arquitectónica va primero
================================================================================

Antes de documentar los pasos técnicos, es importante registrar el error de
proceso que cometimos en esta sesión, porque es una lección de ingeniería de
software que vale más que el código en sí.

**Lo que hicimos mal:**

Empezamos creando ``ScaffoldWrapper`` — un widget que encapsulaba ``Scaffold``,
``AppBar`` y ``Drawer`` — como solución a la duplicación de código en las
pantallas. Esto funcionó parcialmente con ``Navigator``, pero cuando luego
decidimos migrar a ``go_router``, los dos sistemas colisionaron:

- ``Navigator.pop()`` del Drawer destruía el árbol de widgets de ``go_router``
  antes de que terminara la animación de cierre.
- El error ``FocusScopeNode was used after being disposed`` se repetía en bucle.
- El Drawer no cerraba al navegar.

El problema no era un bug — era una **incompatibilidad arquitectónica**. Dos
sistemas de navegación no pueden coexistir en la misma app.

**El orden correcto:**

.. code-block:: text

   1. Decisión arquitectónica — ¿qué sistema de navegación usamos?
   2. Instalar la dependencia
   3. Crear el router central (app_router.dart)
   4. Modificar main.dart
   5. Eliminar todo lo que dependa del sistema anterior (ScaffoldWrapper)
   6. Modificar las pantallas — una por una

**Regla de ingeniería:**

   El sistema de navegación es la columna vertebral de la app. Se decide
   primero, antes de cualquier widget. Cambiarlo después obliga a reescribir
   todas las pantallas.

--------------------------------------------------------------------------------

¿Qué es go_router y por qué lo usamos?
================================================================================

``go_router`` es el paquete de navegación declarativa oficial de Flutter,
mantenido por el equipo de Google. Es el estándar recomendado para apps de
producción desde Flutter 3.x.

Diferencia fundamental
----------------------

**Navegación imperativa (Navigator — lo que teníamos):**

.. code-block:: dart

   // Le decimos CÓMO navegar paso a paso
   Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryListScreen()));
   Navigator.pop(context);
   Navigator.pushReplacement(context, MaterialPageRoute(...));

**Navegación declarativa (go_router — lo que tenemos ahora):**

.. code-block:: dart

   // Le decimos A DÓNDE ir — el router resuelve cómo
   context.go('/categories');
   context.push('/categories/form');
   context.pop();

La diferencia no es solo sintáctica. Con ``Navigator``, el estado del stack de
pantallas es implícito — hay que leer el código para saber qué hay apilado. Con
``go_router``, la app tiene una **tabla de rutas central** que define toda la
navegación posible, como un router de Express o Django.

Ventajas concretas para el proyecto ``sales``
---------------------------------------------

+---------------------------+-------------------------------------------+
| Antes (Navigator)         | Ahora (go_router)                         |
+===========================+===========================================+
| Drawer repetido en cada   | Un solo ``AppShell`` con Drawer           |
| pantalla                  | centralizado                              |
+---------------------------+-------------------------------------------+
| ``Scaffold`` en cada      | Un solo ``Scaffold`` en ``AppShell``      |
| pantalla                  |                                           |
+---------------------------+-------------------------------------------+
| Botón atrás manual en     | ``AppShell`` lo resuelve automáticamente  |
| cada pantalla             | según la ruta                             |
+---------------------------+-------------------------------------------+
| Agregar módulo = modificar| Agregar módulo = una ruta en              |
| N pantallas               | ``app_router.dart``                       |
+---------------------------+-------------------------------------------+
| Route guard imposible sin | ``redirect`` en ``GoRouter`` protege      |
| duplicar código           | todas las rutas (JWT próxima sesión)      |
+---------------------------+-------------------------------------------+

--------------------------------------------------------------------------------

Paso 1 — Agregar go_router al proyecto
================================================================================

Abre ``pubspec.yaml`` y agrega la dependencia en la sección ``dependencies``:

.. code-block:: yaml

   dependencies:
     flutter:
       sdk: flutter
     cupertino_icons: ^1.0.8
     http: ^1.6.0
     provider: ^6.1.5+1
     sqflite: ^2.4.2+1
     path: ^1.9.1
     go_router: ^17.3.0    # ← agregar esta línea

Luego ejecuta en la terminal:

.. code-block:: bash

   flutter pub get

.. note::

   Si ``flutter pub add go_router`` falla por permisos o red, edita el
   ``pubspec.yaml`` manualmente y corre ``flutter pub get``. Ambos producen
   el mismo resultado.

**¿Por qué esta versión?**

``go_router 17.x`` es compatible con Flutter 3.41 / Dart 3.11. La versión
introduce ``ShellRoute`` estable y ``state.uri.toString()`` para obtener la
ruta activa completa — ambos los usamos en esta sesión.

--------------------------------------------------------------------------------

Paso 2 — Crear app_router.dart
================================================================================

Este es el archivo más importante de la migración. Centraliza **toda** la
navegación de la app en un solo lugar.

Crea el archivo ``lib/router/app_router.dart``:

.. code-block:: dart

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

Decisiones técnicas clave
-------------------------

**¿Por qué ``ShellRoute``?**

``ShellRoute`` es el patrón de go_router para compartir UI entre rutas. Su
``builder`` envuelve todas las rutas hijas con un widget común — en nuestro
caso ``AppShell``. Esto significa que el ``Scaffold``, ``AppBar`` y ``Drawer``
se definen **una sola vez** y se reutilizan en todas las pantallas sin
duplicación.

**¿Por qué ``state.uri.toString()`` y no ``state.matchedLocation``?**

``state.matchedLocation`` devuelve la ruta del shell (``/categories``), no la
ruta hija activa (``/categories/form``). Esto causaba que el ``AppShell``
mostrara el Drawer y el hamburger incluso en pantallas de formulario y detalle.
``state.uri.toString()`` devuelve la ruta completa activa, resolviendo el
problema.

**¿Por qué rutas anidadas con path relativo?**

Las rutas hijas usan path relativo sin ``/`` inicial (``'form'``, ``':id'``).
go_router las concatena automáticamente con la ruta padre, resultando en
``/categories/form`` y ``/categories/:id``. Esto mantiene la jerarquía clara
y evita repetición.

**¿Por qué ``state.extra`` para pasar objetos?**

Los parámetros de URL (``pathParameters``) solo transportan strings. Para
pasar objetos completos como ``Category`` o ``Product`` al formulario de
edición, ``go_router`` provee ``extra`` — un campo ``Object?`` que viaja
junto con la navegación.

.. code-block:: dart

   // Navegar pasando el objeto
   context.push('/categories/form', extra: category);

   // Recibirlo en la ruta
   CategoryFormScreen(category: state.extra as dynamic)

AppShell — el único Scaffold de la app
---------------------------------------

``AppShell`` es un ``StatelessWidget`` que recibe la ubicación actual y el
``child`` (la pantalla activa). Es el único lugar donde existe un ``Scaffold``
en toda la app:

.. code-block:: dart

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
   }

**Lógica del botón atrás vs hamburger:**

- Si la ruta está en ``_rootRoutes`` → ``_isRoot = true`` → aparece el
  hamburger del Drawer automáticamente.
- Si la ruta NO está en ``_rootRoutes`` (formulario, detalle) →
  ``_isRoot = false`` → aparece el botón atrás manualmente definido.
- El ``Drawer`` solo se asigna cuando ``_isRoot = true``.

**¿Por qué ``Navigator.of(context).pop()`` para cerrar el Drawer?**

.. code-block:: dart

   onTap: () {
     if (!isActive) {
       Navigator.of(context).pop(); // cierra el drawer
       context.go(route);
     }
   },

El ``Drawer`` en Flutter es una ruta de ``Navigator`` — se abre y cierra con
el ``Navigator`` interno de ``Scaffold``. ``context.go()`` opera sobre el
router de ``go_router``, que es un nivel superior. Por eso necesitamos
``Navigator.of(context).pop()`` para cerrar el drawer ANTES de que
``context.go()`` cambie la ruta — así el árbol de widgets del Drawer se
destruye limpiamente antes de la transición.

--------------------------------------------------------------------------------

Paso 3 — Modificar main.dart
================================================================================

``MaterialApp`` se reemplaza por ``MaterialApp.router``, que acepta un
``routerConfig`` en lugar de ``home``:

.. code-block:: dart

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

**¿Por qué ``MaterialApp.router``?**

``MaterialApp`` usa ``Navigator`` internamente. ``MaterialApp.router`` delega
el control de navegación al ``routerConfig`` proporcionado — en nuestro caso
``appRouter``. Esto le da a ``go_router`` control total sobre el stack de
rutas.

.. note::

   El ``MultiProvider`` no cambia. Los Providers viven por encima del sistema
   de navegación — todas las rutas tienen acceso a ellos.

--------------------------------------------------------------------------------

Paso 4 — Modificar main_screen.dart
================================================================================

``MainScreen`` ya no necesita ``Scaffold`` propio. El ``AppShell`` lo provee.
Solo retorna el contenido:

.. code-block:: dart

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

.. note::

   La clase se renombra a ``MainScreenBody`` para reflejar que ya no es una
   pantalla completa sino solo el body que el ``AppShell`` renderiza.

--------------------------------------------------------------------------------

Paso 5 — Eliminar scaffold_wrapper.dart
================================================================================

El archivo ``lib/widgets/scaffold_wrapper.dart`` se elimina completamente.

**¿Por qué existió y por qué lo eliminamos?**

``ScaffoldWrapper`` fue creado como solución a la duplicación de ``Scaffold``,
``AppBar`` y ``Drawer`` en cada pantalla. Era una solución válida para
``Navigator`` puro, pero **incompatible con ``go_router``** por la misma razón
que causó el bug del ``FocusScopeNode``:

Cuando ``go_router`` cambia de ruta con ``context.go()``, destruye el árbol de
widgets de la ruta anterior. Si el ``Drawer`` estaba dentro de ese árbol y
tenía el foco, Flutter intentaba notificar al ``FocusScopeNode`` ya destruido,
causando el error en bucle.

La solución correcta no fue arreglar ``ScaffoldWrapper`` sino eliminar la
necesidad de que existiera, moviendo el ``Scaffold`` al ``AppShell`` que vive
**fuera** del árbol de rutas cambiantes.

--------------------------------------------------------------------------------

Paso 6 — Modificar las pantallas
================================================================================

Con ``AppShell`` como único ``Scaffold``, cada pantalla:

- **Elimina** su ``Scaffold`` propio
- **Elimina** imports de ``scaffold_wrapper.dart``
- **Reemplaza** ``Navigator.push`` → ``context.push``
- **Reemplaza** ``Navigator.pop`` → ``context.pop``
- **Reemplaza** ``Navigator.pushReplacement`` → ``context.go``

Tabla de equivalencias Navigator → go_router
--------------------------------------------

+-----------------------------------------------+-------------------------------------+
| Navigator (antes)                             | go_router (ahora)                   |
+===============================================+=====================================+
| ``Navigator.push(context,                     | ``context.push('/categories/form')``|
| MaterialPageRoute(builder: (_) =>             |                                     |
| CategoryFormScreen()))``                      |                                     |
+-----------------------------------------------+-------------------------------------+
| ``Navigator.pop(context)``                    | ``context.pop()``                   |
+-----------------------------------------------+-------------------------------------+
| ``Navigator.pushReplacement(context,          | ``context.go('/categories')``       |
| MaterialPageRoute(...))``                     |                                     |
+-----------------------------------------------+-------------------------------------+
| Pasar objeto al constructor:                  | ``context.push('/categories/form``, |
| ``CategoryFormScreen(category: cat)``         | ``extra: cat)``                     |
+-----------------------------------------------+-------------------------------------+
| Recibir objeto vía constructor                | ``state.extra as dynamic``          |
+-----------------------------------------------+-------------------------------------+

**Diferencia entre ``context.go`` y ``context.push``:**

- ``context.go(route)`` — navega reemplazando el stack. No hay botón atrás.
  Se usa para navegación entre módulos (Drawer).
- ``context.push(route)`` — apila la nueva ruta. Aparece botón atrás.
  Se usa para formularios y detalles.

Pantallas de lista — patrón resultante
---------------------------------------

Las pantallas de lista ya no tienen ``Scaffold`` propio. Retornan directamente
su contenido. El ``floatingActionButton`` se pasa como parámetro del
``Scaffold`` del ``AppShell``... pero hay un detalle:

.. code-block:: dart

   // El FAB vive en el Scaffold de la pantalla de lista, no en AppShell
   // porque es específico de esa pantalla
   return Scaffold(
     floatingActionButton: FloatingActionButton(
       onPressed: () => context.push('/categories/form'),
       child: const Icon(Icons.add),
     ),
     body: ListView.builder(...),
   );

.. note::

   Sí, las pantallas de lista tienen un ``Scaffold`` propio — pero sin
   ``AppBar`` ni ``Drawer``. Flutter permite anidar ``Scaffold`` cuando el
   interno no define ``AppBar``. El ``AppBar`` visible es siempre el del
   ``AppShell`` externo.

Pantallas de detalle y formulario — patrón resultante
------------------------------------------------------

No necesitan ``Scaffold``. Retornan directamente su contenido (``Padding``,
``Form``, ``Column``):

.. code-block:: dart

   @override
   Widget build(BuildContext context) {
     return Padding(           // ← directo, sin Scaffold
       padding: const EdgeInsets.all(16.0),
       child: Column(
         children: [...]
       ),
     );
   }

--------------------------------------------------------------------------------

Paso 7 — Formularios con validación
================================================================================

Independientemente de la migración a ``go_router``, los formularios se
refactorizaron del patrón ``TextField`` + ``TextEditingController`` al patrón
``Form`` + ``GlobalKey<FormState>`` + ``TextFormField``.

El problema con TextField simple
---------------------------------

Cada pantalla de formulario usaba ``TextEditingController`` para gestionar el
valor de cada campo. La validación era manual — se verificaba el texto antes
de llamar al Provider:

.. code-block:: dart

   // ❌ Antes — validación manual, sin feedback visual
   ElevatedButton(
     onPressed: () {
       if (controllerName.text.trim().isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(...);
         return;
       }
       provider.save(...);
     },
   )

Problemas concretos:

- Sin mensaje de error bajo el campo — el usuario no sabe qué falló.
- Validación mezclada con lógica de envío.
- Sin estado visual de error en el widget.
- Cada módulo repite el mismo patrón de forma inconsistente.

El trío Form + GlobalKey + TextFormField
-----------------------------------------

**``Form``** — widget coordinador invisible. Conoce a todos sus
``TextFormField`` hijos y puede pedirles que validen o guarden al mismo tiempo.

**``GlobalKey<FormState>``** — llave única que permite acceder al estado
interno del ``Form`` desde el método ``_submit()``. Debe vivir en el estado
del ``StatefulWidget``.

**``TextFormField``** — versión extendida de ``TextField`` que integra
``validator`` (reglas de validación) y ``onSaved`` (extracción del valor).

El flujo de tres pasos
-----------------------

.. code-block:: dart

   Future<void> _submit() async {
     // Paso 1 — VALIDATE
     // Ejecuta el validator de cada TextFormField.
     // Si alguno falla, muestra el mensaje bajo el campo y retorna false.
     if (!_formKey.currentState!.validate()) return;

     // Paso 2 — SAVE
     // Ejecuta onSaved de cada campo, transfiriendo valores a variables locales.
     // Solo se ejecuta si validate() retornó true.
     _formKey.currentState!.save();

     // Paso 3 — SUBMIT
     // Con los valores ya extraídos, construir el objeto y llamar al Provider.
     await provider.save(Category(0, _name, _description));

     if (context.mounted) context.pop();
   }

Ejemplo completo — CategoryFormScreen
--------------------------------------

.. code-block:: dart

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

El bug del DropdownButtonFormField con objetos
----------------------------------------------

Al migrar el dropdown de categorías en ``ProductFormScreen`` de
``DropdownButton`` a ``DropdownButtonFormField``, apareció este error:

.. code-block:: text

   There should be exactly one item with [DropdownButton]'s value.
   Either zero or 2 or more [DropdownMenuItem]s were detected with the same value.

**Causa raíz:** ``DropdownButtonFormField`` compara el ``value`` con los
ítems usando ``==``. Como ``Category`` no implementa ``==`` ni ``hashCode``,
Dart compara por referencia de objeto. Las instancias que vienen de la API en
cada ``loadAll()`` son objetos distintos en memoria aunque tengan el mismo
``id``.

**Solución:** guardar solo el ``id`` de la categoría seleccionada, no la
instancia. En cada ``build()``, resolver la instancia real buscando por ``id``
dentro de la lista actual del provider:

.. code-block:: dart

   // Estado — guardamos solo el id
   int? _selectedCategoryId;

   // En build() — resolvemos la instancia real en cada rebuild
   final selectedCategory = _selectedCategoryId == null
       ? null
       : categories.where((c) => c.id == _selectedCategoryId).isNotEmpty
           ? categories.firstWhere((c) => c.id == _selectedCategoryId)
           : null;

   // En el dropdown — value es la instancia de la lista actual
   DropdownButtonFormField<Category>(
     value: selectedCategory, // misma instancia que el ítem
     ...
   )

Así el ``value`` del dropdown y el ítem correspondiente en la lista son
**exactamente el mismo objeto en memoria** — la comparación por referencia
funciona correctamente.

--------------------------------------------------------------------------------

Estructura final del proyecto
================================================================================

.. code-block:: text

   lib/
   ├── config/
   │   └── app_config.dart          # URL base de la API
   ├── database/
   │   └── database_helper.dart     # SQLite para Client (offline-first)
   ├── models/
   │   ├── category.dart
   │   ├── product.dart
   │   └── client.dart
   ├── providers/
   │   ├── category_provider.dart
   │   ├── product_provider.dart
   │   └── client_provider.dart
   ├── router/
   │   └── app_router.dart          # ← NUEVO: GoRouter + AppShell + rutas
   ├── screens/
   │   ├── main_screen.dart         # solo body (MainScreenBody)
   │   ├── category/
   │   │   ├── list.dart            # sin Scaffold propio
   │   │   ├── detail.dart          # sin Scaffold propio
   │   │   └── form.dart            # Form + GlobalKey + TextFormField
   │   ├── product/
   │   │   ├── list.dart
   │   │   ├── detail.dart
   │   │   └── form.dart            # + fix DropdownButtonFormField
   │   └── client/
   │       ├── list.dart            # Dismissible + sincronización
   │       └── form.dart            # Form + GlobalKey + TextFormField
   ├── services/
   │   ├── category_service.dart
   │   ├── product_service.dart
   │   └── client_service.dart
   └── main.dart                    # MaterialApp.router

   ELIMINADO:
   lib/widgets/scaffold_wrapper.dart  # incompatible con go_router

Árbol de rutas
--------------

.. code-block:: text

   ShellRoute (AppShell — único Scaffold)
   ├── /                    → MainScreenBody
   ├── /categories          → CategoryListScreen
   │   ├── /categories/form → CategoryFormScreen (extra: Category?)
   │   └── /categories/:id  → CategoryDetailScreen
   ├── /products            → ProductListScreen
   │   ├── /products/form   → ProductFormScreen (extra: Product?)
   │   └── /products/:id    → ProductDetailScreen
   └── /clients             → ClientListScreen
       └── /clients/form    → ClientFormScreen (extra: Client?)

--------------------------------------------------------------------------------

Próxima sesión — JWT + Route Guard
================================================================================

Con ``go_router`` ya en su lugar, la siguiente sesión implementa autenticación
JWT contra DRF. El route guard se agrega en un solo lugar:

.. code-block:: dart

   final appRouter = GoRouter(
     initialLocation: '/',
     redirect: (context, state) {
       final token = prefs.getString('token');
       final enLogin = state.uri.toString() == '/login';

       if (token == null && !enLogin) return '/login';
       if (token != null && enLogin)  return '/';
       return null; // dejar pasar
     },
     routes: [
       GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
       ShellRoute(...), // el shell actual
     ],
   );

Esta es la razón por la que migramos a ``go_router`` antes de implementar JWT
— el guard vive en un solo lugar y protege todas las rutas automáticamente,
incluyendo las que se agreguen en el futuro.

--------------------------------------------------------------------------------

Referencias
================================================================================

+----------------------------+-----------------------------------------------------+
| Recurso                    | URL                                                 |
+============================+=====================================================+
| go_router documentación    | https://pub.dev/packages/go_router                  |
+----------------------------+-----------------------------------------------------+
| ShellRoute                 | https://pub.dev/documentation/go_router/latest/     |
|                            | go_router/ShellRoute-class.html                     |
+----------------------------+-----------------------------------------------------+
| Form widget                | https://api.flutter.dev/flutter/widgets/            |
|                            | Form-class.html                                     |
+----------------------------+-----------------------------------------------------+
| GlobalKey                  | https://api.flutter.dev/flutter/widgets/            |
|                            | GlobalKey-class.html                                |
+----------------------------+-----------------------------------------------------+
| TextFormField              | https://api.flutter.dev/flutter/material/           |
|                            | TextFormField-class.html                            |
+----------------------------+-----------------------------------------------------+
| GoRouter migration guide   | https://docs.flutter.dev/ui/navigation              |
+----------------------------+-----------------------------------------------------+