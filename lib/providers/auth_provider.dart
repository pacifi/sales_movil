// lib/providers/auth_provider.dart
//
// Gestiona el estado global de autenticación de la app.
// Es el único punto de verdad sobre si el usuario está autenticado.
// Persiste el token en SharedPreferences para sobrevivir reinicios de la app.
// Notifica a go_router cuando el estado cambia para activar el redirect guard.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  // Clave usada para guardar y leer el token en SharedPreferences.
  static const String _tokenKey = 'auth_token';

  // El token actual. null significa que no hay sesión activa.
  String? _token;

  // Expone si hay una sesión activa. Lo consume el redirect guard en app_router.dart.
  bool get isAuthenticated => _token != null;

  // Expone el token para inyectarlo en los headers de los services.
  String? get token => _token;

  final AuthService _authService = AuthService();

  // Se llama desde main.dart al iniciar la app.
  // Lee el token persistido para restaurar la sesión automáticamente.
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);

    if (savedToken != null) {
      // Si existe un token guardado, la sesión se restaura sin pedir credenciales.
      _token = savedToken;
      notifyListeners();
    }
  }

  // Llama al AuthService, guarda el token si es exitoso y notifica a go_router.
  // Retorna true si el login fue exitoso, false si las credenciales son incorrectas.
  Future<bool> login(String username, String password) async {
    final token = await _authService.login(username, password);

    if (token != null) {
      _token = token;

      // Persiste el token para que sobreviva al cierre de la app.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);

      // Notifica a go_router — el redirect guard detecta isAuthenticated = true
      // y redirige automáticamente al home.
      notifyListeners();
      return true;
    }

    return false;
  }

  // Elimina el token de memoria y de SharedPreferences.
  // go_router detecta isAuthenticated = false y redirige al login.
  Future<void> logout() async {
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);

    notifyListeners();
  }
}