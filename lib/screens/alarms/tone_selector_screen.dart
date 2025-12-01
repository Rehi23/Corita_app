import 'package:flutter/material.dart';

class ToneSelectorScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tones = [
    {"name": "Alarma meteorológica", "color": Colors.orangeAccent, "icon": Icons.wb_sunny},
    {"name": "Alarma natural", "color": Colors.cyan, "icon": Icons.water_drop}, // Selección azul en imagen
    {"name": "Rocío matutino", "color": Colors.green, "icon": Icons.grass},
    {"name": "Luciérnagas", "color": Colors.indigo, "icon": Icons.nights_stay},
    {"name": "Ensueño", "color": Colors.purpleAccent, "icon": Icons.bedtime},
    {"name": "Campana Clásica", "color": Colors.blueAccent, "icon": Icons.notifications_active},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Tonos", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columnas como en la imagen
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8, // Tarjetas más altas que anchas
        ),
        itemCount: tones.length,
        itemBuilder: (context, index) {
          final tone = tones[index];
          return GestureDetector(
            onTap: () {
              // Devolver el tono seleccionado
              Navigator.pop(context, tone['name']);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tone['color'].withOpacity(0.8), tone['color']],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono decorativo (simulando la imagen de fondo)
                  Expanded(child: Center(child: Icon(tone['icon'], size: 50, color: Colors.white54))),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      tone['name'],
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}