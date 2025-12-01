import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/constants.dart'; // Para leer phpApiUrl
import '../../config/theme.dart';

class ContactDoctorScreen extends StatefulWidget {
  @override
  _ContactDoctorScreenState createState() => _ContactDoctorScreenState();
}

class _ContactDoctorScreenState extends State<ContactDoctorScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Actualizar chat cada 3 segundos (Polling)
    _timer = Timer.periodic(Duration(seconds: 3), (timer) => _loadMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- 1. LEER MENSAJES DEL SERVIDOR PHP ---
  Future<void> _loadMessages() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.id == null) return;

    // URL: api/chat_movil.php?action=read&id_paciente=1
    final url = Uri.parse('${AppConstants.phpApiUrl}/chat_movil.php?action=read&id_paciente=${user!.id}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final newMessages = jsonResponse['data'] as List;
          
          // Solo actualizamos si hay cambios para evitar parpadeos
          if (newMessages.length != _messages.length) {
            setState(() {
              _messages = newMessages;
              _isLoading = false;
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      print("Error cargando chat: $e");
    }
  }

  // --- 2. ENVIAR MENSAJE AL SERVIDOR PHP ---
// --- 2. ENVIAR MENSAJE AL SERVIDOR PHP (CORREGIDO) ---
  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.id == null) return;

    // Guardamos el texto temporalmente por si falla
    final tempText = text;
    _msgCtrl.clear(); // Limpiamos visualmente

    final url = Uri.parse('${AppConstants.phpApiUrl}/chat_movil.php?action=send&id_paciente=${user!.id}');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mensaje": tempText,
          "user_id": user!.id
        }),
      );

      print("Respuesta del servidor: ${response.body}"); // <-- VER EN CONSOLA

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'success') {
        _loadMessages(); // Si fue éxito, recargamos
        _scrollToBottom();
      } else {
        // SI HUBO ERROR EN PHP, LO MOSTRAMOS EN PANTALLA
        _msgCtrl.text = tempText; // Devolvemos el texto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${jsonResponse['message']}"),
            backgroundColor: Colors.red,
          )
        );
      }

    } catch (e) {
      _msgCtrl.text = tempText;
      print("Error de conexión: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error de conexión")));
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F2F5), // Fondo gris chat
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: CoritaTheme.primaryColor,
              child: Icon(Icons.support_agent, color: Colors.white, size: 20),
              radius: 18,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Chat con Médico", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("En línea", style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --- LISTA DE MENSAJES ---
          Expanded(
            child: _messages.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Escribe 'Hola' para contactar a tu médico", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(15),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      // PHP nos devuelve 'is_from_patient' como booleano
                      final bool isMe = msg['is_from_patient'] == true;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? CoritaTheme.primaryColor : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                              bottomLeft: isMe ? Radius.circular(15) : Radius.circular(0),
                              bottomRight: isMe ? Radius.circular(0) : Radius.circular(15),
                            ),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                          ),
                          child: Text(
                            msg['content'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // --- INPUT DE TEXTO ---
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: InputDecoration(
                          hintText: "Escribe un mensaje...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: CircleAvatar(
                      backgroundColor: CoritaTheme.secondaryColor,
                      radius: 22,
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
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