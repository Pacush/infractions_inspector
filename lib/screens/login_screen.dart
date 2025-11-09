import 'package:flutter/material.dart';
import 'package:infractions_inspector/services/db_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final claveController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  bool passwordVisible = false;

  Future<void> login() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final String clave = claveController.text;
    final String password = passwordController.text;
    final dbController = DBController.instance;

    final agente = await dbController.getAgentByClave(clave);
    if (agente != null) {
      final agenteClave = agente['clave'].toString();
      final agenteId = agente['id'].toString();
      final agentePassword = agente['password'];

      // Clave and Contraseña verification
      if (clave == agenteClave && password == agentePassword) {
        try {
          // Saves the information of the User logged in into SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('loggedUserName', agente['name']);
          await prefs.setString('loggedUserId', agenteId);
          await prefs.setString('loggedUserClave', clave);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MenuScreen()),
          );
        } catch (e) {
          setState(() {
            errorMessage =
                "Error al guardar la sesión. Por favor intente más tarde";
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
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo (In case lgo.png doesn't load, "logo_placeholder" will show up)
                Image.asset(
                  'assets/images/logo.png',
                  errorBuilder:
                      (context, error, stackTrace) => Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          "logo_placeholder",
                          textAlign: TextAlign.center,
                        ),
                      ),
                ),
                Text(
                  "Bienvenido",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 32),

                // Clave TextField
                TextFormField(
                  controller: claveController,
                  decoration: InputDecoration(
                    labelText: "Clave",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor, ingrese su clave";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Contraseña TextField
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          passwordVisible = !passwordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !passwordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor, ingrese su contraseña";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Error message text in case user is not found or password is incorrect
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Login button or Loading icon depending on current state
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
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
