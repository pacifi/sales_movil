// lib/screens/login/login_screen.dart
//
// Pantalla de autenticación. Vive FUERA del ShellRoute — no tiene Drawer ni AppBar
// compartido porque es el punto de entrada previo a la app.
// Usa el patrón Form + GlobalKey<FormState> consistente con el resto del proyecto.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sales/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controla la validación del formulario completo.
  final _formKey = GlobalKey<FormState>();

  // Controladores para leer los valores de los campos al hacer submit.
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controla el indicador de carga durante la llamada al API.
  bool _isLoading = false;

  // Controla la visibilidad de la contraseña.
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Libera los controladores cuando el widget se destruye — buena práctica obligatoria.
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Ejecuta todos los validators del Form antes de proceder.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Lee el AuthProvider sin escuchar cambios — solo necesitamos llamar al método.
    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    // Verifica que el widget siga montado antes de usar context post-await.
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // go_router detecta isAuthenticated = true mediante el redirect guard
      // y redirige automáticamente. context.go es redundante pero explícito.
      context.go('/');
    } else {
      // Muestra feedback al usuario sin abandonar la pantalla.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario o contraseña incorrectos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // LoginScreen tiene su propio Scaffold — es independiente del ShellRoute.
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono representativo de la app.
                const Icon(Icons.store, size: 80, color: Colors.orange),
                const SizedBox(height: 8),
                const Text(
                  'Sales App',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 40),

                // Campo de usuario.
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  // Desactiva la corrección automática — no aplica para usernames.
                  autocorrect: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese su usuario';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de contraseña con toggle de visibilidad.
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    // Botón para mostrar/ocultar la contraseña.
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingrese su contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botón de ingreso. Muestra CircularProgressIndicator durante la carga.
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Ingresar',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}