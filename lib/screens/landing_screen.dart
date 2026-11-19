import 'package:flutter/material.dart';
import '../models/origen_model.dart';
import '../models/vuelo_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'mis_reservas_screen.dart';
import 'registro_screen.dart';
import 'reserva_screen.dart';
import 'vuelos_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ApiService _apiService = ApiService();

  List<Vuelo> _vuelos = [];
  List<Origen> _origenes = [];

  bool _cargandoVuelos = true;
  bool _cargandoDestinos = true;
  String? _errorVuelos;
  String? _errorDestinos;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarVuelos(),
      _cargarDestinos(),
    ]);
  }

  Future<void> _cargarVuelos() async {
    if (mounted) {
      setState(() {
        _cargandoVuelos = true;
        _errorVuelos = null;
      });
    }

    try {
      final vuelos = await _apiService.obtenerVuelos();
      if (!mounted) return;
      setState(() {
        _vuelos = vuelos.where((v) => !v.yaPaso).toList();
        _cargandoVuelos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorVuelos = 'No se pudieron cargar los vuelos disponibles.';
        _cargandoVuelos = false;
      });
    }
  }

  Future<void> _cargarDestinos() async {
    if (mounted) {
      setState(() {
        _cargandoDestinos = true;
        _errorDestinos = null;
      });
    }

    try {
      final origenes = await _apiService.obtenerOrigenes();
      if (!mounted) return;
      setState(() {
        _origenes = origenes;
        _cargandoDestinos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorDestinos = 'No se pudieron cargar los destinos.';
        _cargandoDestinos = false;
      });
    }
  }

  Future<void> _irALogin(BuildContext context) async {
    final autenticado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(returnOnSuccess: true),
      ),
    );
    if (mounted && autenticado == true) {
      setState(() {});
      _cargarVuelos();
    }
  }

  void _irARegistro(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroScreen()),
    );
  }

  Future<void> _irAVuelos(
    BuildContext context, {
    String? origenInicial,
    String? destinoInicial,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VuelosScreen(
          origenInicial: origenInicial,
          destinoInicial: destinoInicial,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
      _cargarVuelos();
    }
  }

  Future<void> _abrirDetalleVuelo(BuildContext context, Vuelo vuelo) async {
    final recargar = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => ReservaScreen(vuelo: vuelo)),
    );
    if (mounted) {
      setState(() {});
      if (recargar == true) {
        _cargarVuelos();
      }
    }
  }

  Future<void> _irAMisReservas(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MisReservasScreen()),
    );
    if (mounted) {
      setState(() {});
      _cargarVuelos();
    }
  }

  void _cerrarSesion() {
    _apiService.logout();
    setState(() {});
  }

  String _tipoCabina(int capacidad) {
    if (capacidad <= 20) return 'Avioneta Regional (1x2)';
    if (capacidad <= 70) return 'Jet Regional (2x2)';
    return 'Comercial Pasajeros (3x3)';
  }

  String _formatearHora(String hora) {
    try {
      final partes = hora.split(':');
      if (partes.length >= 2) {
        int h = int.parse(partes[0]);
        final m = partes[1].padLeft(2, '0');
        final periodo = h >= 12 ? 'PM' : 'AM';
        if (h == 0) {
          h = 12;
        } else if (h > 12) {
          h -= 12;
        }
        return '${h.toString().padLeft(2, '0')}:$m $periodo';
      }
    } catch (_) {}
    return hora;
  }

  String _formatearFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      const meses = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${meses[dt.month - 1]}';
    } catch (_) {}
    return fecha;
  }

  IconData _obtenerIconoDestino(String nombre) {
    final lower = nombre.toLowerCase();
    if (lower.contains('quito')) return Icons.location_city_rounded;
    if (lower.contains('guayaquil')) return Icons.beach_access_rounded;
    if (lower.contains('cuenca')) return Icons.museum_rounded;
    if (lower.contains('galápagos') ||
        lower.contains('galapagos') ||
        lower.contains('baltra') ||
        lower.contains('san cristóbal')) {
      return Icons.nature_people_rounded;
    }
    if (lower.contains('manta') ||
        lower.contains('salinas') ||
        lower.contains('esmeraldas')) {
      return Icons.wb_sunny_rounded;
    }
    if (lower.contains('loja') ||
        lower.contains('ambato') ||
        lower.contains('riobamba')) {
      return Icons.landscape_rounded;
    }
    if (lower.contains('coca') ||
        lower.contains('lago agrio') ||
        lower.contains('macas')) {
      return Icons.forest_rounded;
    }
    return Icons.flight_land_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final esMovil = size.width < 768;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildNavbar(context, esMovil),
              _buildHero(context, esMovil),
              _buildStatsSection(context, esMovil),
              _buildCatalogoVuelosSection(context, esMovil),
              _buildFlujoSection(context, esMovil),
              _buildRutasSection(context, esMovil),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  // 1. NAVBAR
  Widget _buildNavbar(BuildContext context, bool esMovil) {
    final autenticado = _apiService.isAuthenticated;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 16 : 60,
        vertical: 14,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: "Aero",
                      style: TextStyle(color: Colors.indigo.shade900),
                    ),
                    const TextSpan(
                      text: "Andes",
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (!esMovil)
                TextButton(
                  onPressed: () => _irAVuelos(context),
                  child: const Text("Vuelos"),
                ),
              if (autenticado) ...[
                TextButton.icon(
                  onPressed: () => _irAMisReservas(context),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: Text(esMovil ? "Reservas" : "Mis Reservas"),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Cerrar Sesión',
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ] else ...[
                if (!esMovil)
                  TextButton(
                    onPressed: () => _irARegistro(context),
                    child: const Text("Registrarse"),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade900,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: esMovil ? 14 : 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _irALogin(context),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text(
                    "Iniciar Sesión",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 2. HERO SECTION
  Widget _buildHero(BuildContext context, bool esMovil) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 24 : 80,
        vertical: esMovil ? 44 : 76,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: esMovil
              ? Column(
                  children: [
                    _buildHeroText(context, esMovil),
                    const SizedBox(height: 32),
                    _buildHeroCard(context),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildHeroText(context, esMovil)),
                    const SizedBox(width: 40),
                    Expanded(child: _buildHeroCard(context)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroText(BuildContext context, bool esMovil) {
    final autenticado = _apiService.isAuthenticated;

    return Column(
      crossAxisAlignment:
          esMovil ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          "Viaja por todo el Ecuador en minutos.",
          textAlign: esMovil ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: esMovil ? 32 : 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Consulta rutas, horarios y el mapa real de asientos sin necesidad de iniciar sesión. Solo ingresa a tu cuenta cuando confirmes tu reserva.",
          textAlign: esMovil ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 15,
            color: Colors.blue.shade100,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          alignment: esMovil ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              onPressed: () => _irAVuelos(context),
              icon: const Icon(Icons.search_rounded),
              label: const Text(
                "Explorar Vuelos",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            if (autenticado)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _irAMisReservas(context),
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text(
                  "Mis Reservas",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              )
            else
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _irARegistro(context),
                child: const Text(
                  "Crear Cuenta",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    Widget contenido;

    if (_cargandoVuelos) {
      contenido = const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: Colors.amberAccent),
        ),
      );
    } else if (_errorVuelos != null) {
      contenido = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 32),
            const SizedBox(height: 10),
            Text(
              _errorVuelos!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue.shade100, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _cargarVuelos,
              icon: const Icon(Icons.refresh_rounded, color: Colors.amberAccent),
              label: const Text(
                "Reintentar",
                style: TextStyle(color: Colors.amberAccent),
              ),
            ),
          ],
        ),
      );
    } else if (_vuelos.isEmpty) {
      contenido = Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            const Icon(Icons.flight_rounded, color: Colors.white70, size: 32),
            const SizedBox(height: 10),
            Text(
              "No hay vuelos próximos disponibles por el momento.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue.shade100, fontSize: 14),
            ),
          ],
        ),
      );
    } else {
      final proximosVuelos = _vuelos.take(3).toList();
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Próximas salidas",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                "Toca un vuelo para ver asientos",
                style: TextStyle(color: Colors.blue.shade200, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < proximosVuelos.length; i++) ...[
            _buildFlightPreview(proximosVuelos[i]),
            if (i < proximosVuelos.length - 1)
              const Divider(color: Colors.white24, height: 22),
          ],
          const SizedBox(height: 16),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.amberAccent,
            ),
            onPressed: () => _irAVuelos(context),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text("Ver los ${_vuelos.length} vuelos disponibles"),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: contenido,
    );
  }

  Widget _buildFlightPreview(Vuelo vuelo) {
    return InkWell(
      onTap: () => _abrirDetalleVuelo(context, vuelo),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        vuelo.origen,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.amberAccent,
                        size: 15,
                      ),
                      Text(
                        vuelo.destino,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_formatearFecha(vuelo.fecha)} • ${_formatearHora(vuelo.horaSalida)} • ${vuelo.asientosDisponibles} cupos",
                    style: TextStyle(color: Colors.blue.shade200, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "\$${vuelo.precio.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. STATS (datos reales del catálogo)
  Widget _buildStatsSection(BuildContext context, bool esMovil) {
    final destinosCount = _origenes.isNotEmpty
        ? _origenes.length
        : _vuelos.map((v) => v.destino).toSet().length;

    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Wrap(
        spacing: 40,
        runSpacing: 18,
        alignment: WrapAlignment.center,
        children: [
          _buildStat("${_vuelos.length}", "Vuelos Disponibles"),
          _buildStat("$destinosCount", "Destinos Activos"),
          _buildStat("Sin registro", "Consulta y Mapa de Asientos"),
          _buildStat("Reembolso", "Disponible antes de la salida"),
        ],
      ),
    );
  }

  Widget _buildStat(String val, String lbl) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.indigo.shade900,
          ),
        ),
        const SizedBox(height: 2),
        Text(lbl, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      ],
    );
  }

  // 4. CATÁLOGO DE VUELOS EN DETALLE (directo desde la landing)
  Widget _buildCatalogoVuelosSection(BuildContext context, bool esMovil) {
    final vuelosDestacados = _vuelos.take(6).toList();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 20 : 60,
        vertical: 52,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Text(
              "Vuelos Disponibles en Detalle",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Consulta horarios, tipo de aeronave y cupos disponibles. Abre cualquier vuelo para ver sus asientos sin iniciar sesión.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 30),
            if (_cargandoVuelos)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              )
            else if (_errorVuelos != null)
              Column(
                children: [
                  Text(
                    _errorVuelos!,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _cargarVuelos,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Reintentar"),
                  ),
                ],
              )
            else if (vuelosDestacados.isEmpty)
              Text(
                "No hay vuelos próximos disponibles en este momento.",
                style: TextStyle(color: Colors.grey.shade600),
              )
            else ...[
              Wrap(
                spacing: 18,
                runSpacing: 18,
                alignment: WrapAlignment.center,
                children: vuelosDestacados
                    .map((v) => _buildTarjetaVueloDetalle(context, v, esMovil))
                    .toList(),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                onPressed: () => _irAVuelos(context),
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  _vuelos.length > 6
                      ? "Ver todos los vuelos (${_vuelos.length}) y filtros"
                      : "Abrir buscador completo y filtros",
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaVueloDetalle(
    BuildContext context,
    Vuelo vuelo,
    bool esMovil,
  ) {
    final colorCupos =
        vuelo.asientosDisponibles > 5 ? Colors.green.shade700 : Colors.orange.shade800;

    return Container(
      width: esMovil ? double.infinity : 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vuelo.origen,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.flight_takeoff, size: 18, color: Colors.indigo),
              ),
              Expanded(
                child: Text(
                  vuelo.destino,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  vuelo.fechaLlegada != vuelo.fecha
                      ? "${_formatearFecha(vuelo.fecha)} a ${_formatearFecha(vuelo.fechaLlegada)}"
                      : _formatearFecha(vuelo.fecha),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "${_formatearHora(vuelo.horaSalida)} - ${_formatearHora(vuelo.horaLlegada)}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.airline_seat_recline_normal, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _tipoCabina(vuelo.asientosTotales),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
              Text(
                "${vuelo.asientosDisponibles}/${vuelo.asientosTotales} libres",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorCupos,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "\$${vuelo.precio.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  Text(
                    "por asiento (+15% IVA)",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: vuelo.asientosDisponibles > 0
                    ? () => _abrirDetalleVuelo(context, vuelo)
                    : null,
                icon: const Icon(Icons.event_seat, size: 18),
                label: const Text("Ver asientos"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. FLUJO DEL USUARIO A DETALLE
  Widget _buildFlujoSection(BuildContext context, bool esMovil) {
    final pasos = [
      (
        '1',
        Icons.search_rounded,
        'Explora vuelos y tarifas',
        'Revisa rutas, horarios, tipo de cabina y precios en tiempo real sin necesidad de iniciar sesión.',
      ),
      (
        '2',
        Icons.event_seat_rounded,
        'Elige tus asientos en cabina',
        'Visualiza los puestos libres y ocupados en el mapa interactivo y revisa el cálculo exacto con IVA.',
      ),
      (
        '3',
        Icons.verified_user_rounded,
        'Ingresa solo al confirmar',
        'Te pedimos iniciar sesión o registrarte únicamente al confirmar. Tus asientos seleccionados se conservan.',
      ),
      (
        '4',
        Icons.currency_exchange_rounded,
        'Comprobante y reembolsos',
        'Accede a tu pasaje desde Mis Reservas y solicita un reembolso antes de la salida si cambias de planes.',
      ),
    ];

    return Container(
      width: double.infinity,
      color: Colors.grey.shade50,
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 20 : 60,
        vertical: 52,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Text(
              "Cómo funciona tu reserva",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Conoce cada paso del proceso antes de crear tu cuenta",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 18,
              runSpacing: 18,
              alignment: WrapAlignment.center,
              children: pasos
                  .map(
                    (p) => _buildPasoCard(
                      numero: p.$1,
                      icon: p.$2,
                      title: p.$3,
                      desc: p.$4,
                      esMovil: esMovil,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasoCard({
    required String numero,
    required IconData icon,
    required String title,
    required String desc,
    required bool esMovil,
  }) {
    return Container(
      width: esMovil ? double.infinity : 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  numero,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: Colors.blueAccent, size: 22),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.45,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // 6. RUTAS DINÁMICAS (interactivas: filtran el catálogo)
  Widget _buildRutasSection(BuildContext context, bool esMovil) {
    final List<({String etiqueta, String ciudad})> destinosMostrar =
        _origenes.isNotEmpty
            ? _origenes
                .map(
                  (o) => (
                    etiqueta: o.codigoIata.trim().isNotEmpty
                        ? "${o.nombre} (${o.codigoIata})"
                        : o.nombre,
                    ciudad: o.nombre,
                  ),
                )
                .toList()
            : _vuelos
                .map((v) => v.destino)
                .toSet()
                .map((d) => (etiqueta: d, ciudad: d))
                .toList();

    return Container(
      width: double.infinity,
      color: Colors.blue.shade50.withValues(alpha: 0.4),
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 20 : 60,
        vertical: 48,
      ),
      child: Column(
        children: [
          Text(
            "Destinos Nacionales Disponibles",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Selecciona una ciudad para ver los vuelos hacia ese destino",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 22),
          if (_cargandoDestinos && _cargandoVuelos)
            const CircularProgressIndicator()
          else if (_errorDestinos != null && destinosMostrar.isEmpty)
            Column(
              children: [
                Text(
                  _errorDestinos!,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _cargarDatos,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Reintentar"),
                ),
              ],
            )
          else if (destinosMostrar.isEmpty)
            Text(
              "No hay destinos registrados por el momento.",
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            Wrap(
              spacing: 14,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: destinosMostrar
                  .map(
                    (d) => _buildChipDestino(
                      d.etiqueta,
                      d.ciudad,
                      _obtenerIconoDestino(d.ciudad),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildChipDestino(String etiqueta, String ciudad, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, color: Colors.indigo.shade900, size: 18),
      label: Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.white,
      elevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => _irAVuelos(context, destinoInicial: ciudad),
    );
  }

  // 7. FOOTER
  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.indigo.shade900,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      child: Column(
        children: [
          const Text(
            "AeroAndes • Conectando todo el Ecuador",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "© 2026 AeroAndes. Todos los derechos reservados.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade200, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
