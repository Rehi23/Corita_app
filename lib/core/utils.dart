import 'package:flutter/services.dart';

class Validators {
  // Regex para validar email
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  // --- VALIDACIÓN DE CORREO ---
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'El correo es obligatorio';
    if (!_emailRegExp.hasMatch(value)) return 'Ingrese un correo válido';
    return null;
  }

  // --- VALIDACIÓN DE CONTRASEÑA (Seguridad) ---
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    
    // Regla: Debe tener al menos una letra y un número
    bool hasLetter = value.contains(RegExp(r'[A-Za-z]'));
    bool hasDigit = value.contains(RegExp(r'[0-9]'));

    if (!hasLetter || !hasDigit) {
      return 'Debe contener letras y números';
    }
    return null;
  }

  // --- VALIDACIÓN DE NSS (11 Dígitos exactos) ---
  static String? validateNSS(String? value) {
    if (value == null || value.isEmpty) return 'El NSS es obligatorio';
    // Verificar que sean solo números
    if (int.tryParse(value) == null) return 'Solo se permiten números';
    // Verificar longitud exacta
    if (value.length != 11) return 'El NSS debe tener 11 dígitos';
    
    return null;
  }

  // --- FORMATTER PARA CAMPOS DE TEXTO ---
  // Úsalo en el inputFormatters del TextField del NSS para bloquear letras
  static List<TextInputFormatter> nssInputFormatter() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(11),
    ];
  }
}