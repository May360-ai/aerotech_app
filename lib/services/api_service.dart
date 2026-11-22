import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/usuario_model.dart';
import '../models/vuelo_model.dart';
import '../models/reserva_model.dart';
import '../models/origen_model.dart';

class ConcurrencyException implements Exception {
  final String message;
  ConcurrencyException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _tokenKey = 'jwt_token';
  static const String _usuarioKey = 'usuario_json';

  String? _jwtToken;
  Usuario? _usuarioActual;

  String? get jwtToken => _jwtToken;
  Usuario? get usuarioActual => _usuarioActual;
  bool get isAuthenticated => _jwtToken != null;

  bool _tokenExpirado(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return false;
      final payloadStr = utf8.decode(
        base64Url.decode(base64Url.normalize(partes[1])),
      );
      final payload = jsonDecode(payloadStr);
      if (payload is Map<String, dynamic> && payload['exp'] is num) {
        final exp = DateTime.fromMillisecondsSinceEpoch(
          (payload['exp'] as num).toInt() * 1000,
        );
        return DateTime.now().isAfter(exp);
      }
    } catch (_) {}
    return false;
  }

  Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final usuarioJson = prefs.getString(_usuarioKey);

    if (token != null && token.isNotEmpty) {
      if (_tokenExpirado(token)) {
        await logout();
        return;
      }
      _jwtToken = token;
      if (usuarioJson != null && usuarioJson.isNotEmpty) {
        try {
          _usuarioActual = Usuario.fromJson(jsonDecode(usuarioJson));
        } catch (_) {
          _usuarioActual = null;
        }
      }
    }
  }

  Future<void> logout() async {
    _jwtToken = null;
    _usuarioActual = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usuarioKey);
  }

  Map<String, dynamic> _leerObjeto(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      throw Exception('El servicio no pudo responder. Inténtalo de nuevo.');
    }
    throw Exception('La respuesta no tiene la información esperada.');
  }

  Future<Usuario> registrarUsuario({
    required String nombre,
    required String correo,
    required String cedulaRuc,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/usuarios/registro');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombre': nombre,
            'correo': correo,
            'cedula_ruc': cedulaRuc,
            'password': password,
          }),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );

    final data = _leerObjeto(response);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Usuario.fromJson(data['usuario'] ?? data);
    } else {
      throw Exception(data['mensaje'] ?? 'Error al registrar el usuario');
    }
  }

  Future<bool> login(String correo, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'correo': correo, 'password': password}),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );

    final data = _leerObjeto(response);
    if (response.statusCode == 200 && data['token'] != null) {
      _jwtToken = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _jwtToken!);

      if (data['usuario'] != null) {
        _usuarioActual = Usuario.fromJson(data['usuario']);
        await prefs.setString(_usuarioKey, jsonEncode(data['usuario']));
      }
      return true;
    } else {
      throw Exception(data['mensaje'] ?? 'Credenciales incorrectas');
    }
  }

  Future<List<Vuelo>> obtenerVuelos() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/vuelos');
    final response = await http
        .get(url)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Vuelo.fromJson(json)).toList();
    } else {
      throw Exception('No se pudo cargar el catálogo de vuelos');
    }
  }

  Future<List<Origen>> obtenerOrigenes() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/origenes');
    final response = await http
        .get(url)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((j) => Origen.fromJson(j)).toList();
    }
    throw Exception('No se pudo consultar la información');
  }

  Future<List<Usuario>> obtenerUsuariosAdmin() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/usuarios');
    final response = await http
        .get(url, headers: {'Authorization': 'Bearer $_jwtToken'})
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((j) => Usuario.fromJson(j)).toList();
    }
    throw Exception('Error al cargar usuarios');
  }

  Future<void> alternarEstadoUsuario(int userId, bool activo) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/usuarios/$userId/estado');
    final response = await http
        .patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
          body: jsonEncode({'activo': activo}),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode != 200) {
      final data = _leerObjeto(response);
      throw Exception(data['mensaje'] ?? 'Error al actualizar usuario');
    }
  }

  Future<void> crearOrigen(String nombre, String codigoIata) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/origenes');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
          body: jsonEncode({'nombre': nombre, 'codigo_iata': codigoIata}),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode != 201) {
      final data = _leerObjeto(response);
      throw Exception(data['mensaje'] ?? 'Error al crear origen');
    }
  }

  Future<List<Origen>> obtenerTodosOrigenesAdmin() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/origenes/todos');
    final response = await http
        .get(url, headers: {'Authorization': 'Bearer $_jwtToken'})
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((j) => Origen.fromJson(j)).toList();
    }
    throw Exception('No se pudo cargar la lista de orígenes');
  }

  Future<void> editarOrigen(
    int id,
    String nombre,
    String codigoIata,
    bool activo,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/origenes/$id');
    final response = await http
        .put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
          body: jsonEncode({
            'nombre': nombre,
            'codigo_iata': codigoIata,
            'activo': activo,
          }),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode != 200) {
      final data = _leerObjeto(response);
      throw Exception(data['mensaje'] ?? 'Error al editar origen');
    }
  }

  Future<void> softDeleteOrigen(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/origenes/$id');
    final response = await http
        .delete(url, headers: {'Authorization': 'Bearer $_jwtToken'})
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode != 200) {
      final data = _leerObjeto(response);
      throw Exception(data['mensaje'] ?? 'Error al desactivar origen');
    }
  }

  Future<void> crearVueloAdmin({
    required String origen,
    required String destino,
    required String fecha,
    required String fechaLlegada,
    required String horaSalida,
    required String horaLlegada,
    required double precio,
    required int asientosTotales,
    bool reembolsable = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/vuelos');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
          body: jsonEncode({
            'origen': origen,
            'destino': destino,
            'fecha': fecha,
            'fecha_llegada': fechaLlegada,
            'hora_salida': horaSalida,
            'hora_llegada': horaLlegada,
            'precio': precio,
            'asientos_totales': asientosTotales,
            'reembolsable': reembolsable,
          }),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode != 201) {
      final data = _leerObjeto(response);
      throw Exception(data['mensaje'] ?? 'Error al crear vuelo');
    }
  }

  Future<void> editarVueloAdmin({
    required int id,
    required String origen,
    required String destino,
    required String fecha,
    required String fechaLlegada,
    required String horaSalida,
    required String horaLlegada,
    required double precio,
    required int asientosTotales,
    bool reembolsable = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/vuelos/$id');
    final response = await http
        .put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
          body: jsonEncode({
            'origen': origen,
            'destino': destino,
            'fecha': fecha,
            'fecha_llegada': fechaLlegada,
            'hora_salida': horaSalida,
            'hora_llegada': horaLlegada,
            'precio': precio,
            'asientos_totales': asientosTotales,
            'reembolsable': reembolsable,
          }),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode != 200) {
      final data = _leerObjeto(response);
      throw Exception(data['mensaje'] ?? 'Error al editar vuelo');
    }
  }

  Future<void> alternarReembolsableVueloAdmin(
    int vueloId,
    bool reembolsable,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/admin/vuelos/$vueloId/reembolsable',
    );
    final response = await http
        .patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
          body: jsonEncode({'reembolsable': reembolsable}),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode != 200) {
      final data = _leerObjeto(response);
      throw Exception(
        data['mensaje'] ?? 'Error al actualizar política de reembolso',
      );
    }
  }

  Future<void> softDeleteVueloAdmin(int vueloId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/vuelos/$vueloId');
    final response = await http
        .delete(url, headers: {'Authorization': 'Bearer $_jwtToken'})
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );
    if (response.statusCode != 200) {
      final data = _leerObjeto(response);
      throw Exception(data['mensaje'] ?? 'Error al desactivar vuelo');
    }
  }

  Future<List<String>> obtenerAsientosOcupados(int vueloId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/vuelos/$vueloId/asientos-ocupados',
    );
    final response = await http
        .get(url)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      final List<dynamic> lista = data['asientos_ocupados'] ?? [];
      return lista.map((e) => e.toString()).toList();
    }
    throw Exception('No se pudo consultar la información');
  }

  Future<Reserva> crearReserva({
    required int vueloId,
    required int cantidad,
    List<String> asientos = const [],
  }) async {
    if (!isAuthenticated) throw Exception('Vuelve a iniciar sesión.');
    if (vueloId < 1 ||
        cantidad < 1 ||
        cantidad > 350 ||
        (asientos.isNotEmpty &&
            (asientos.length != cantidad ||
                asientos.toSet().length != cantidad))) {
      throw Exception('Selecciona una cantidad válida de asientos.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/reservas');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
          body: jsonEncode({
            'vuelo_id': vueloId,
            'cantidad': cantidad,
            'asientos': asientos,
          }),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );

    final data = _leerObjeto(response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Reserva.fromJson(data['reserva'] ?? data);
    } else if (response.statusCode == 409) {
      throw ConcurrencyException(
        data['mensaje'] ?? 'Uno o más asientos acaban de ser ocupados.',
      );
    } else {
      throw Exception(data['mensaje'] ?? 'No se pudo procesar la reserva');
    }
  }

  Future<List<Reserva>> obtenerMisReservas() async {
    if (!isAuthenticated) throw Exception('Sesión expirada o no autenticado.');

    final url = Uri.parse('${ApiConfig.baseUrl}/reservas/mis-reservas');
    final response = await http
        .get(url, headers: {'Authorization': 'Bearer $_jwtToken'})
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Reserva.fromJson(json)).toList();
    } else {
      throw Exception('No se pudo cargar el historial de reservas');
    }
  }

  Future<String> obtenerComprobanteXml(int reservaId) async {
    if (!isAuthenticated) throw Exception('No autenticado.');

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/reservas/$reservaId/comprobante-xml',
    );
    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $_jwtToken',
            'Accept': 'application/xml',
          },
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );

    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    } else {
      throw Exception('No se pudo obtener el comprobante');
    }
  }
  Future<ReembolsoResultado> solicitarReembolso({
    required int reservaId,
    required String motivo,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Inicia sesión para solicitar un reembolso.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/reservas/$reservaId/reembolso');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
          body: jsonEncode({'motivo': motivo}),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'La conexión tardó demasiado. Inténtalo de nuevo.',
          ),
        );

    final data = _leerObjeto(response);
    if (response.statusCode == 200) {
      final reembolsoJson = data['reembolso'] is Map<String, dynamic>
          ? data['reembolso'] as Map<String, dynamic>
          : data;
      return ReembolsoResultado.fromJson(reembolsoJson);
    } else {
      throw Exception(data['mensaje'] ?? 'No se pudo procesar el reembolso');
    }
  }
}
