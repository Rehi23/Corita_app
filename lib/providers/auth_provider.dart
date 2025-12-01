import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/user_model.dart';
import 'dart:io';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  User? _currentUser;
  String? _token; // En un futuro aquí guardarías el JWT

  bool get isLoading => _isLoading;
  bool get isAuth => _currentUser != null;
  User? get currentUser => _currentUser;

  // --- LOGIN ---
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Llamar a la API (FastAPI)
      // Nota: Asumimos un endpoint /login que devuelve el ID y datos del usuario
      final response = await ApiClient.post('/login', {
        'username': email, // FastAPI OAuth2 suele usar 'username' para el email
        'password': password
      });

      // 2. Crear el objeto usuario con la respuesta
      _currentUser = User.fromJson(response['user']); 
      
      // 3. Guardar sesión en el celular (Persistencia)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', _currentUser!.id!);
      
      _isLoading = false;
      notifyListeners();
      return true; // Login exitoso

    } catch (e) {
      print("Error Login: $e");
      _isLoading = false;
      notifyListeners();
      return false; // Falló
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Borrar datos del celular
    notifyListeners();
  }

  // --- RECUPERAR SESIÓN AL ABRIR APP ---
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('user_id')) return;

    final userId = prefs.getInt('user_id');
    try {
      // Pedir datos frescos a la API usando el ID guardado
      final response = await ApiClient.get('/users/$userId');
      _currentUser = User.fromJson(response);
      notifyListeners();
    } catch (e) {
      // Si falla (ej. usuario borrado), limpiar sesión
      logout();
    }
  }

// Modifica la definición para aceptar imagen
  Future<void> updateProfile(Map<String, String> data, File? imageFile) async { // <--- CAMBIO AQUÍ
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Usamos updateImage que ya sabe mandar multipart/form-data
      final response = await ApiClient.updateImage(
        endpoint: '/users/${_currentUser!.id}',
        fields: data,
        imageFile: imageFile,
        imageFieldName: 'photo'
      );
      
      _currentUser = User.fromJson(response['user']);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("Error actualizando perfil: $e");
      throw e;
    }
  }
}