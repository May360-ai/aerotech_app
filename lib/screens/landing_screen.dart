import 'package:flutter/material.dart';
import '../models/origen_model.dart';
import '../models/vuelo_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'registro_screen.dart';

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
        _vuelos = vuelos;
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

  void _irALogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _irARegistro(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroScreen()),
    );
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
              _buildFeaturesSection(context, esMovil),
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 20 : 60,
        vertical: 16,
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
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
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
                  onPressed: () => _irARegistro(context),
                  child: const Text("Registrarse"),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
        vertical: esMovil ? 50 : 90,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: esMovil
              ? Column(
                  children: [
                    _buildHeroText(context, esMovil),
                    const SizedBox(height: 36),
                    _buildHeroCard(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildHeroText(context, esMovil)),
                    const SizedBox(width: 40),
                    Expanded(child: _buildHeroCard()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroText(BuildContext context, bool esMovil) {
    return Column(
      crossAxisAlignment:
          esMovil ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.5)),
          ),
          child: const Text(
            "✈️ Vuelos Nacionales al Mejor Precio",
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Viaja por todo el Ecuador en minutos.",
          textAlign: esMovil ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Encuentra tarifas flexibles, selecciona tu asiento favorito y recibe tu pase de abordar digital y comprobante al instante de forma rápida y segura.",
          textAlign: esMovil ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 15,
            color: Colors.blue.shade100,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          alignment: esMovil ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              onPressed: () => _irALogin(context),
              child: const Text(
                "Reservar mi Vuelo",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
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

  Widget _buildHeroCard() {
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
        children: [
          for (int i = 0; i < proximosVuelos.length; i++) ...[
            _buildFlightPreview(proximosVuelos[i]),
            if (i < proximosVuelos.length - 1)
              const Divider(color: Colors.white24, height: 26),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
      onTap: () => _irALogin(context),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
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
                    "Salida: ${_formatearFecha(vuelo.fecha)} • ${_formatearHora(vuelo.horaSalida)}",
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

  // 3. STATS
  Widget _buildStatsSection(BuildContext context, bool esMovil) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Wrap(
        spacing: 40,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          _buildStat(
            _vuelos.isNotEmpty ? "${_vuelos.length}" : "+45",
            _vuelos.isNotEmpty ? "Vuelos Disponibles" : "Vuelos Diarios",
          ),
          _buildStat("100%", "Pagos Protegidos"),
          _buildStat("Al Instante", "Pase de Abordar Digital"),
          _buildStat("24/7", "Atención al Viajero"),
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
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.indigo.shade900,
          ),
        ),
        const SizedBox(height: 2),
        Text(lbl, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      ],
    );
  }

  // 4. BENEFICIOS PARA EL VIAJERO
  Widget _buildFeaturesSection(BuildContext context, bool esMovil) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: esMovil ? 20 : 60, vertical: 60),
      child: Column(
        children: [
          Text(
            "¿Por qué volar con nosotros?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Disfruta de una experiencia de reserva ágil, transparente y pensada para tu comodidad",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildCard(
                Icons.airplane_ticket_rounded,
                "Confirmación Inmediata",
                "Recibe tu boleto electrónico, itinerario y factura electrónica segundos después de completar tu reserva.",
              ),
              _buildCard(
                Icons.event_seat_rounded,
                "Elige tu Asiento Ideal",
                "Selecciona ventana, pasillo o primera fila con disponibilidad en tiempo real garantizada al momento de pagar.",
              ),
              _buildCard(
                Icons.verified_user_rounded,
                "Viaja con Tranquilidad",
                "Tarifas claras sin cargos ocultos, protección total en tus compras y soporte personalizado en cada etapa del viaje.",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(IconData icon, String title, String desc) {
    return Container(
      width: 310,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 26),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(color: Colors.grey.shade600, height: 1.4, fontSize: 13)),
        ],
      ),
    );
  }

  // 5. RUTAS DINÁMICAS
  Widget _buildRutasSection(BuildContext context, bool esMovil) {
    // Priorizamos el catálogo de /origenes; si está vacío, extraemos destinos de /vuelos
    final List<String> destinosMostrar = _origenes.isNotEmpty
        ? _origenes
            .map((o) => o.codigoIata.trim().isNotEmpty
                ? "${o.nombre} (${o.codigoIata})"
                : o.nombre)
            .toList()
        : _vuelos.map((v) => v.destino).toSet().toList();

    return Container(
      width: double.infinity,
      color: Colors.blue.shade50.withOpacity(0.4),
      padding: EdgeInsets.symmetric(horizontal: esMovil ? 20 : 60, vertical: 50),
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
          const SizedBox(height: 24),
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
              spacing: 16,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: destinosMostrar
                  .map((nombre) => _buildChip(nombre, _obtenerIconoDestino(nombre)))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String nombre, IconData icon) {
    return Chip(
      avatar: Icon(icon, color: Colors.indigo.shade900, size: 18),
      label: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.white,
      elevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // 6. FOOTER
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
            "© 2026 AeroAndes. Todos los derechos reservados. • Atención al cliente 24/7",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue.shade200, fontSize: 12),
          ),
        ],
      ),
    );
  }
}