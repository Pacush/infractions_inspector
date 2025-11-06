import 'package:flutter/material.dart';
import 'package:infractions_inspector/components/db_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final claveController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.delayed(Duration(seconds: 1));

    final String clave = claveController.text;
    final String password = passwordController.text;

    final dbController = DBController.instance;

    final agente = await dbController.getAgentByClave(clave);
    if (agente != null) {
      final agenteClave = agente['clave'].toString();
      final agenteId = agente['id'].toString();

      final agentePassword = agente['password'];
      // ----- LÓGICA DE AUTENTICACIÓN SIMULADA -----
      if (clave == agenteClave && password == agentePassword) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('loggedUserName', agente['name']);
          await prefs.setString('loggedUserId', agenteId);
          await prefs.setString('loggedUserClave', clave);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MenuScreen()),
          );
        } catch (e) {
          setState(() {
            errorMessage = "Error al guardar la sesión: $e";
          });
        }
      } else {
        setState(() {
          errorMessage = "Contraseña incorrecta";
        });
      }
    } else {
      setState(() {
        errorMessage = "Clave incorrecta";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    claveController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inicio de Sesión")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo o Título (Opcional)
                Text(
                  "Bienvenido",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 32),

                // Campo de clave
                TextFormField(
                  controller: claveController,
                  decoration: InputDecoration(
                    labelText: "Clave",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  //keyboardType: TextInputType.number, // Teclado numérico
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor, ingrese su clave";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Campo de Contraseña
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true, // Oculta la contraseña
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor, ingrese su contraseña";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Mensaje de Error
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Botón de Inicio de Sesión o Indicador de Carga
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: login,
                      child: Text(
                        "Iniciar Sesión",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
