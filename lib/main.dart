import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// --- IMPORTACIONES DE CONFIGURACIÓN ---
import 'config/theme.dart';

// --- IMPORTACIONES DE PROVIDERS (ESTADO) ---
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/meds_provider.dart';
import 'providers/alarms_provider.dart';

// --- IMPORTACIONES DE PANTALLAS ---
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  // Asegura que los bindings de Flutter estén inicializados antes de correr la app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppState());
}

/// Widget intermedio para inicializar todos los Providers
/// Esto permite que cualquier parte de la App acceda a la Auth, Settings o Meds
class AppState extends StatelessWidget {
  const AppState({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => MedsProvider()),
        ChangeNotifierProvider(create: (_) => AlarmsProvider()),
      ],
      child: const MyApp(),
    );
  }
}

/// La raíz visual de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el SettingsProvider para aplicar cambios de accesibilidad en tiempo real
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'CORITA',
      debugShowCheckedModeBanner:
          false, // Quita la etiqueta "Debug" de la esquina

      // --- TEMA VISUAL ---
      // Usamos el tema definido en config/theme.dart
      theme: CoritaTheme.lightTheme,

      // --- ACCESIBILIDAD (Texto Grande) ---
      // Este builder envuelve toda la app y escala el texto según la configuración
      builder: (context, child) {
        // Obtenemos la escala actual (1.0 es normal, 1.2 es grande, etc.)
        final double scaleFactor = settings.textScaleFactor;

        return MediaQuery(
          // Forzamos el factor de escala de texto en toda la app
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scaleFactor),
          ),
          child: child!,
        );
      },

      // --- NAVEGACIÓN PRINCIPAL ---
      // Decidimos qué pantalla mostrar basándonos en si el usuario está autenticado
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Si está cargando (revisando token guardado), mostramos un spinner
          if (auth.isLoading) {
            return const Scaffold(
              body: Center(
                child:
                    CircularProgressIndicator(color: CoritaTheme.primaryColor),
              ),
            );
          }
          // Si está autenticado, vamos al Menú Principal
          if (auth.isAuth) {
            return HomeScreen();
          }
          // Si no, vamos al Login
          return LoginScreen();
        },
      ),
    );
  }
}
