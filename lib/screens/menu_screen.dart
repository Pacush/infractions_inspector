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
  String userName = '';

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('loggedUserName') ?? '';
    });
  }

  /// Logout, clears SharedPreferences variables and returns to login_screen
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('loggedUserClave');
    await prefs.remove('loggedUserId');
    await prefs.remove('loggedUserName');

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sandwich menu on top left corner
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
                    'Usuario: $userName',
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
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                logout();
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
              "Bienvenido $userName",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            Text(
              "Utliza el menú lateral para acceder a las opciones",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
