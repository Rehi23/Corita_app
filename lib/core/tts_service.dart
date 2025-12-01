import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  // Singleton: Para usar la misma instancia en toda la app
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isEnabled = false; // Controlado desde Configuración

  // Configuración inicial
  Future<void> init() async {
    await _flutterTts.setLanguage("es-MX"); // Español México
    await _flutterTts.setPitch(1.0); // Tono normal
    await _flutterTts.setSpeechRate(0.5); // Velocidad media (buena para adultos mayores)
  }

  // Activar o desactivar (Desde la pantalla de Configuración)
  void setEnabled(bool value) {
    _isEnabled = value;
    if (value) speak("Indicaciones auditivas activadas");
  }

  bool get isEnabled => _isEnabled;

  // Función principal para hablar
  Future<void> speak(String text) async {
    if (_isEnabled && text.isNotEmpty) {
      await _flutterTts.stop(); // Detener si estaba hablando algo antes
      await _flutterTts.speak(text);
    }
  }

  // Detener voz
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}