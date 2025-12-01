import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import 'profile_screen.dart'; // La crearemos abajo

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Consumir los providers para leer el estado actual
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text("Configuración")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // --- 1. PERFIL ---
          _SectionHeader("Cuenta"),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: CoritaTheme.primaryColor,
                child: Text(auth.currentUser?.fullName[0] ?? "U", style: TextStyle(color: Colors.white)),
              ),
              title: Text(auth.currentUser?.fullName ?? "Usuario"),
              subtitle: Text("Editar datos personales"),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
              },
            ),
          ),
          SizedBox(height: 20),

          // --- 2. ACCESIBILIDAD (Punto 10 del requerimiento) ---
          _SectionHeader("Accesibilidad"),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                // Switch de Audio
                SwitchListTile(
                  title: Text("Indicaciones auditivas"),
                  subtitle: Text("Leer en voz alta los elementos en pantalla"),
                  activeColor: CoritaTheme.secondaryColor,
                  value: settings.audioEnabled,
                  onChanged: (bool value) {
                    settings.toggleAudio(value);
                  },
                ),
                Divider(),
                
                // Slider de Tamaño de Letra
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tamaño de letra", style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          Text("A", style: TextStyle(fontSize: 14)), // Letra chica
                          Expanded(
                            child: Slider(
                              value: settings.textScaleFactor,
                              min: 1.0,
                              max: 1.5, // 50% más grande máximo
                              divisions: 2, // 3 pasos: Normal, Grande, Muy Grande
                              activeColor: CoritaTheme.primaryColor,
                              label: _getLabel(settings.textScaleFactor),
                              onChanged: (double value) {
                                settings.setTextScale(value);
                              },
                            ),
                          ),
                          Text("A", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), // Letra grande
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // --- 3. IDIOMA (Visual) ---
          _SectionHeader("General"),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: Icon(Icons.language),
              title: Text("Idioma"),
              trailing: DropdownButton<String>(
                value: "Español",
                underline: Container(), // Quitar línea fea
                items: ["Español", "English"].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (val) {
                  // Aquí implementarías la lógica de cambio de idioma real
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Idioma cambiado a $val")));
                },
              ),
            ),
          ),
          SizedBox(height: 30),

          // --- 4. ZONA DE PELIGRO ---
          ElevatedButton.icon(
            icon: Icon(Icons.logout),
            label: Text("Cerrar Sesión"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            onPressed: () {
              auth.logout();
              // Main.dart redirigirá al Login automáticamente
            },
          ),
          SizedBox(height: 10),
          TextButton(
            child: Text("Eliminar cuenta", style: TextStyle(color: CoritaTheme.errorColor)),
            onPressed: () => _confirmDeleteAccount(context),
          ),
        ],
      ),
    );
  }

  // Helper para el título del slider
  String _getLabel(double value) {
    if (value == 1.0) return "Normal";
    if (value == 1.25) return "Grande";
    return "Muy Grande";
  }

  // Diálogo de confirmación para eliminar cuenta
  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("¿Estás seguro?"),
        content: Text("Esta acción eliminará todos tus datos médicos y alarmas. No se puede deshacer."),
        actions: [
          TextButton(child: Text("Cancelar"), onPressed: () => Navigator.pop(ctx)),
          TextButton(
            child: Text("Eliminar", style: TextStyle(color: Colors.red)),
            onPressed: () {
              // Aquí llamarías a auth.deleteAccount() que llama a la API DELETE /users/{id}
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
    );
  }
}