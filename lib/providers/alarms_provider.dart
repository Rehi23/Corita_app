import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/alarm_model.dart';

class AlarmsProvider extends ChangeNotifier {
  List<Alarm> _alarms = [];
  bool _isLoading = false;

  List<Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;

  // Descargar alarmas del servidor
  Future<void> fetchAlarms(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Llamamos al endpoint que creamos en Python: GET /alarms/{id}
      final response = await ApiClient.get('/alarms/$userId');
      
      final List<dynamic> data = response as List<dynamic>;
      _alarms = data.map((json) => Alarm.fromJson(json)).toList();
      
    } catch (e) {
      print("Error cargando alarmas: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método opcional para agregar manualmente a la lista local y que se vea rápido
  void addAlarmLocal(Alarm alarm) {
    _alarms.add(alarm);
    notifyListeners();
  }

  // --- BORRAR ALARMA ---
  Future<void> deleteAlarm(int alarmId) async {
    try {
      await ApiClient.delete('/alarms/$alarmId');
      
      // Actualizar lista localmente para que desaparezca rápido
      _alarms.removeWhere((a) => a.id == alarmId);
      notifyListeners();
      
    } catch (e) {
      print("Error borrando alarma: $e");
    }
  }

  // --- ACTUALIZAR ESTADO (Switch) ---
  Future<void> toggleAlarmActive(int index, bool newValue) async {
    final alarm = _alarms[index];
    
    // 1. Actualización Optimista (cambiar visualmente antes de esperar al servidor)
    alarm.active = newValue; // Nota: Necesitas quitar 'final' de 'active' en tu modelo Alarm si da error
    notifyListeners();

    try {
      // 2. Enviar al servidor
      // Preparamos los datos (incluyendo la hora actual para cumplir con el esquema)
      final String timeStr = '${alarm.time.hour}:${alarm.time.minute}';
      
      await ApiClient.put('/alarms/${alarm.id}', {
        "active": newValue,
        "label": alarm.label,
        "days": alarm.days.join(','),
        "tone": alarm.tone,
        "alarm_time": timeStr
      });
      
    } catch (e) {
      // Si falla, revertimos el cambio visual
      alarm.active = !newValue;
      notifyListeners();
      print("Error actualizando: $e");
    }
  }

  // --- EDITAR ALARMA COMPLETA (Nombre, Hora, Tono, etc.) ---
  Future<void> updateAlarmFull(int id, Map<String, dynamic> alarmData) async {
    try {
      await ApiClient.put('/alarms/$id', alarmData);
      
      // Actualizar la lista localmente para ver cambios sin recargar
      final index = _alarms.indexWhere((a) => a.id == id);
      if (index != -1) {
        // Truco: Forzamos la recarga completa para simplificar
        // O podrías actualizar el objeto _alarms[index] manualmente
      }
      notifyListeners();
    } catch (e) {
      print("Error editando alarma: $e");
      throw e; // Lanzamos el error para que la pantalla lo muestre
    }
  }
}