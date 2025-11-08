import 'package:flutter/material.dart';
import 'package:infractions_inspector/components/app_bar.dart';
import 'package:infractions_inspector/screens/consultar_infracciones_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crear_infraccion_screen.dart';
import 'login_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _userClave = '';
  String _userId = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userClave = prefs.getString('loggedUserClave') ?? 'Usuario Desconocido';
      _userId = prefs.getString('loggedUserId') ?? '';
      _userName = prefs.getString('loggedUserName') ?? '';
    });
  }

  // Cerrar sesión
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Borrar la clave de SharedPreferences
    await prefs.remove('loggedUserClave');
    await prefs.remove('loggedUserId');
    await prefs.remove('loggedUserName');

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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Menú',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Usuario: $_userName',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit_document),
              title: Text('Crear infracción'),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => CrearInfraccionScreen(),
                  ),
                );
                //Navigator.pop(context); // Close drawer
                // Add navigation code here
              },
            ),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Consultar infracciones'),
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ConsultarInfraccionScreen(),
                  ),
                );
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
      appBar: generateAppBar(context, "Menú principal"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Bienvenido ${_userName.substring(0, _userName.indexOf(" "))}",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            Text(
              "Utliza el menú lateral para acceder a las opciones",
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
