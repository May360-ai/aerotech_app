import 'package:flutter/material.dart';

import '../models/vuelo_model.dart';
import '../services/api_service.dart';
import 'comprobante_xml_screen.dart';

class ReservaScreen extends StatefulWidget {
  final Vuelo vuelo;
  const ReservaScreen({super.key, required this.vuelo});

  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  final ApiService _api = ApiService();
  bool _cargandoAsientos = true;
  bool _procesando = false;
  bool _ocupacionValida = false;

  final Set<String> _asientosSeleccionados = {};
  final Set<String> _asientosOcupados = {};

  late final List<String> _colsIzquierda;
  late final List<String> _colsDerecha;
  late final int _columnasPorFila;
  late final int _totalFilas;
  late final double _anchoFuselaje;
  late final String _nombreTipoAvion;

  int get _cantidadAsientos => _asientosSeleccionados.length;
  double get subtotal => widget.vuelo.precio * _cantidadAsientos;
  double get iva => subtotal * 0.15;
  double get total => subtotal + iva;

  @override
  void initState() {
    super.initState();
    _configurarDistribucionAeronave();
    _cargarAsientosDesdeServidor();
  }

  void _configurarDistribucionAeronave() {
    final capacidad = widget.vuelo.asientosTotales;

    if (capacidad <= 20) {
      _colsIzquierda = ['A'];
      _colsDerecha = ['B', 'C'];
      _anchoFuselaje = 270;
      _nombreTipoAvion = 'Avioneta Regional (1x2)';
    } else if (capacidad <= 70) {
      _colsIzquierda = ['A', 'B'];
      _colsDerecha = ['C', 'D'];
      _anchoFuselaje = 330;
      _nombreTipoAvion = 'Jet Regional (2x2)';
    } else {
      _colsIzquierda = ['A', 'B', 'C'];
      _colsDerecha = ['D', 'E', 'F'];
      _anchoFuselaje = 410;
      _nombreTipoAvion = 'Comercial Pasajeros (3x3)';
    }

    _columnasPorFila = _colsIzquierda.length + _colsDerecha.length;
    _totalFilas = (capacidad / _columnasPorFila).ceil();
  }

  bool _asientoExiste(int fila, String col) {
    final todasLasColumnas = [..._colsIzquierda, ..._colsDerecha];
    final colIndex = todasLasColumnas.indexOf(col);
    final indiceGlobal = (fila - 1) * _columnasPorFila + colIndex;
    return indiceGlobal < widget.vuelo.asientosTotales;
  }

