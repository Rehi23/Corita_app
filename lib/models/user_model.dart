class User {
  final int? id;
  final String fullName; // Coincide con "full_name" del JSON
  final String email;
  final String phone;
  final String gender;
  final DateTime? birthDate;
  final String nss;
  final String bloodType;
  final String allergies;
  final String medicalHistory;
  final String? profilePicture; // <--- ESTE ES IMPORTANTE

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    this.birthDate,
    required this.nss,
    required this.bloodType,
    required this.allergies,
    required this.medicalHistory,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'] ?? '', // Flutter lee la llave que manda Python
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? 'Masculino',
      birthDate: json['birth_date'] != null && json['birth_date'] != 'None'
          ? DateTime.tryParse(json['birth_date']) 
          : null,
      nss: json['nss'] ?? '',
      bloodType: json['blood_type'] ?? '',
      allergies: json['allergies'] ?? '',
      medicalHistory: json['medical_history'] ?? '',
      profilePicture: json['profile_picture'], // Lee la llave nueva
    );
  }
    // Convertir de Objeto Dart a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'nss': nss,
      'blood_type': bloodType,
      'allergies': allergies,
      'medical_history': medicalHistory,
      'profile_picture': profilePicture, // <--- 4. AGREGADO AL TOJSON
    };
  }
}
