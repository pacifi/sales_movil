// lib/services/auth_service.dart
//
// Responsabilidad única: comunicación con el endpoint de autenticación DRF.
// Retorna el access token si las credenciales son válidas, null si fallan.
// La persistencia del token NO es responsabilidad de este servicio —
// eso le corresponde a AuthProvider, siguiendo el principio de separación de responsabilidades.

import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:sales/config/app_config.dart';

class AuthService {
  // Reutiliza la misma base URL centralizada que usan los demás services.
  final String apiUrl = AppConfig.apiUrl;

  // Envía credenciales al endpoint estándar de simplejwt en DRF.
  // Retorna el access token como String si el login es exitoso.
  // Retorna null si las credenciales son incorrectas (HTTP 401)
  // o si ocurre cualquier otro error de red.
  Future<String?> login(String username, String password) async {
    // El endpoint /api/token/ es el estándar de djangorestframework-simplejwt.
    final url = Uri.http(apiUrl, '/auth/token/');

    final response = await http.post(
      url,
      // DRF simplejwt acepta las credenciales como JSON.
      body: convert.jsonEncode({
        'username': username,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // La respuesta contiene 'access' y 'refresh'.
      // Solo usamos 'access' — el refresh queda disponible para implementación futura.
      final json = convert.jsonDecode(response.body);
      return json['access'] as String;
    }

    // Cualquier código distinto de 200 (típicamente 401) se trata como login fallido.
    return null;
  }
}