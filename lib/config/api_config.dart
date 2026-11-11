import 'package:flutter/foundation.dart';

class ApiConfig {
  // Cambiar esta bandera a true si se va a probar contra el backend en Render
  static const bool useProduction = true;
  static const String _productionUrl = 'https://aerotech-back.onrender.com/api';

  static String get baseUrl {
    if (useProduction) {
      return _productionUrl;
    }
    // Si corre en Web o Desktop local
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    return 'http://10.0.2.2:5000/api';
  }
}