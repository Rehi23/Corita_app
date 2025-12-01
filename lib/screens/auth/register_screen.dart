import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- ESTA ERA LA LÍNEA FALTANTE

import '../../widgets/custom_input.dart';
import '../../core/utils.dart';
import '../../core/api_client.dart'; 

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;

  // --- CONTROLADORES DE TEXTO ---
  // Paso 1
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  // Paso 2
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  // Paso 3
  final _nssCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String _gender = 'Masculino';
  DateTime? _selectedDate;
  // Paso 4
  String _bloodType = 'O+';
  String _allergy = 'Ninguna';
  final _otherAllergyCtrl = TextEditingController();
  final _historyCtrl = TextEditingController();

  // Listas para dropdowns
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _allergiesList = ['Ninguna', 'Polen', 'Penicilina', 'Mariscos', 'Otro'];

  // --- NAVEGACIÓN ENTRE PASOS ---
  void _nextPage() {
    _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    setState(() => _currentPage++);
  }

  void _prevPage() {
    _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    setState(() => _currentPage--);
  }

  // --- SELECTOR DE FECHA ---
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1960), 
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobCtrl.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // --- ENVIAR REGISTRO A LA API ---
  void _submitRegister() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor corrige los errores')));
      return;
    }

    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Las contraseñas no coinciden')));
      return;
    }

    // Preparar JSON
    final Map<String, dynamic> userData = {
      "full_name": _nameCtrl.text,
      "email": _emailCtrl.text,
      "phone": "+52${_phoneCtrl.text}", 
      "password": _passCtrl.text,
      "gender": _gender,
      "birth_date": _selectedDate?.toIso8601String().split('T')[0] ?? "2000-01-01",
      "nss": _nssCtrl.text,
      "blood_type": _bloodType,
      "allergies": _allergy == 'Otro' ? _otherAllergyCtrl.text : _allergy,
      "medical_history": _historyCtrl.text
    };

    try {
      await ApiClient.post('/register', userData);
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Registro Exitoso"),
          content: Text("Gracias por completar el proceso."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: Text("Aceptar"),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registro (${_currentPage + 1}/4)"),
        leading: _currentPage > 0 
          ? IconButton(icon: Icon(Icons.arrow_back), onPressed: _prevPage)
          : null,
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(), 
          children: [
            // --- PASO 1: DATOS CONTACTO ---
            _buildStep(
              title: "Datos de Contacto",
              children: [
                CustomInput(label: "Nombre completo", controller: _nameCtrl, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                CustomInput(label: "Correo electrónico", controller: _emailCtrl, type: TextInputType.emailAddress, validator: Validators.validateEmail),
                CustomInput(
                  label: "Teléfono", 
                  controller: _phoneCtrl, 
                  type: TextInputType.phone, 
                  hint: "10 dígitos",
                  // Aquí es donde marcaba error, ahora con 'services.dart' importado funcionará:
                  formatters: [Validators.nssInputFormatter()[0], LengthLimitingTextInputFormatter(10)], 
                ),
              ],
              onNext: _nextPage,
            ),

            // --- PASO 2: CONTRASEÑA ---
            _buildStep(
              title: "Seguridad",
              children: [
                CustomInput(
                  label: "Contraseña",
                  controller: _passCtrl,
                  isPassword: true,
                  obscureText: _obscurePass,
                  onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass),
                  validator: Validators.validatePassword,
                ),
                CustomInput(
                  label: "Confirmar contraseña",
                  controller: _confirmPassCtrl,
                  isPassword: true,
                  obscureText: _obscurePass,
                ),
              ],
              onNext: _nextPage,
            ),

            // --- PASO 3: DATOS PERSONALES (NSS) ---
            _buildStep(
              title: "Datos Personales",
              children: [
                Text("Género", style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    Expanded(child: RadioListTile(title: Text("Masc."), value: "Masculino", groupValue: _gender, onChanged: (v) => setState(() => _gender = v.toString()))),
                    Expanded(child: RadioListTile(title: Text("Fem."), value: "Femenino", groupValue: _gender, onChanged: (v) => setState(() => _gender = v.toString()))),
                  ],
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: CustomInput(label: "Fecha de nacimiento", controller: _dobCtrl, icon: Icons.calendar_today),
                  ),
                ),
                CustomInput(
                  label: "Número de Seguridad Social (NSS)",
                  controller: _nssCtrl,
                  type: TextInputType.number,
                  formatters: Validators.nssInputFormatter(),
                  validator: Validators.validateNSS,
                ),
              ],
              onNext: _nextPage,
            ),

            // --- PASO 4: DATOS MÉDICOS ---
            _buildStep(
              title: "Datos Médicos",
              isLast: true,
              children: [
                DropdownButtonFormField(
                  value: _bloodType,
                  items: _bloodTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _bloodType = v.toString()),
                  decoration: InputDecoration(labelText: "Tipo de sangre"),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField(
                  value: _allergy,
                  items: _allergiesList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _allergy = v.toString()),
                  decoration: InputDecoration(labelText: "Alergias"),
                ),
                if (_allergy == 'Otro')
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CustomInput(label: "Especifique alergia", controller: _otherAllergyCtrl),
                  ),
                SizedBox(height: 20),
                CustomInput(label: "Antecedentes médicos", controller: _historyCtrl, hint: "Ej. Diabetes, Hipertensión..."),
              ],
              onNext: _submitRegister,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required String title, required List<Widget> children, required VoidCallback onNext, bool isLast = false}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
          SizedBox(height: 20),
          ...children,
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: onNext,
            child: Text(isLast ? "Finalizar Registro" : "Siguiente"),
          ),
        ],
      ),
    );
  }
}