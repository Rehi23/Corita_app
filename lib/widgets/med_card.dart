import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class MedCard extends StatelessWidget {
  final String name;
  final String dosage;
  final String unit;
  final String formType;
  final String photoPath;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MedCard({
    Key? key,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.formType,
    required this.photoPath,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  // --- LÓGICA DE COLORES ---
  Color _getBackgroundColor(String type) {
    switch (type.toLowerCase()) {
      case 'pastilla': return Color(0xFFFCE4EC); // Rosa muy claro
      case 'jarabe': return Color(0xFFFFF3E0);   // Naranja muy claro
      case 'inyección': return Color(0xFFE3F2FD); // Azul muy claro
      default: return Color(0xFFE0F2F1);         // Verde muy claro (Default)
    }
  }

  Color _getTextColor(String type) {
    switch (type.toLowerCase()) {
      case 'pastilla': return Color(0xFFC2185B); // Rosa oscuro
      case 'jarabe': return Color(0xFFE65100);   // Naranja oscuro
      case 'inyección': return Color(0xFF1565C0); // Azul oscuro
      default: return CoritaTheme.secondaryColor; // Verde oscuro
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? fullImageUrl = photoPath.isNotEmpty 
        ? '${AppConstants.apiBaseUrl}/$photoPath' 
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0, // Quitamos elevación para un look más plano y moderno
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200), // Borde sutil
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // 1. FOTO
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(18),
                  image: fullImageUrl != null
                      ? DecorationImage(image: NetworkImage(fullImageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: fullImageUrl == null
                    ? Icon(Icons.medication, color: Colors.grey[300], size: 30)
                    : null,
              ),
              
              const SizedBox(width: 15),

              // 2. INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // --- CHIP DE COLOR DINÁMICO ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getBackgroundColor(formType),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formType,
                            style: TextStyle(
                              fontSize: 12, 
                              color: _getTextColor(formType), 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$dosage $unit",
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. ACCIÓN
              if (onDelete != null)
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: onDelete)
              else
                Icon(Icons.chevron_right, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }
}