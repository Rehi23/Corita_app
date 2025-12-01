import 'package:flutter/material.dart';

class VitalSignCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const VitalSignCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 10, 
            offset: Offset(0, 4)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono superior
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 15),
          
          // Valor numérico grande
          Text(
            value, 
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: Colors.black87
            )
          ),
          
          // Unidad (mmHg, bpm)
          Text(
            unit, 
            style: TextStyle(fontSize: 12, color: Colors.grey)
          ),
          SizedBox(height: 5),
          
          // Título (Presión arterial)
          Text(
            title, 
            style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }
}