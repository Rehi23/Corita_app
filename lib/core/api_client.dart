import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  // ---------------------------------------------------------
  // CONFIGURACIÓN DE IP (¡CAMBIA ESTO SEGÚN DONDE PRUEBES!)
  // ---------------------------------------------------------
  // Si usas EMULADOR Android: usa '10.0.2.2'
  static const String phpApiUrl = 'http://192.168.100.34:8000/AW/integradora/coritas_doctors1/api';
  // http://localhost/AW/integradora/coritas_doctors1/api/chat_movil.php
  static const String apiBaseUrl = 'http://192.168.100.34:8000';

  // Headers básicos para JSON
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  // --- GET (Obtener datos) ---
  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$apiBaseUrl$endpoint');
    try {
      final response = await http.get(url, headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // --- POST (Enviar datos: Login, Registro, Alarmas) ---
  static Future<dynamic> post(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$apiBaseUrl$endpoint');
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // --- SUBIDA DE IMÁGENES (Para medicamentos) ---
  static Future<dynamic> uploadImage({
    required String endpoint,
    required Map<String, String> fields,
    required File imageFile,
    required String imageFieldName, // 'photo' según definimos en FastAPI
  }) async {
    final url = Uri.parse('$apiBaseUrl$endpoint');
    var request = http.MultipartRequest('POST', url);

    // Agregar campos de texto
    request.fields.addAll(fields);

    // Agregar imagen
    request.files
        .add(await http.MultipartFile.fromPath(imageFieldName, imageFile.path));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Error subiendo imagen: $e');
    }
  }

// Procesador de respuestas MEJORADO
  static dynamic _processResponse(http.Response response) {
    // Si la respuesta es exitosa (200-299)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      // Si hay error, intentamos leer qué nos dice el servidor
      try {
        final errorBody = jsonDecode(response.body);
        final detail = errorBody['detail'];

        // Caso especial: Errores de validación de FastAPI (422) vienen como lista
        if (detail is List) {
          String mensajes = "";
          for (var item in detail) {
            // Extrae qué campo falló y por qué
            // Ejemplo: "nss: El NSS debe tener exactamente 11 dígitos"
            String campo = item['loc'].last.toString();
            String error = item['msg'].toString();
            mensajes += "$campo: $error\n";
          }
          throw Exception(mensajes);
        }
        // Caso normal: Mensaje simple
        else {
          throw Exception(detail ?? 'Error desconocido');
        }
      } catch (e) {
        // Si el error ya lo procesamos arriba, lo lanzamos
        if (e.toString().contains("Exception:")) throw e;
        // Si no se pudo leer, mostramos el código
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    }
  }

  // --- PUT (Actualizar datos) ---
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$apiBaseUrl$endpoint');
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // --- DELETE (Borrar datos) ---
  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$apiBaseUrl$endpoint');
    try {
      final response = await http.delete(url, headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // --- ACTUALIZAR CON FOTO (PUT Multipart) ---
  static Future<dynamic> updateImage({
    required String endpoint,
    required Map<String, String> fields,
    File? imageFile, // Opcional al editar
    String imageFieldName = 'photo',
  }) async {
    final url = Uri.parse('$apiBaseUrl$endpoint');
    var request = http.MultipartRequest('PUT', url); // Cambiamos a PUT

    request.fields.addAll(fields);

    // Solo adjuntamos archivo si el usuario seleccionó una foto nueva
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(imageFieldName, imageFile.path)
      );
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Error actualizando imagen: $e');
    }
  }
}