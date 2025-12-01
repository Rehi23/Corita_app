import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../medications/med_list_screen.dart';
import '../medications/add_med_screen.dart';
import '../alarms/alarm_list_screen.dart';
import '../doctor/contact_doctor_screen.dart';
import '../settings/settings_screen.dart';
// import '../../widgets/dashboard_button.dart'; // Importamos los nuevos widgets
import '../../widgets/drawer_menu.dart'; // Importamos el menú lateral

import '../../config/constants.dart'; // <--- AGREGA ESTA LÍNEA
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meds_provider.dart';
import '../../providers/alarms_provider.dart';
import '../../models/alarm_model.dart';
import '../../core/tts_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _mainPages = [
    _HomeDashboard(),
    MedListScreen(),
    AlarmListScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;

      TtsService().speak("Bienvenido a Corita, ${user?.fullName ?? ''}.");

      // --- NUEVO: CARGAR DATOS PARA EL DASHBOARD ---
      if (user?.id != null) {
        // Descargamos medicinas y alarmas silenciosamente
        Provider.of<MedsProvider>(context, listen: false)
            .fetchMedications(user!.id!);
        Provider.of<AlarmsProvider>(context, listen: false)
            .fetchAlarms(user.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Drawer (Menú lateral) agregado aquí
      drawer: const DrawerMenu(),

      body: _mainPages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: CoritaTheme.secondaryColor.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.medication_outlined),
              selectedIcon: Icon(Icons.medication),
              label: 'Registro'),
          NavigationDestination(
              icon: Icon(Icons.alarm_outlined),
              selectedIcon: Icon(Icons.alarm),
              label: 'Alarmas'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes'),
        ],
      ),
    );
  }
}

// --- NUEVO DISEÑO DEL DASHBOARD ---
class _HomeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    // --- LÓGICA DE PRÓXIMA DOSIS ---
    // Escuchamos los cambios en Alarmas y Medicamentos
    final alarmsProvider = Provider.of<AlarmsProvider>(context);
    final medsProvider = Provider.of<MedsProvider>(context);

    String nextMedName = "Todo listo";
    String nextMedTime = "por hoy";
    bool hasPending = false;

    if (alarmsProvider.alarms.isNotEmpty) {
      final now = TimeOfDay.now();
      final nowMinutes = now.hour * 60 + now.minute;

      // 1. Filtrar solo alarmas activas
      final activeAlarms =
          alarmsProvider.alarms.where((a) => a.active).toList();

      if (activeAlarms.isNotEmpty) {
        // 2. Ordenarlas por hora (de la más temprana a la más tarde)
        activeAlarms.sort((a, b) {
          final aMin = a.time.hour * 60 + a.time.minute;
          final bMin = b.time.hour * 60 + b.time.minute;
          return aMin.compareTo(bMin);
        });

        // 3. Buscar la primera alarma que sea DESPUÉS de ahora
        Alarm? nextAlarm;
        try {
          nextAlarm = activeAlarms.firstWhere(
              (a) => (a.time.hour * 60 + a.time.minute) > nowMinutes);
        } catch (e) {
          // Si no hay más hoy (ej. son las 10PM y la última fue a las 8PM),
          // la próxima es la primera de la lista (es decir, la primera de mañana)
          nextAlarm = activeAlarms.first;
        }

        // 4. Obtener el nombre del medicamento usando el ID
        try {
          final med = medsProvider.medications
              .firstWhere((m) => m.id == nextAlarm!.medicationId);
          nextMedName = med.name;
          nextMedTime =
              nextAlarm.time.format(context); // Formato bonito (8:00 PM)
          hasPending = true;
        } catch (e) {
          nextMedName = "Medicamento no encontrado";
        }
      }
    }
    // ---------------------------------

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Column(
        children: [
          // --- CABECERA ---
          Container(
            padding: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CoritaTheme.primaryColor,
                  CoritaTheme.primaryColor.withOpacity(0.8)
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SALUDO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hola,",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18)),
                          Text(
                            user?.fullName.split(' ')[0] ?? 'Paciente',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: user?.profilePicture != null
                            ? NetworkImage(
                                '${AppConstants.apiBaseUrl}/${user!.profilePicture}')
                            : null,
                        child: user?.profilePicture == null
                            ? Icon(Icons.person,
                                size: 30, color: CoritaTheme.primaryColor)
                            : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25),

                // --- TARJETA PRÓXIMA DOSIS (DINÁMICA) ---
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        // Cambia el icono si no hay pendientes
                        child: Icon(
                            hasPending
                                ? Icons.access_alarm
                                : Icons.check_circle,
                            color: hasPending
                                ? CoritaTheme.primaryColor
                                : Colors.green,
                            size: 28),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hasPending ? "Próxima dosis:" : "Estado:",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                            Text(
                              hasPending
                                  ? "$nextMedName a las $nextMedTime"
                                  : "Sin recordatorios pendientes",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- GRID MENU ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _GridCard(
                    title: "Mis Signos",
                    icon: Icons.monitor_heart,
                    color: Colors.blueAccent,
                    onTap: () {
                      final state =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      state?.setState(() => state._currentIndex = 1);
                    },
                  ),
                  _GridCard(
                    title: "Mis Alarmas",
                    icon: Icons.alarm,
                    color: Colors.orangeAccent,
                    onTap: () {
                      final state =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      state?.setState(() => state._currentIndex = 2);
                    },
                  ),
                  _GridCard(
                    title: "Nuevo Medicamento",
                    icon: Icons.add_circle,
                    color: CoritaTheme.secondaryColor,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AddMedScreen())),
                  ),
                  _GridCard(
                    title: "Contactar Médico", // Cambio de nombre
                    icon: Icons.chat, // Icono de Chat
                    color: Colors.purpleAccent,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ContactDoctorScreen())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET NUEVO: TARJETA DE CUADRÍCULA ---
class _GridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GridCard(
      {required this.title,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Círculo de fondo para el icono
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            SizedBox(height: 10),
            Padding(
              // Agregamos padding horizontal para que el texto no toque los bordes
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2, // Permitir 2 líneas
                overflow:
                    TextOverflow.ellipsis, // Puntos suspensivos si se pasa
                style: TextStyle(
                    fontSize: 15, // REDUCIDO: Antes era 16
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
