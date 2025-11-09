import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final String? userClave = prefs.getString('loggedUserClave');

  Widget initialScreen = (userClave == null) ? LoginScreen() : MenuScreen();

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  // Add this test function that will be called from the floating button
  /*Future<void> runTestFunction() async {
    final b = await DBController.instance.database;
    List<Map<String, dynamic>> a = await b.rawQuery(
      'SELECT * FROM Infractions WHERE agent_id = 4',
    );
    for (dynamic queri in a) {
      queri;
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /*builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(builder: (context) => child!),
            OverlayEntry(
              builder:
                  (context) => Positioned(
                    right: 16,
                    top: MediaQuery.of(context).size.height - 140,
                    child: FloatingActionButton(
                      heroTag: 'testButton',
                      backgroundColor: Colors.red,
                      onPressed: runTestFunction,
                      child: const Icon(Icons.bug_report),
                    ),
                  ),
            ),
          ],
        );
      },*/
      title: 'Infractions Inspector',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 255, 87, 34),
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: initialScreen,
      debugShowCheckedModeBanner: false,
    );
  }
}
