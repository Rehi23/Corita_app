import 'package:flutter/material.dart';

class Alarm {
  final int? id;
  final int medicationId;
  final TimeOfDay time; // Usamos el objeto de hora nativo de Flutter
  final List<String> days; // ['Lun', 'Mar', 'Mie']
  bool active;
  final String label;
  final String tone;

  Alarm({
    this.id,
    required this.medicationId,
    required this.time,
    required this.days,
    this.active = true,
    this.label = '',
    this.tone = 'default',
  });

  factory Alarm.fromJson(Map<String, dynamic> json) {
    // Parsear hora que viene como "08:30:00"
    String timeStr = json['alarm_time'] ?? '00:00';
    List<String> parts = timeStr.split(':');
    TimeOfDay parsedTime = TimeOfDay(
      hour: int.parse(parts[0]), 
      minute: int.parse(parts[1])
    );

    // Parsear días
    String daysStr = json['days'] ?? '';
    List<String> daysList = daysStr.isNotEmpty ? daysStr.split(',') : [];

    return Alarm(
      id: json['id'],
      medicationId: json['medication_id'],
      time: parsedTime,
      days: daysList,
      active: json['active'] == 1 || json['active'] == true,
      label: json['label'] ?? '',
      tone: json['tone'] ?? 'default',
    );
  }

  Map<String, dynamic> toJson() {
    // Formatear TimeOfDay a "HH:MM" para la API
    final String formattedTime = 
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return {
      'medication_id': medicationId,
      'alarm_time': formattedTime,
      'days': days.join(','),
      'active': active,
      'label': label,
      'tone': tone,
    };
  }
}