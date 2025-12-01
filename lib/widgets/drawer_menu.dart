import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../screens/settings/settings_screen.dart'; // Para navegar a ajustes
import '../screens/auth/login_screen.dart'; // Para redirigir al salir

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtener datos del usuario logueado
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          // --- 1. CABECERA (USER INFO) ---
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: CoritaTheme.primaryColor, // Color Magenta
              image: DecorationImage(
                image: AssetImage('assets/images/header_bg.png'), // Opcional: si tienes fondo
                fit: BoxFit.cover,
                opacity: 0.2, // Oscurecer un poco la imagen de fondo
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : "U",
                style: const TextStyle(fontSize: 30, color: CoritaTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            accountName: Text(
              user?.fullName ?? "Usuario",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(user?.email ?? "correo@ejemplo.com"),
          ),

          // --- 2. OPCIONES DE MENÚ ---
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Inicio"),
            onTap: () {
              Navigator.pop(context); // Cerrar el drawer
              // Navegación adicional si fuera necesario
            },
          ),
          ListTile(
            leading: const Icon(Icons.medication),
            title: const Text("Mis Medicamentos"),
            onTap: () {
              Navigator.pop(context);
              // Podrías navegar a MedListScreen aquí si no usaras el BottomBar
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Médicos vinculados"),
            onTap: () {
              Navigator.pop(context);
              // Futura pantalla de lista de médicos
            },
          ),
          
          const Divider(), // Línea separadora

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Configuración"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
            },
          ),
          
          const Spacer(), // Empuja lo siguiente al final de la pantalla

          // --- 3. CERRAR SESIÓN ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.red.withOpacity(0.1),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                await auth.logout();
                // Redirigir y limpiar historial para que no pueda volver atrás
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}