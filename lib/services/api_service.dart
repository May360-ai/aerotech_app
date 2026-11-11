import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/usuario_model.dart';
import '../models/vuelo_model.dart';
import '../models/reserva_model.dart';

class ApiService {
  // Instancia única (Singleton)
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _jwtToken;
  Usuario? _usuarioActual;

  String? get jwtToken => _jwtToken;
  Usuario? get usuarioActual => _usuarioActual;
  bool get isAuthenticated => _jwtToken != null;

  void logout() {
    _jwtToken = null;
    _usuarioActual = null;
  }

  // POST /api/usuarios/registro
  Future<Usuario> registrarUsuario({
    required String nombre,
    required String correo,
    required String cedulaRuc,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/usuarios/registro');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'cedula_ruc': cedulaRuc,
        'password': password,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Usuario.fromJson(data['usuario'] ?? data);
    } else {
      throw Exception(data['mensaje'] ?? 'Error al registrar el usuario');
    }
  }

  // POST /api/auth/login
  Future<bool> login(String correo, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'password': password}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 && data['token'] != null) {
      _jwtToken = data['token'];
      if (data['usuario'] != null) {
        _usuarioActual = Usuario.fromJson(data['usuario']);
      }
      return true;
    } else {
      throw Exception(data['mensaje'] ?? 'Credenciales incorrectas');
    }
  }

  // GET /api/vuelos (Público)
  Future<List<Vuelo>> obtenerVuelos() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/vuelos');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Vuelo.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar catálogo de vuelos (${response.statusCode})');
    }
  }

  // POST /api/reservas (Requiere Token)
  Future<Reserva> crearReserva({
    required int vueloId,
    required int cantidad,
  }) async {
    if (!isAuthenticated) throw Exception('Sesión expirada o no autenticado.');

    final url = Uri.parse('${ApiConfig.baseUrl}/reservas');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_jwtToken',
      },
      body: jsonEncode({
        'vuelo_id': vueloId,
        'cantidad': cantidad,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Reserva.fromJson(data['reserva'] ?? data);
    } else {
      throw Exception(data['mensaje'] ?? 'Error al procesar la reserva');
    }
  }

  // GET /api/reservas/{id}/comprobante-xml (Interoperabilidad SOA XML)
  Future<String> obtenerComprobanteXml(int reservaId) async {
    if (!isAuthenticated) throw Exception('No autenticado.');

    final url = Uri.parse('${ApiConfig.baseUrl}/reservas/$reservaId/comprobante-xml');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_jwtToken',
        'Accept': 'application/xml',
      },
    );

    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    } else {
      throw Exception('No se pudo generar el comprobante XML (${response.statusCode})');
    }
  }
}