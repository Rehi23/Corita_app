import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_input.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meds_provider.dart';
import '../../core/api_client.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/medication_model.dart';

class AddMedScreen extends StatefulWidget {
  final Medication? medToEdit;

  const AddMedScreen({Key? key, this.medToEdit}) : super(key: key);

  @override
  _AddMedScreenState createState() => _AddMedScreenState();
}

class _AddMedScreenState extends State<AddMedScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  
  // NUEVO: Controlador para especificar "Otro" tipo
  late TextEditingController _otherTypeCtrl; 

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  double _dosage = 1.0;
  String _unit = 'comprimido(s)';
  
  String _selectedType = 'Pastilla'; 
  final List<String> _medTypes = ['Pastilla', 'Jarabe', 'Inyección', 'Otro'];
  bool _isOtherType = false; // Para saber si mostrar el campo extra

  final Map<String, bool> _symptoms = {
    'Dolor': false, 'Fiebre': false, 'Infección': false, 'Otro': false
  };

  @override
  void initState() {
    super.initState();
    _otherTypeCtrl = TextEditingController(); // Inicializar

    if (widget.medToEdit != null) {
      final m = widget.medToEdit!;
      _nameCtrl = TextEditingController(text: m.name);
      _dosage = m.dosageAmount;
      _unit = m.dosageUnit;
      
      // Lógica Inteligente para Tipo
      if (_medTypes.contains(m.formType) && m.formType != 'Otro') {
        _selectedType = m.formType;
        _isOtherType = false;
      } else {
        // Si el tipo guardado no está en la lista (ej. "Pomada"), es "Otro"
        _selectedType = 'Otro';
        _isOtherType = true;
        _otherTypeCtrl.text = m.formType; // Rellenar con "Pomada"
      }
      
      for (var s in m.symptoms) {
        if (_symptoms.containsKey(s)) _symptoms[s] = true;
      }
    } else {
      _nameCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _otherTypeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (widget.medToEdit == null && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('La foto es obligatoria')));
      return;
    }

    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? 1;
    String symptomsStr = _symptoms.entries.where((e) => e.value).map((e) => e.key).join(',');

    // Decidir qué tipo enviar: El del menú o lo que escribió el usuario
    final String finalType = _selectedType == 'Otro' ? _otherTypeCtrl.text.trim() : _selectedType;

    if (finalType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Especifique el tipo de medicamento')));
      return;
    }

    final fields = {
      'user_id': userId.toString(),
      'name': _nameCtrl.text,
      'dosage_amount': _dosage.toString(),
      'dosage_unit': _unit,
      'form_type': finalType, // Enviamos el tipo final
      'symptoms': symptomsStr,
    };

    try {
      if (widget.medToEdit != null) {
        await Provider.of<MedsProvider>(context, listen: false)
            .updateMedication(widget.medToEdit!.id!, fields, _imageFile);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Medicamento actualizado')));
      } else {
        await ApiClient.uploadImage(
          endpoint: '/medications/',
          imageFile: _imageFile!,
          imageFieldName: 'photo',
          fields: fields,
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Medicamento guardado')));
      }

      Provider.of<MedsProvider>(context, listen: false).fetchMedications(userId);
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.medToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Editar medicamento" : "Registro de medicamento")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FOTO
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(context: context, builder: (_) => Wrap(
                    children: [
                      ListTile(leading: Icon(Icons.camera), title: Text("Cámara"), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                      ListTile(leading: Icon(Icons.photo), title: Text("Galería"), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                    ],
                  ));
                },
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade400),
                    image: _imageFile != null 
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : (isEditing && widget.medToEdit!.photoPath.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage('${AppConstants.apiBaseUrl}/${widget.medToEdit!.photoPath}'),
                              fit: BoxFit.cover
                            )
                          : null,
                  ),
                  child: (_imageFile == null && (!isEditing || widget.medToEdit!.photoPath.isEmpty))
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.add_a_photo, size: 50, color: Colors.grey), Text("Tocar para agregar foto")],
                        )
                      : null,
                ),
              ),
              SizedBox(height: 25),

              CustomInput(label: "Nombre del medicamento", controller: _nameCtrl, validator: (v) => v!.isEmpty ? 'Requerido' : null),

              // --- SECCIÓN TIPO ---
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Tipo de medicamento", style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: _medTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (val) => setState(() {
                        _selectedType = val!;
                        _isOtherType = (val == 'Otro'); // Activar campo si es Otro
                        
                        // Lógica de unidades
                        if (val == 'Jarabe') _unit = 'ml';
                        else if (val == 'Inyección') _unit = 'dosis';
                        else if (val == 'Otro') _unit = 'unidad(es)';
                        else _unit = 'comprimido(s)';
                      }),
                      decoration: InputDecoration(
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                    
                    // --- CAMPO EXTRA SI ES OTRO ---
                    if (_isOtherType)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: CustomInput(
                          label: "Especifique el tipo (ej. Pomada, Gotas)", 
                          controller: _otherTypeCtrl,
                          validator: (v) => _isOtherType && (v == null || v.isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                  ],
                ),
              ),

              Text("Dosis", style: Theme.of(context).textTheme.titleMedium),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: CoritaTheme.secondaryColor, size: 32),
                      onPressed: () => setState(() { if(_dosage > 0.5) _dosage -= 0.5; }),
                    ),
                    Column(
                      children: [
                        Text("$_dosage", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(_unit, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: CoritaTheme.secondaryColor, size: 32),
                      onPressed: () => setState(() => _dosage += 0.5),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              Text("¿Para qué tomas esto?", style: Theme.of(context).textTheme.titleMedium),
              ..._symptoms.keys.map((key) => CheckboxListTile(
                title: Text(key),
                value: _symptoms[key],
                activeColor: CoritaTheme.secondaryColor,
                onChanged: (val) => setState(() => _symptoms[key] = val!),
              )).toList(),

              SizedBox(height: 30),

              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? "Actualizar" : "Guardar"),
              )
            ],
          ),
        ),
      ),
    );
  }
}