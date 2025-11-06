import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart'; // Importamos el login para navegar de regreso

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _userClave = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  // Método para cargar el ID y mostrarlo (opcional)
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userClave = prefs.getString('loggedUserClave') ?? 'Usuario Desconocido';
    });
  }

  // Método para cerrar sesión
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Borrar la clave de SharedPreferences
    await prefs.remove('loggedUserClave');

    // 2. Regresar a la pantalla de Login
    // Usamos pushReplacement para que no pueda "volver" al menú
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 87, 34),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Menú',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Usuario: $_userClave',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit_document),
              title: Text('Crear infracción'),
              onTap: () {
                // TODO: Navigate to create infraction screen
                Navigator.pop(context); // Close drawer
                // Add navigation code here
              },
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Consultar infracciones'),
              onTap: () {
                // TODO: Navigate to search infractions screen
                Navigator.pop(context); // Close drawer
                // Add navigation code here
              },
            ),
            Divider(), // Adds a line separator
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context); // Close drawer first
                _logout(); // Then logout
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          "Menú Principal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 255, 87, 34),
        iconTheme: IconThemeData(
          color: Colors.white,
        ), // Makes drawer icon white
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "¡Inicio de sesión exitoso!",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            Text(
              "Clave de usuario: $_userClave",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            // Aquí irían tus botones:
            // - Registrar Infracción
            // - Ver Registros
            // - etc.
          ],
        ),
      ),
    );
  }
}
