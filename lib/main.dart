import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'screens/vuelos_screen.dart'; // <-- cambia por tu pantalla principal
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroAndes - Reservas de Vuelos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: FutureBuilder<void>(
        future: ApiService().cargarSesion(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (ApiService().isAuthenticated) {
            return const VuelosScreen(); // <-- tu pantalla principal autenticada
          }
          return const LandingScreen();
        },
      ),
    );
  }
}