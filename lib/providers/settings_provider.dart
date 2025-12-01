import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/tts_service.dart'; // Importamos el servicio de voz que hicimos antes

class SettingsProvider extends ChangeNotifier {
  // Estado inicial
  double _textScaleFactor = 1.0; // 1.0 = Normal, 1.2 = Grande, 1.5 = Muy Grande
  bool _audioEnabled = false;

  double get textScaleFactor => _textScaleFactor;
  bool get audioEnabled => _audioEnabled;

  // Constructor: Cargar configuración guardada al iniciar
  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _textScaleFactor = prefs.getDouble('textScale') ?? 1.0;
    _audioEnabled = prefs.getBool('audioEnabled') ?? false;
    
    // Sincronizar el servicio de TTS
    TtsService().setEnabled(_audioEnabled);
    notifyListeners();
  }

  // --- CAMBIAR TAMAÑO DE LETRA ---
  Future<void> setTextScale(double scale) async {
    _textScaleFactor = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScale', scale);
    notifyListeners(); // Esto redibujará TODA la app con la nueva letra
  }

  // --- ACTIVAR/DESACTIVAR AUDIO ---
  Future<void> toggleAudio(bool value) async {
    _audioEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audioEnabled', value);
    
    TtsService().setEnabled(value); // Avisar al servicio de voz
    notifyListeners();
  }
}