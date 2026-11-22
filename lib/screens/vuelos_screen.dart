import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vuelo_model.dart';
import '../services/api_service.dart';
import 'admin_panel_screen.dart';
import 'landing_screen.dart';
import 'login_screen.dart';
import 'mis_reservas_screen.dart';
import 'reserva_screen.dart';

enum _TipoViaje { todos, soloIda, idaYVuelta }

class _VueloIdaVuelta {
  final Vuelo ida;
  final Vuelo vuelta;

  const _VueloIdaVuelta({required this.ida, required this.vuelta});

  double get precioTotal => ida.precio + vuelta.precio;

  bool get disponible =>
      ida.asientosDisponibles > 0 && vuelta.asientosDisponibles > 0;
}

class VuelosScreen extends StatefulWidget {
  final String? origenInicial;
  final String? destinoInicial;

  const VuelosScreen({
    super.key,
    this.origenInicial,
    this.destinoInicial,
  });

  @override
  State<VuelosScreen> createState() => _VuelosScreenState();
}

class _VuelosScreenState extends State<VuelosScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _busquedaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Vuelo> _todosLosVuelos = [];
  bool _cargando = true;
  String? _error;

  _TipoViaje _tipoViaje = _TipoViaje.todos;
  String? _origenSeleccionado;
  String? _destinoSeleccionado;
  DateTime? _fechaIda;
  DateTime? _fechaVuelta;
  bool _filtrosExpandidos = false;

  int _paginaActual = 1;
  int _itemsPorPagina = 5;

  @override
  void initState() {
    super.initState();
    _origenSeleccionado = widget.origenInicial;
    _destinoSeleccionado = widget.destinoInicial;
    if (_origenSeleccionado != null || _destinoSeleccionado != null) {
      _filtrosExpandidos = true;
    }
    _cargarVuelos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarVuelos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final vuelos = await _api.obtenerVuelos();
      if (!mounted) return;
      setState(() {
        _todosLosVuelos = vuelos.where((v) => !v.yaPaso).toList();
        _cargando = false;
        _paginaActual = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  void _cerrarSesion() {
    _api.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  Future<void> _irALogin() async {
    final autenticado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(returnOnSuccess: true),
      ),
    );
    if (mounted && autenticado == true) {
      setState(() {});
      _cargarVuelos();
    }
  }

  DateTime? _parseFecha(String valor) {
    final limpio = valor.trim();
    if (limpio.isEmpty) return null;

    final iso = DateTime.tryParse(limpio);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    final partes = limpio.split(RegExp(r'[-/]'));
    if (partes.length == 3) {
      final p0 = int.tryParse(partes[0]);
      final p1 = int.tryParse(partes[1]);
      final p2 = int.tryParse(partes[2]);
      if (p0 != null && p1 != null && p2 != null) {
        if (partes[0].length == 4) {
          return DateTime(p0, p1, p2);
        }
        if (partes[2].length == 4) {
          return DateTime(p2, p1, p0);
        }
      }
    }
    return null;
  }

  String _formatearFecha(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _mismaFecha(String fechaVuelo, DateTime fechaFiltro) {
    final parsed = _parseFecha(fechaVuelo);
    if (parsed != null) {
      return parsed.year == fechaFiltro.year &&
          parsed.month == fechaFiltro.month &&
          parsed.day == fechaFiltro.day;
    }
    return fechaVuelo.trim() == _formatearFecha(fechaFiltro);
  }

  bool _coincideTexto(Vuelo v, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return v.origen.toLowerCase().contains(q) ||
        v.destino.toLowerCase().contains(q) ||
        v.fecha.toLowerCase().contains(q) ||
        v.horaSalida.toLowerCase().contains(q) ||
        v.horaLlegada.toLowerCase().contains(q);
  }

  List<String> get _origenesDisponibles {
    final set = _todosLosVuelos
        .map((v) => v.origen.trim())
        .where((o) => o.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return set;
  }

  List<String> get _destinosDisponibles {
    final set = _todosLosVuelos
        .map((v) => v.destino.trim())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return set;
  }

  int get _cantidadFiltrosActivos {
    var count = 0;
    if (_origenSeleccionado != null) count++;
    if (_destinoSeleccionado != null) count++;
    if (_fechaIda != null) count++;
    if (_tipoViaje == _TipoViaje.idaYVuelta && _fechaVuelta != null) count++;
    return count;
  }

  bool get _hayAlgunFiltro =>
      _busquedaController.text.trim().isNotEmpty || _cantidadFiltrosActivos > 0;

  void _limpiarFiltros() {
    setState(() {
      _busquedaController.clear();
      _origenSeleccionado = null;
      _destinoSeleccionado = null;
      _fechaIda = null;
      _fechaVuelta = null;
      _paginaActual = 1;
    });
    _irAlInicioLista();
  }

  void _intercambiarOrigenDestino() {
    setState(() {
      final temp = _origenSeleccionado;
      _origenSeleccionado = _destinoSeleccionado;
      _destinoSeleccionado = temp;
      _paginaActual = 1;
    });
    _irAlInicioLista();
  }

  void _irAlInicioLista() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  List<Vuelo> _filtrarVuelosIndividuales() {
    final query = _busquedaController.text.trim();
    return _todosLosVuelos.where((v) {
      if (v.yaPaso) return false;
      if (_origenSeleccionado != null &&
          v.origen.trim().toLowerCase() !=
              _origenSeleccionado!.trim().toLowerCase()) {
        return false;
      }
      if (_destinoSeleccionado != null &&
          v.destino.trim().toLowerCase() !=
              _destinoSeleccionado!.trim().toLowerCase()) {
        return false;
      }
      if (_fechaIda != null && !_mismaFecha(v.fecha, _fechaIda!)) {
        return false;
      }
      if (!_coincideTexto(v, query)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<_VueloIdaVuelta> _generarParesIdaVuelta() {
    final query = _busquedaController.text.trim().toLowerCase();
    final pares = <_VueloIdaVuelta>[];

    for (final ida in _todosLosVuelos) {
      if (ida.yaPaso) continue;
      if (_origenSeleccionado != null &&
          ida.origen.trim().toLowerCase() !=
              _origenSeleccionado!.trim().toLowerCase()) {
        continue;
      }
      if (_destinoSeleccionado != null &&
          ida.destino.trim().toLowerCase() !=
              _destinoSeleccionado!.trim().toLowerCase()) {
        continue;
      }
      if (_fechaIda != null && !_mismaFecha(ida.fecha, _fechaIda!)) {
        continue;
      }

      final dtIda = _parseFecha(ida.fecha);

      for (final vuelta in _todosLosVuelos) {
        if (vuelta.id == ida.id || vuelta.yaPaso) continue;
        if (vuelta.origen.trim().toLowerCase() !=
                ida.destino.trim().toLowerCase() ||
            vuelta.destino.trim().toLowerCase() !=
                ida.origen.trim().toLowerCase()) {
          continue;
        }

        final dtVuelta = _parseFecha(vuelta.fecha);
        if (dtIda != null && dtVuelta != null) {
          if (dtVuelta.isBefore(dtIda)) continue;
          if (dtVuelta.isAtSameMomentAs(dtIda) &&
              vuelta.horaSalida.compareTo(ida.horaLlegada) < 0) {
            continue;
          }
        }

        if (_fechaVuelta != null && !_mismaFecha(vuelta.fecha, _fechaVuelta!)) {
          continue;
        }

        if (query.isNotEmpty) {
          final coincideRuta =
              '${ida.origen} ${ida.destino} ${vuelta.origen} ${vuelta.destino}'
                  .toLowerCase()
                  .contains(query);
          if (!coincideRuta &&
              !_coincideTexto(ida, query) &&
              !_coincideTexto(vuelta, query)) {
            continue;
          }
        }

        pares.add(_VueloIdaVuelta(ida: ida, vuelta: vuelta));
      }
    }

    pares.sort((a, b) {
      final cmpFecha = a.ida.fecha.compareTo(b.ida.fecha);
      if (cmpFecha != 0) return cmpFecha;
      final cmpVuelta = a.vuelta.fecha.compareTo(b.vuelta.fecha);
      if (cmpVuelta != 0) return cmpVuelta;
      return a.precioTotal.compareTo(b.precioTotal);
    });

    return pares;
  }

  Future<void> _seleccionarFecha({required bool esVuelta}) async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final primera = esVuelta && _fechaIda != null && _fechaIda!.isAfter(hoy)
        ? _fechaIda!
        : hoy;
    final inicial = esVuelta
        ? (_fechaVuelta ?? _fechaIda ?? hoy)
        : (_fechaIda ?? hoy);
    final limiteMaximo = DateTime(2035);
    final fechaInicial = inicial.isBefore(primera)
        ? primera
        : (inicial.isAfter(limiteMaximo) ? limiteMaximo : inicial);

    final seleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: primera,
      lastDate: limiteMaximo,
    );

    if (seleccionada == null || !mounted) return;

    setState(() {
      if (esVuelta) {
        _fechaVuelta = seleccionada;
      } else {
        _fechaIda = seleccionada;
        if (_fechaVuelta != null && _fechaVuelta!.isBefore(seleccionada)) {
          _fechaVuelta = null;
        }
      }
      _paginaActual = 1;
    });
    _irAlInicioLista();
  }

  void _notificarVueloExpirado() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Este vuelo ya superó su hora de salida.'),
        backgroundColor: Colors.orange,
      ),
    );
    _cargarVuelos();
  }

  Future<void> _abrirReserva(Vuelo vuelo) async {
    if (vuelo.yaPaso) {
      _notificarVueloExpirado();
      return;
    }
    final recargar = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReservaScreen(vuelo: vuelo)),
    );
    if (mounted && recargar == true) {
      _cargarVuelos();
    }
  }

  Future<void> _reservarIdaYVuelta(_VueloIdaVuelta par) async {
    if (par.ida.yaPaso || par.vuelta.yaPaso) {
      _notificarVueloExpirado();
      return;
    }
    final reservoIda = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReservaScreen(vuelo: par.ida)),
    );
    if (!mounted) return;

    if (reservoIda == true) {
      if (par.vuelta.yaPaso) {
        _notificarVueloExpirado();
        return;
      }
      final reservoVuelta = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => ReservaScreen(vuelo: par.vuelta)),
      );
      if (!mounted) return;
      if (reservoVuelta == true || reservoIda == true) {
        _cargarVuelos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _api.usuarioActual;
    final autenticado = _api.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vuelos Disponibles'),
        actions: [
          if (autenticado && (_api.usuarioActual?.isAdmin ?? false))
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
              tooltip: 'Panel de Administrador',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                ).then((_) {
                  if (mounted) _cargarVuelos();
                });
              },
            ),
          if (autenticado)
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Mis Reservas',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MisReservasScreen()),
                ).then((_) {
                  if (mounted) _cargarVuelos();
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarVuelos,
          ),
          if (autenticado)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: _cerrarSesion,
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _irALogin,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Ingresar'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (usuario != null)
            Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    child: Text(
                      usuario.nombre.isNotEmpty
                          ? usuario.nombre[0].toUpperCase()
                          : 'U',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pasajero: ${usuario.nombre}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Cédula/RUC: ${usuario.cedulaRuc}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Explora vuelos y elige tus asientos libremente. Solo inicia sesión al confirmar.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          _buildPanelBusqueda(context),
          Expanded(child: _buildContenido(context)),
        ],
      ),
    );
  }

  Widget _buildPanelBusqueda(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final origenes = _origenesDisponibles;
    final destinos = _destinosDisponibles;

    final origenActual =
        origenes.contains(_origenSeleccionado) ? _origenSeleccionado : null;
    final destinoActual =
        destinos.contains(_destinoSeleccionado) ? _destinoSeleccionado : null;

    return Material(
      elevation: 1,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _busquedaController,
                    onChanged: (_) {
                      setState(() {
                        _paginaActual = 1;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar por origen, destino o fecha...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _busquedaController.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Limpiar búsqueda',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _busquedaController.clear();
                                  _paginaActual = 1;
                                });
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: _cantidadFiltrosActivos > 0,
                  label: Text('$_cantidadFiltrosActivos'),
                  child: IconButton.outlined(
                    tooltip: _filtrosExpandidos
                        ? 'Ocultar filtros'
                        : 'Mostrar filtros',
                    icon: Icon(
                      _filtrosExpandidos
                          ? Icons.filter_alt_off
                          : Icons.tune,
                    ),
                    onPressed: () {
                      setState(() {
                        _filtrosExpandidos = !_filtrosExpandidos;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_filtrosExpandidos) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownUbicacion(
                      label: 'Origen',
                      valor: origenActual,
                      opciones: origenes,
                      onChanged: (valor) {
                        setState(() {
                          _origenSeleccionado = valor;
                          _paginaActual = 1;
                        });
                        _irAlInicioLista();
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Intercambiar origen y destino',
                    onPressed: (_origenSeleccionado != null ||
                            _destinoSeleccionado != null)
                        ? _intercambiarOrigenDestino
                        : null,
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  Expanded(
                    child: _buildDropdownUbicacion(
                      label: 'Destino',
                      valor: destinoActual,
                      opciones: destinos,
                      onChanged: (valor) {
                        setState(() {
                          _destinoSeleccionado = valor;
                          _paginaActual = 1;
                        });
                        _irAlInicioLista();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectorFecha(
                      etiqueta: _tipoViaje == _TipoViaje.idaYVuelta
                          ? 'Fecha ida'
                          : 'Fecha salida',
                      fecha: _fechaIda,
                      onTap: () => _seleccionarFecha(esVuelta: false),
                      onClear: () {
                        setState(() {
                          _fechaIda = null;
                          _paginaActual = 1;
                        });
                        _irAlInicioLista();
                      },
                    ),
                  ),
                  if (_tipoViaje == _TipoViaje.idaYVuelta) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSelectorFecha(
                        etiqueta: 'Fecha vuelta',
                        fecha: _fechaVuelta,
                        onTap: () => _seleccionarFecha(esVuelta: true),
                        onClear: () {
                          setState(() {
                            _fechaVuelta = null;
                            _paginaActual = 1;
                          });
                          _irAlInicioLista();
                        },
                      ),
                    ),
                  ],
                ],
              ),
              if (_hayAlgunFiltro)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _limpiarFiltros,
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('Limpiar filtros'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownUbicacion({
    required String label,
    required String? valor,
    required List<String> opciones,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: valor,
          isExpanded: true,
          isDense: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos'),
            ),
            ...opciones.map(
              (op) => DropdownMenuItem<String?>(
                value: op,
                child: Text(op, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSelectorFecha({
    required String etiqueta,
    required DateTime? fecha,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              fecha != null ? _formatearFecha(fecha) : etiqueta,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (fecha != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildContenido(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 50, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarVuelos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_todosLosVuelos.isEmpty) {
      return const Center(
        child: Text('No hay vuelos disponibles en este momento.'),
      );
    }

    if (_tipoViaje == _TipoViaje.idaYVuelta) {
      final pares = _generarParesIdaVuelta();
      if (pares.isEmpty) {
        return _buildSinResultados(
          'No se encontraron combinaciones de ida y vuelta con esos filtros.',
        );
      }
      return _buildListaPaginada<_VueloIdaVuelta>(
        items: pares,
        etiquetaConteo:
            '${pares.length} ${pares.length == 1 ? 'combinación ida y vuelta' : 'combinaciones ida y vuelta'}',
        itemBuilder: (par) => _buildCardIdaYVuelta(context, par),
      );
    }

    final vuelos = _filtrarVuelosIndividuales();
    if (vuelos.isEmpty) {
      return _buildSinResultados(
        'No se encontraron vuelos que coincidan con tu búsqueda.',
      );
    }

    return _buildListaPaginada<Vuelo>(
      items: vuelos,
      etiquetaConteo:
          '${vuelos.length} ${vuelos.length == 1 ? 'vuelo encontrado' : 'vuelos encontrados'}',
      itemBuilder: (vuelo) => _buildCardVuelo(context, vuelo),
    );
  }

  Widget _buildSinResultados(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            if (_hayAlgunFiltro) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListaPaginada<T>({
    required List<T> items,
    required String etiquetaConteo,
    required Widget Function(T item) itemBuilder,
  }) {
    final totalItems = items.length;
    final totalPaginas = math.max(1, (totalItems / _itemsPorPagina).ceil());
    final paginaSegura = _paginaActual.clamp(1, totalPaginas);
    final inicio = (paginaSegura - 1) * _itemsPorPagina;
    final fin = math.min(inicio + _itemsPorPagina, totalItems);
    final itemsPagina = items.sublist(inicio, fin);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                etiquetaConteo,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Mostrando ${inicio + 1}-$fin de $totalItems',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarVuelos,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: itemsPagina.length,
              itemBuilder: (context, index) => itemBuilder(itemsPagina[index]),
            ),
          ),
        ),
        _buildBarraPaginacion(
          paginaActual: paginaSegura,
          totalPaginas: totalPaginas,
        ),
      ],
    );
  }

  Widget _buildBarraPaginacion({
    required int paginaActual,
    required int totalPaginas,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final paginasVisibles = _calcularPaginasVisibles(paginaActual, totalPaginas);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          DropdownButton<int>(
            value: _itemsPorPagina,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 5, child: Text('5 / pág')),
              DropdownMenuItem(value: 10, child: Text('10 / pág')),
              DropdownMenuItem(value: 20, child: Text('20 / pág')),
            ],
            onChanged: (nuevo) {
              if (nuevo == null) return;
              setState(() {
                _itemsPorPagina = nuevo;
                _paginaActual = 1;
              });
              _irAlInicioLista();
            },
          ),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Primera página',
            onPressed: paginaActual > 1 ? () => _cambiarPagina(1) : null,
            icon: const Icon(Icons.first_page),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Página anterior',
            onPressed:
                paginaActual > 1 ? () => _cambiarPagina(paginaActual - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          ...paginasVisibles.map((numPag) {
            final activa = numPag == paginaActual;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: activa ? null : () => _cambiarPagina(numPag),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: activa ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$numPag',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: activa ? FontWeight.bold : FontWeight.normal,
                      color: activa
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Página siguiente',
            onPressed: paginaActual < totalPaginas
                ? () => _cambiarPagina(paginaActual + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Última página',
            onPressed: paginaActual < totalPaginas
                ? () => _cambiarPagina(totalPaginas)
                : null,
            icon: const Icon(Icons.last_page),
          ),
        ],
      ),
    );
  }

  List<int> _calcularPaginasVisibles(int actual, int total) {
    const maxBotones = 3;
    if (total <= maxBotones) {
      return List.generate(total, (i) => i + 1);
    }
    var inicio = math.max(1, actual - 1);
    var fin = inicio + maxBotones - 1;
    if (fin > total) {
      fin = total;
      inicio = math.max(1, fin - maxBotones + 1);
    }
    return [for (var i = inicio; i <= fin; i++) i];
  }

  void _cambiarPagina(int nuevaPagina) {
    setState(() {
      _paginaActual = nuevaPagina;
    });
    _irAlInicioLista();
  }

  Widget _buildCardVuelo(BuildContext context, Vuelo vuelo) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vuelo.origen,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.flight_takeoff, color: Colors.indigo),
                Text(
                  vuelo.destino,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(vuelo.fecha),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text('${vuelo.horaSalida} - ${vuelo.horaLlegada}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${vuelo.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Cupos: ${vuelo.asientosDisponibles} / ${vuelo.asientosTotales}',
                      style: TextStyle(
                        color: vuelo.asientosDisponibles > 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: vuelo.reembolsable
                            ? Colors.teal.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: vuelo.reembolsable
                              ? Colors.teal.shade200
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        vuelo.reembolsable
                            ? 'Tarifa reembolsable'
                            : 'No reembolsable',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: vuelo.reembolsable
                              ? Colors.teal.shade900
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: vuelo.asientosDisponibles > 0
                      ? () => _abrirReserva(vuelo)
                      : null,
                  icon: const Icon(Icons.event_seat),
                  label: Text(
                    _api.isAuthenticated ? 'Reservar' : 'Ver asientos',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardIdaYVuelta(BuildContext context, _VueloIdaVuelta par) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'IDA Y VUELTA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Text(
                  '\$${par.precioTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTramoIdaVuelta(
              etiqueta: 'IDA',
              icono: Icons.flight_takeoff,
              vuelo: par.ida,
              onReservar: par.ida.asientosDisponibles > 0
                  ? () => _abrirReserva(par.ida)
                  : null,
            ),
            const Divider(height: 20),
            _buildTramoIdaVuelta(
              etiqueta: 'VUELTA',
              icono: Icons.flight_land,
              vuelo: par.vuelta,
              onReservar: par.vuelta.asientosDisponibles > 0
                  ? () => _abrirReserva(par.vuelta)
                  : null,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: par.disponible ? () => _reservarIdaYVuelta(par) : null,
              icon: const Icon(Icons.sync_alt),
              label: const Text('Reservar Ida y Vuelta'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTramoIdaVuelta({
    required String etiqueta,
    required IconData icono,
    required Vuelo vuelo,
    required VoidCallback? onReservar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 18, color: Colors.indigo),
            const SizedBox(width: 6),
            Text(
              '$etiqueta: ${vuelo.origen} → ${vuelo.destino}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Spacer(),
            Text(
              '\$${vuelo.precio.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 15,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(vuelo.fecha, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 15, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${vuelo.horaSalida} - ${vuelo.horaLlegada}',
              style: const TextStyle(fontSize: 13),
            ),
            const Spacer(),
            Text(
              'Cupos: ${vuelo.asientosDisponibles}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: vuelo.asientosDisponibles > 0
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onReservar,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text('Reservar solo $etiqueta'),
          ),
        ),
      ],
    );
  }
}