  Future<void> _cargarAsientosDesdeServidor() async {
    _ocupacionValida = false;
    try {
      final ocupadosServidor = await _api.obtenerAsientosOcupados(
        widget.vuelo.id,
      );
      if (!mounted) return;
      setState(() {
        _asientosOcupados.clear();
        _asientosOcupados.addAll(ocupadosServidor);
        _asientosSeleccionados.removeAll(_asientosOcupados);
        _ocupacionValida = true;
        _cargandoAsientos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoAsientos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aviso al cargar ocupación: ${e.toString()}')),
      );
    }
  }

  void _toggleAsiento(String codigo) {
    if (_procesando ||
        !_ocupacionValida ||
        _asientosOcupados.contains(codigo)) {
      return;
    }

    setState(() {
      if (_asientosSeleccionados.contains(codigo)) {
        _asientosSeleccionados.remove(codigo);
      } else {
        if (_asientosSeleccionados.length < widget.vuelo.asientosDisponibles) {
          _asientosSeleccionados.add(codigo);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Solo quedan ${widget.vuelo.asientosDisponibles} cupos libres.',
              ),
            ),
          );
        }
      }
    });
  }

  void _mostrarDialogoConcurrencia(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('El asiento ya no está disponible'),
        content: Text(
          '$mensaje\n\nEl mapa se actualizará con los asientos disponibles.',
        ),
        actions: [
          FilledButton(
            onPressed: _procesando
                ? null
                : () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarReserva() async {
    if (_procesando || !_ocupacionValida) return;
    if (_cantidadAsientos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione al menos un asiento.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _procesando = true);
    final listaAsientos = _asientosSeleccionados.toList()..sort();

    try {
      final reserva = await _api.crearReserva(
        vueloId: widget.vuelo.id,
        cantidad: _cantidadAsientos,
        asientos: listaAsientos,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ComprobanteXmlScreen(
            reserva: reserva,
            asientosSeleccionados: listaAsientos,
            vuelo: widget.vuelo,
          ),
        ),
        result: true,
      );
    } on ConcurrencyException catch (e) {
      if (!mounted) return;
      _mostrarDialogoConcurrencia(e.message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listaOrdenada = _asientosSeleccionados.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Cabina Adaptativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar Asientos',
            onPressed: _procesando
                ? null
                : () {
                    setState(() => _cargandoAsientos = true);
                    _cargarAsientosDesdeServidor();
                  },
          ),
        ],
      ),
      body: _cargandoAsientos
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Consultando asientos disponibles…'),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.vuelo.origen} a ${widget.vuelo.destino}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _nombreTipoAvion,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Chip(
                        label: Text(
                          'Libres: ${widget.vuelo.asientosDisponibles} / ${widget.vuelo.asientosTotales}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildItemLeyenda(
                        Colors.white,
                        Colors.grey.shade400,
                        'Libre',
                      ),
                      const SizedBox(width: 16),
                      _buildItemLeyenda(
                        theme.colorScheme.primary,
                        theme.colorScheme.primary,
                        'Tu Selección',
                        textoColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      _buildItemLeyenda(
                        Colors.grey.shade300,
                        Colors.grey.shade400,
                        'Ocupado',
                        textoColor: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          width: _anchoFuselaje,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(100),
                              bottom: Radius.circular(24),
                            ),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.flight,
                                size: 36,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'CABINA (${widget.vuelo.asientosTotales} ASIENTOS)',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 24, thickness: 1.5),

                              for (int fila = 1; fila <= _totalFilas; fila++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (final col in _colsIzquierda) ...[
                                        _asientoExiste(fila, col)
                                            ? _buildWidgetAsiento('$fila$col')
                                            : const SizedBox(
                                                width: 44,
                                                height: 44,
                                              ),
                                        const SizedBox(width: 6),
                                      ],

                                      Container(
                                        width: 32,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$fila',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),

                                      for (final col in _colsDerecha) ...[
                                        _asientoExiste(fila, col)
                                            ? _buildWidgetAsiento('$fila$col')
                                            : const SizedBox(
                                                width: 44,
                                                height: 44,
                                              ),
                                        if (col != _colsDerecha.last)
                                          const SizedBox(width: 6),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        offset: const Offset(0, -3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Asientos (${_asientosSeleccionados.length}):',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                listaOrdenada.isEmpty
                                    ? 'Ninguno'
                                    : listaOrdenada.join(', '),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: listaOrdenada.isEmpty
                                      ? Colors.red
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total (+15% IVA)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed:
                            (_ocupacionValida &&
                                _cantidadAsientos > 0 &&
                                !_procesando)
                            ? _confirmarReserva
                            : null,
                        icon: _procesando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.airplane_ticket),
                        label: Text(
                          _procesando
                              ? 'Confirmando reserva…'
                              : 'Confirmar reserva',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildItemLeyenda(
    Color fondo,
    Color borde,
    String texto, {
    Color textoColor = Colors.black87,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: fondo,
            border: Border.all(color: borde),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildWidgetAsiento(String codigo) {
    final theme = Theme.of(context);
    final estaOcupado = _asientosOcupados.contains(codigo);
    final estaSeleccionado = _asientosSeleccionados.contains(codigo);

    Color colorFondo;
    Color colorBorde;
    Color colorTexto;

    if (estaOcupado) {
      colorFondo = Colors.grey.shade300;
      colorBorde = Colors.grey.shade400;
      colorTexto = Colors.grey.shade500;
    } else if (estaSeleccionado) {
      colorFondo = theme.colorScheme.primary;
      colorBorde = theme.colorScheme.primary;
      colorTexto = Colors.white;
    } else {
      colorFondo = Colors.white;
      colorBorde = Colors.indigo.shade200;
      colorTexto = Colors.indigo.shade900;
    }

    return InkWell(
      onTap: estaOcupado ? null : () => _toggleAsiento(codigo),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorFondo,
          border: Border.all(
            color: colorBorde,
            width: estaSeleccionado ? 2 : 1,
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(8),
            bottom: Radius.circular(4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              estaOcupado
                  ? Icons.close
                  : (estaSeleccionado
                        ? Icons.check
                        : Icons.airline_seat_recline_normal),
              size: 15,
              color: colorTexto,
            ),
            Text(
              codigo.substring(codigo.length - 1),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
