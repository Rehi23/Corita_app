import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <--- IMPORTANTE
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_input.dart';
import '../../config/theme.dart';
import '../../config/constants.dart'; // Para URL base

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Imagen
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Controladores
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _nssCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _historyCtrl;
  late TextEditingController _otherAllergyCtrl;

  String? _gender;
  String? _bloodType;
  String? _allergy;
  bool _isOtherAllergy = false;

  final List<String> _genders = ['Masculino', 'Femenino'];
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _allergiesList = ['Ninguna', 'Polen', 'Penicilina', 'Mariscos', 'Otro'];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _nssCtrl = TextEditingController(text: user?.nss ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone.replaceAll('+52', '') ?? '');
    _dobCtrl = TextEditingController(text: user?.birthDate?.toIso8601String().split('T')[0] ?? '');
    _historyCtrl = TextEditingController(text: user?.medicalHistory ?? '');
    
    String currentAllergy = user?.allergies ?? 'Ninguna';
    if (!_allergiesList.contains(currentAllergy)) {
      _allergy = 'Otro';
      _otherAllergyCtrl = TextEditingController(text: currentAllergy);
      _isOtherAllergy = true;
    } else {
      _allergy = currentAllergy;
      _otherAllergyCtrl = TextEditingController();
    }

    _gender = user?.gender;
    _bloodType = user?.bloodType;
  }

  // --- SELECCIONAR FOTO ---
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(leading: Icon(Icons.camera), title: Text("Cámara"), onTap: () async {
            Navigator.pop(context);
            final picked = await _picker.pickImage(source: ImageSource.camera);
            if (picked != null) setState(() => _imageFile = File(picked.path));
          }),
          ListTile(leading: Icon(Icons.photo), title: Text("Galería"), onTap: () async {
            Navigator.pop(context);
            final picked = await _picker.pickImage(source: ImageSource.gallery);
            if (picked != null) setState(() => _imageFile = File(picked.path));
          }),
        ],
      )
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime(1960), firstDate: DateTime(1920), lastDate: DateTime.now()
    );
    if (picked != null) {
      setState(() => _dobCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}");
    }
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final finalAllergy = _allergy == 'Otro' ? _otherAllergyCtrl.text : _allergy;

    final Map<String, String> updateData = {
      "phone": "+52${_phoneCtrl.text}",
      "gender": _gender ?? "Masculino",
      "birth_date": _dobCtrl.text,
      "blood_type": _bloodType ?? "O+",
      "allergies": finalAllergy ?? "Ninguna",
      "medical_history": _historyCtrl.text
    };

    try {
      // Ahora enviamos la imagen también
      await Provider.of<AuthProvider>(context, listen: false).updateProfile(updateData, _imageFile);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Datos actualizados")));
      Navigator.pop(context); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al actualizar")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    // URL de la foto del servidor (si existe)
    // Nota: Asegúrate que tu User model tenga el campo profilePicture mapeado del JSON
    final String? serverPhotoUrl = (user?.profilePicture != null && user!.profilePicture!.isNotEmpty)
        ? '${AppConstants.apiBaseUrl}/${user.profilePicture}'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text("Editar Perfil"),
        // YA NO HAY BOTÓN AQUÍ ARRIBA
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- AVATAR CON CÁMARA (El cambio que pediste) ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                        border: Border.all(color: CoritaTheme.primaryColor, width: 2),
                        image: _imageFile != null
                            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                            : (serverPhotoUrl != null 
                                ? DecorationImage(image: NetworkImage(serverPhotoUrl), fit: BoxFit.cover)
                                : null),
                      ),
                      child: (_imageFile == null && serverPhotoUrl == null)
                          ? Icon(Icons.person, size: 80, color: Colors.grey[600])
                          : null,
                    ),
                    // Botón flotante de cámara
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage, // Abre el selector
                        child: CircleAvatar(
                          backgroundColor: CoritaTheme.secondaryColor,
                          radius: 20,
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 30),

              // --- DATOS FIJOS ---
              _SectionHeader("Identificación (No editable)"),
              CustomInput(label: "Nombre completo", controller: _nameCtrl, icon: Icons.person, readOnly: true),
              CustomInput(label: "Correo electrónico", controller: _emailCtrl, icon: Icons.email, readOnly: true),
              CustomInput(label: "NSS", controller: _nssCtrl, icon: Icons.badge, readOnly: true),
              
              SizedBox(height: 20),

              // --- DATOS EDITABLES ---
              _SectionHeader("Datos Personales"),
              CustomInput(label: "Teléfono", controller: _phoneCtrl, type: TextInputType.phone, icon: Icons.phone, hint: "10 dígitos"),
              
              _DropdownLabel("Género"),
              DropdownButtonFormField<String>(
                value: _gender,
                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gender = v),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.white),
              ),
              SizedBox(height: 15),

              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(child: CustomInput(label: "Fecha de nacimiento", controller: _dobCtrl, icon: Icons.calendar_today)),
              ),

              _SectionHeader("Información Médica"),
              
              _DropdownLabel("Tipo de Sangre"),
              DropdownButtonFormField<String>(
                value: _bloodType,
                items: _bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _bloodType = v),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.white),
              ),
              SizedBox(height: 15),

              _DropdownLabel("Alergias"),
              DropdownButtonFormField<String>(
                value: _allergy,
                items: _allergiesList.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() { _allergy = v; _isOtherAllergy = (v == 'Otro'); }),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.white),
              ),
              
              if (_isOtherAllergy)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: CustomInput(label: "Especifique su alergia", controller: _otherAllergyCtrl),
                ),

              SizedBox(height: 15),
              CustomInput(label: "Antecedentes médicos", controller: _historyCtrl, hint: "Ej. Diabetes..."),

              SizedBox(height: 30),
              
              // BOTÓN GUARDAR ABAJO (ÚNICO)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: Text("Guardar Cambios"),
                  style: ElevatedButton.styleFrom(backgroundColor: CoritaTheme.secondaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 15, top: 10), child: Text(title, style: TextStyle(color: CoritaTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold)));
  }
}

class _DropdownLabel extends StatelessWidget {
  final String label;
  const _DropdownLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 8, left: 5), child: Text(label, style: Theme.of(context).textTheme.titleMedium));
  }
}