class Doctor {
  final int? id;
  final String name;
  final String connectionCode; // El código QR
  final String specialty;

  Doctor({
    this.id,
    required this.name,
    required this.connectionCode,
    this.specialty = 'General',
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'] ?? '',
      connectionCode: json['connection_code'] ?? '',
      specialty: json['specialty'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'connection_code': connectionCode,
      'specialty': specialty,
    };
  }
}