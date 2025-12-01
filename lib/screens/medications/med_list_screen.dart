import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/meds_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import 'add_med_screen.dart';

// Importamos los widgets visuales
import '../../widgets/vital_sign_card.dart';
import '../../widgets/med_card.dart';
import '../../widgets/empty_state.dart';

class MedListScreen extends StatefulWidget {
  @override
  _MedListScreenState createState() => _MedListScreenState();
}

class _MedListScreenState extends State<MedListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId =
          Provider.of<AuthProvider>(context, listen: false).currentUser?.id ??
              1;
      Provider.of<MedsProvider>(context, listen: false)
          .fetchMedications(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Visualización de registro")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CoritaTheme.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => AddMedScreen())),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCIÓN SIGNOS VITALES (Usando el nuevo widget)
            Text("Signos Vitales",
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  VitalSignCard(
                      title: "Presión Arterial",
                      value: "120/80",
                      unit: "mmHg",
                      icon: Icons.favorite,
                      color: Colors.redAccent),
                  VitalSignCard(
                      title: "Frecuencia Card.",
                      value: "80.5",
                      unit: "BPM",
                      icon: Icons.monitor_heart,
                      color: Colors.blueAccent),
                  VitalSignCard(
                      title: "Colesterol",
                      value: "220",
                      unit: "mg/dL",
                      icon: Icons.bloodtype,
                      color: Colors.orangeAccent),
                ],
              ),
            ),

            SizedBox(height: 25),

            // SECCIÓN LISTA DE MEDICAMENTOS (Usando MedCard)
            Text("Medicamentos",
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 10),

            Consumer<MedsProvider>(
              builder: (context, medsProvider, child) {
                if (medsProvider.isLoading)
                  return Center(child: CircularProgressIndicator());
                if (medsProvider.medications.isEmpty) {
                  // --- ESTADO VACÍO BONITO ---
                  return Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: EmptyState(
                      icon: Icons.medication_liquid_outlined, // Icono de frasco
                      title: "Tu botiquín está vacío",
                      message: "Agrega tu primer medicamento usando el botón +",
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: medsProvider.medications.length,
                  itemBuilder: (context, index) {
                    final med = medsProvider.medications[index];
                    // ENVUELVE LA TARJETA EN DISMISSIBLE
                    return Dismissible(
                      key: Key(med.id.toString()), // ID Único
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20)),
                        child:
                            Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text("¿Borrar medicamento?"),
                            content: Text("Se eliminará de tu registro."),
                            actions: [
                              TextButton(
                                  child: Text("Cancelar"),
                                  onPressed: () => Navigator.pop(ctx, false)),
                              TextButton(
                                  child: Text("Borrar",
                                      style: TextStyle(color: Colors.red)),
                                  onPressed: () => Navigator.pop(ctx, true)),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        Provider.of<MedsProvider>(context, listen: false)
                            .deleteMedication(med.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Medicamento eliminado")));
                      },

                      // HACER LA TARJETA TOCABLE PARA EDITAR
                      child: MedCard(
                        name: med.name,
                        dosage: med.dosageAmount.toString(),
                        unit: med.dosageUnit,
                        formType: med.formType,
                        photoPath: med.photoPath,
                        onTap: () {
                          // Navegar a edición
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AddMedScreen(medToEdit: med)));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
