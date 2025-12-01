import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_alarm_screen.dart';
import '../../providers/alarms_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/empty_state.dart';

class AlarmListScreen extends StatefulWidget {
  @override
  _AlarmListScreenState createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAlarms());
  }

  void _loadAlarms() {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? 1;
    Provider.of<AlarmsProvider>(context, listen: false).fetchAlarms(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Historial de alarmas")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
              context, MaterialPageRoute(builder: (_) => AddAlarmScreen()));
          if (result == true) _loadAlarms();
        },
        label: Text("Agregar"),
        icon: Icon(Icons.add_alarm),
        backgroundColor: CoritaTheme.secondaryColor,
      ),
      body: Consumer<AlarmsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading)
            return Center(child: CircularProgressIndicator());
          if (provider.alarms.isEmpty){
            return EmptyState(
              icon: Icons.alarm_off,
              title: "Todo tranquilo",
              message: "No tienes alarmas programadas por ahora. ¡Descansa!",
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: provider.alarms.length,
            itemBuilder: (context, index) {
              final alarm = provider.alarms[index];

              // --- 1. DISMISSIBLE (DESLIZAR PARA BORRAR) ---
              return Dismissible(
                key: Key(alarm.id.toString()), // Clave única obligatoria
                direction: DismissDirection
                    .endToStart, // Solo deslizar de derecha a izquierda
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.delete, color: Colors.white, size: 30),
                ),
                confirmDismiss: (direction) async {
                  // Diálogo de confirmación
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text("¿Eliminar alarma?"),
                      actions: [
                        TextButton(
                            child: Text("Cancelar"),
                            onPressed: () => Navigator.pop(ctx, false)),
                        TextButton(
                            child: Text("Eliminar",
                                style: TextStyle(color: Colors.red)),
                            onPressed: () => Navigator.pop(ctx, true)),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  // Borrar de verdad
                  Provider.of<AlarmsProvider>(context, listen: false)
                      .deleteAlarm(alarm.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Alarma eliminada")));
                },

                // --- 2. TARJETA TOCABLE (EDITAR) ---
                child: GestureDetector(
                  onTap: () async {
                    // Navegar a pantalla de edición pasando la alarma actual
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AddAlarmScreen(alarmToEdit: alarm)));
                    if (result == true)
                      _loadAlarms(); // Recargar si hubo cambios
                  },
                  child: Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alarm.time.format(context),
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: alarm.active
                                        ? Colors.black
                                        : Colors.grey),
                              ),
                              Text("${alarm.label} • ${alarm.days.join(', ')}",
                                  style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                          Switch(
                            value: alarm.active,
                            activeColor: CoritaTheme.secondaryColor,
                            onChanged: (val) {
                              Provider.of<AlarmsProvider>(context,
                                      listen: false)
                                  .toggleAlarmActive(index, val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
