import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'tone_selector_screen.dart';
import '../../providers/meds_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/alarms_provider.dart';
import '../../core/api_client.dart';
import '../../models/alarm_model.dart';
import '../../config/theme.dart';

class AddAlarmScreen extends StatefulWidget {
  final Alarm? alarmToEdit;

  const AddAlarmScreen({Key? key, this.alarmToEdit}) : super(key: key);

  @override
  _AddAlarmScreenState createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  late TimeOfDay _selectedTime;
  String _selectedTone = "Alarma de naturaleza";
  String _repeatOption = "Una vez";
  bool _vibrate = true;
  final _labelCtrl = TextEditingController();
  int? _selectedMedId;
  bool _isSaving = false;

  // Lista de días para el selector personalizado
  final List<String> _weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    if (widget.alarmToEdit != null) {
      final a = widget.alarmToEdit!;
      _selectedTime = a.time;
      _selectedTone = a.tone;
      _repeatOption = a.days.join(','); // Convertir lista a texto
      _labelCtrl.text = a.label;
      _selectedMedId = a.medicationId;
      _vibrate = true;
    } else {
      _selectedTime = TimeOfDay.now();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? 1;
      Provider.of<MedsProvider>(context, listen: false).fetchMedications(userId);
    });
  }

  void _saveAlarm() async {
    if (_selectedMedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Selecciona un medicamento")));
      return;
    }

    setState(() => _isSaving = true);

    final String timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final Map<String, dynamic> alarmData = {
      "medication_id": _selectedMedId,
      "alarm_time": timeStr,
      "days": _repeatOption,
      "active": true,
      "label": _labelCtrl.text.isEmpty ? "Alarma" : _labelCtrl.text,
      "tone": _selectedTone
    };

    try {
      if (widget.alarmToEdit != null) {
        alarmData['active'] = widget.alarmToEdit!.active; 
        await Provider.of<AlarmsProvider>(context, listen: false)
            .updateAlarmFull(widget.alarmToEdit!.id!, alarmData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Alarma actualizada")));
      } else {
        await ApiClient.post('/alarms/', alarmData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Alarma creada")));
      }
      
      if (!mounted) return;
      Navigator.pop(context, true); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- MENÚ PRINCIPAL DE REPETIR ---
  void _showRepeatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Repetir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CoritaTheme.primaryColor)),
              ),
              Divider(height: 1),
              _buildRepeatOption("Una vez"),
              _buildRepeatOption("Diariamente"),
              _buildRepeatOption("Lun a Vie"),
              // 4. OPCIÓN PERSONALIZADA AGREGADA
              _buildRepeatOption("Personalizado", isCustomAction: true),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRepeatOption(String option, {bool isCustomAction = false}) {
    // Verificar si esta opción está seleccionada actualmente
    bool isSelected = false;
    if (!isCustomAction) {
      isSelected = _repeatOption == option;
    } else {
      // Si no es ninguna de las estándar, asumimos que es personalizada
      isSelected = !["Una vez", "Diariamente", "Lun a Vie"].contains(_repeatOption);
    }

    return ListTile(
      title: Text(option, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check, color: CoritaTheme.secondaryColor) : (isCustomAction ? Icon(Icons.chevron_right, color: Colors.grey) : null),
      onTap: () {
        Navigator.pop(context); // Cerrar menú principal
        if (isCustomAction) {
          _showCustomDaysDialog(); // Abrir selector de días
        } else {
          setState(() => _repeatOption = option);
        }
      },
    );
  }

  // --- DIÁLOGO DE DÍAS PERSONALIZADOS ---
  void _showCustomDaysDialog() {
    // Parsear días actuales si ya hay seleccionados
    List<String> currentDays = [];
    if (!["Una vez", "Diariamente", "Lun a Vie"].contains(_repeatOption)) {
      currentDays = _repeatOption.split(',');
    }

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder permite actualizar los checkboxes dentro del diálogo sin cerrar
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Seleccionar días"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _weekDays.map((day) {
                    final bool checked = currentDays.contains(day);
                    return CheckboxListTile(
                      title: Text(day),
                      value: checked,
                      activeColor: CoritaTheme.secondaryColor,
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            currentDays.add(day);
                          } else {
                            currentDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancelar"),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text("Aceptar", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    // Ordenar los días para que queden bonitos (Lun, Mar, Mie...)
                    currentDays.sort((a, b) => _weekDays.indexOf(a).compareTo(_weekDays.indexOf(b)));
                    
                    setState(() {
                      if (currentDays.isEmpty) {
                        _repeatOption = "Una vez";
                      } else {
                        _repeatOption = currentDays.join(',');
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final medsProvider = Provider.of<MedsProvider>(context);
    final isEditing = widget.alarmToEdit != null;

    return Scaffold(
      backgroundColor: CoritaTheme.backgroundColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black87, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? "Editar alarma" : "Agregar alarma", 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: CoritaTheme.secondaryColor, size: 32),
            onPressed: _saveAlarm,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            
            // RUEDA DE HORA
            Container(
              height: 220,
              color: Colors.white,
              child: CupertinoTheme(
                data: CupertinoThemeData(brightness: Brightness.light),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(2023, 1, 1, _selectedTime.hour, _selectedTime.minute),
                  onDateTimeChanged: (val) => setState(() => _selectedTime = TimeOfDay.fromDateTime(val)),
                ),
              ),
            ),
            
            SizedBox(height: 20),

            // SELECCIÓN DE MEDICAMENTO
            _buildSection(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedMedId,
                  hint: Text("Seleccionar medicamento", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: CoritaTheme.primaryColor),
                  items: medsProvider.medications.map((med) {
                    return DropdownMenuItem<int>(
                      value: med.id, 
                      child: Text(med.name, style: TextStyle(color: Colors.black87, fontSize: 16))
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedMedId = val),
                ),
              ),
            ),

            // OPCIONES (Tono y Repetir)
            _buildSection(
              child: Column(
                children: [
                  _buildOptionTile("Tono", _selectedTone, onTap: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ToneSelectorScreen()));
                    if (result != null) setState(() => _selectedTone = result);
                  }),
                  Divider(height: 1, indent: 15, endIndent: 15),
                  _buildOptionTile("Repetir", _repeatOption, onTap: _showRepeatOptions),
                ],
              ),
            ),

            // VIBRACIÓN
            _buildSection(
              child: SwitchListTile(
                title: Text("Vibrar al sonar", style: TextStyle(color: Colors.black87, fontSize: 16)),
                value: _vibrate,
                activeColor: CoritaTheme.secondaryColor,
                onChanged: (v) => setState(() => _vibrate = v),
              ),
            ),

            // ETIQUETA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _labelCtrl,
                style: TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Etiqueta (Opcional)",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), 
                    borderSide: BorderSide.none
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _buildOptionTile(String title, String subtitle, {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(color: Colors.black87, fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Limitamos el texto largo (ej. Lun, Mar, Mie...) para que no rompa el diseño
          Container(
            constraints: BoxConstraints(maxWidth: 150),
            child: Text(
              subtitle, 
              style: TextStyle(color: CoritaTheme.primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 5),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
      onTap: onTap,
    );
  }
}