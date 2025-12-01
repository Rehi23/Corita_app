import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api_client.dart';
import '../../config/theme.dart';

class QrScanScreen extends StatefulWidget {
  @override
  _QrScanScreenState createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _isProcessing = false; // Para evitar lecturas múltiples
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE CONEXIÓN ---
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);
    
    // 1. Obtener ID del usuario actual
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 1; // Fallback a 1 si es prueba

    try {
      // 2. Enviar a la API (Endpoint que creamos en FastAPI)
      // POST /connect/doctor/{user_id} body: { "doctor_code": "DOC-123" }
      await ApiClient.post(
        '/connect/doctor/$userId', 
        {'doctor_code': code}
      );

      // 3. Mostrar Éxito (Diseño basado en Página 10 del PDF)
      if (!mounted) return;
      _showSuccessDialog();

    } catch (e) {
      // Manejar Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al vincular: $e"),
          backgroundColor: CoritaTheme.errorColor,
        ),
      );
      setState(() => _isProcessing = false); // Permitir intentar de nuevo
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.check_circle, color: CoritaTheme.secondaryColor, size: 50),
            SizedBox(height: 10),
            Text("Registro exitoso", textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          "Gracias por completar el proceso. Se ha conectado con su médico.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Cerrar escáner y volver al perfil
              },
              child: Text("Aceptar"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Conexión a su médico")),
      body: Stack(
        children: [
          // --- 1. CÁMARA ---
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),

          // --- 2. SUPERPOSICIÓN VISUAL (Overlay Oscuro) ---
          // Esto crea el efecto de "recuadro" para escanear
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5), 
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 3. MARCO DECORATIVO Y TEXTO ---
          Center(
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                border: Border.all(color: CoritaTheme.primaryColor, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                // Línea roja de escaneo (decorativa)
                child: Container(
                  height: 1,
                  width: 230,
                  color: Colors.red.withOpacity(0.7),
                ),
              ),
            ),
          ),

          // --- 4. TEXTO DE INSTRUCCIONES ---
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "Escanee por favor el código que su médico le proporciona",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}