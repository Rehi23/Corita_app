class Medication {
  final int? id;
  final int userId;
  final String name;
  final String formType; // Pastilla, Jarabe, etc.
  final double dosageAmount; // 1.0, 2.5
  final String dosageUnit; // comprimidos, ml
  final List<String> symptoms; // Lista: ['Dolor', 'Fiebre']
  final String photoPath; // Ruta en el servidor: 'static/meds/...'

  Medication({
    this.id,
    required this.userId,
    required this.name,
    required this.formType,
    required this.dosageAmount,
    required this.dosageUnit,
    required this.symptoms,
    required this.photoPath,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    // Truco: Convertir el string "Dolor,Fiebre" a una Lista real
    String symptomsString = json['symptoms'] ?? '';
    List<String> symptomsList = symptomsString.isNotEmpty 
        ? symptomsString.split(',') 
        : [];

    return Medication(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? '',
      formType: json['form_type'] ?? 'Desconocido',
      // Convertir a double seguro (MySQL a veces manda int o string)
      dosageAmount: double.tryParse(json['dosage_amount'].toString()) ?? 0.0,
      dosageUnit: json['dosage_unit'] ?? '',
      symptoms: symptomsList,
      photoPath: json['photo_path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'form_type': formType,
      'dosage_amount': dosageAmount,
      'dosage_unit': dosageUnit,
      // Convertir la lista ['A', 'B'] a string "A,B"
      'symptoms': symptoms.join(','),
      // Nota: La foto se envía por separado como archivo, no aquí
    };
  }
}