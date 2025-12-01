import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/medication_model.dart';
import 'dart:io';

class MedsProvider extends ChangeNotifier {
  List<Medication> _medications = [];
  bool _isLoading = false;

  List<Medication> get medications => _medications;
  bool get isLoading => _isLoading;

  // --- CARGAR MEDICAMENTOS DESDE API ---
  Future<void> fetchMedications(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // GET /medications/?user_id=1
      final response = await ApiClient.get('/medications/?user_id=$userId');
      
      // Convertir la lista de JSONs a lista de objetos Dart
      final List<dynamic> data = response as List<dynamic>;
      _medications = data.map((json) => Medication.fromJson(json)).toList();

    } catch (e) {
      print("Error cargando meds: $e");
      // Aquí podrías manejar un mensaje de error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- AGREGAR MEDICAMENTO (Actualizar lista localmente) ---
  void addMedicationLocal(Medication med) {
    _medications.add(med);
    notifyListeners();
  }

  // --- BORRAR MEDICAMENTO ---
  Future<void> deleteMedication(int id) async {
    try {
      await ApiClient.delete('/medications/$id');
      _medications.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      print("Error borrando med: $e");
      throw e;
    }
  }

  // --- EDITAR MEDICAMENTO ---
  Future<void> updateMedication(int id, Map<String, String> fields, File? imageFile) async {
    try {
      await ApiClient.updateImage(
        endpoint: '/medications/$id',
        fields: fields,
        imageFile: imageFile, // Puede ser null
      );
      // Forzamos recarga para ver cambios
      // (Opcionalmente podrías actualizar la lista localmente aquí)
    } catch (e) {
      print("Error editando med: $e");
      throw e;
    }
  }
}