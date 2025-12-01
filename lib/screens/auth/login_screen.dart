import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_input.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils.dart';
import 'register_screen.dart'; // Para navegar al registro

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Usar el Provider para loguear
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool exito = await auth.login(_emailCtrl.text, _passCtrl.text);

    if (exito) {
      // El main.dart detectará el cambio y redirigirá al Home automáticamente
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Credenciales incorrectas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO Y TÍTULO
                Image.asset('assets/images/corita_logo.png', height: 100), // Asegúrate de tener la imagen
                Text("¡Bienvenido!", style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(height: 10),
                // INPUTS
                CustomInput(
                  label: "Correo electrónico",
                  controller: _emailCtrl,
                  type: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                CustomInput(
                  label: "Contraseña",
                  controller: _passCtrl,
                  isPassword: true,
                  obscureText: _obscurePass,
                  onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass),
                  validator: (v) => v!.isEmpty ? 'Ingrese contraseña' : null,
                ),

                // OLVIDÉ CONTRASEÑA
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, // Pendiente implementar
                    child: Text("¿Olvidaste tu contraseña?"),
                  ),
                ),
                SizedBox(height: 20),

                // BOTÓN LOGIN
                SizedBox(
                  width: double.infinity,
                  child: Consumer<AuthProvider>( // Escuchar cambios para mostrar loading
                    builder: (context, auth, _) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading 
                            ? CircularProgressIndicator(color: Colors.white) 
                            : Text("Iniciar sesión"),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 20),
                Text("O ingresa a través de", style: TextStyle(color: Colors.grey)),
                SizedBox(height: 10),
                
                // BOTÓN GOOGLE (Visual)
                OutlinedButton.icon(
                  onPressed: () {}, 
                  icon: Icon(Icons.g_mobiledata, size: 30, color: Colors.red), 
                  label: Text("Google", style: TextStyle(color: Colors.black)),
                ),

                SizedBox(height: 30),
                
                // IR A REGISTRO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("¿Aún no tienes cuenta? "),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                      child: Text("Regístrate", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}