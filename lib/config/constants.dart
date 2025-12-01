class AppConstants {
  // --- NOMBRE DE LA APP ---
  static const String appName = "CORITA";

  // --- CONEXIÓN API (IMPORTANTE) ---
  // Usa '10.0.2.2:8000' para Emulador Android
  // Usa tu IP local (ej. '192.168.1.XX:8000') para probar en celular real
  static const String apiBaseUrl = 'http://192.168.100.34:8000';
  static const String phpApiUrl = 'http://192.168.100.34:8000/AW/integradora/coritas_doctors1/api';
  
  // Endpoints específicos (opcional, para mantener orden)
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String medsEndpoint = '/medications/';

  // --- ASSETS (Rutas de imágenes locales) ---
  static const String logoPath = 'assets/images/corita_logo.png';
  static const String placeholderMed = 'assets/images/med_placeholder.png';
}