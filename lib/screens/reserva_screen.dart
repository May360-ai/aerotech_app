import 'dart:math';
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
  bool _procesando = false;

  final Set<String> _asientosSeleccionados = {};
  final Set<String> _asientosOcupados = {};
  final List<String> _columnas = ['A', 'B', 'C', 'D'];
  late int _totalFilas;

  int get _cantidadAsientos => _asientosSeleccionados.length;
  double get subtotal => widget.vuelo.precio * _cantidadAsientos;
  double get iva => subtotal * 0.15; 
  double get total => subtotal + iva;

  @override
  void initState() {
    super.initState();
    _generarMapaDeAsientos();
  }

  void _generarMapaDeAsientos() {
    final capacidadAproximada = max(widget.vuelo.asientosDisponibles + 8, 24);
    _totalFilas = (capacidadAproximada / _columnas.length).ceil();

    final List<String> todosLosAsientos = [];
    for (int fila = 1; fila <= _totalFilas; fila++) {
      for (String col in _columnas) {
        todosLosAsientos.add('$fila$col');
      }
    }

    final totalAsientos = todosLosAsientos.length;
    final cuposDisponibles = min(widget.vuelo.asientosDisponibles, totalAsientos);
    final cantidadOcupados = totalAsientos - cuposDisponibles;

    final random = Random(widget.vuelo.id);
    todosLosAsientos.shuffle(random);

    for (int i = 0; i < cantidadOcupados; i++) {
      _asientosOcupados.add(todosLosAsientos[i]);
    }

    final primerLibre = todosLosAsientos.firstWhere(
      (asiento) => !_asientosOcupados.contains(asiento),
      orElse: () => '',
    );
    if (primerLibre.isNotEmpty) {
      _asientosSeleccionados.add(primerLibre);
    }
  }

  void _toggleAsiento(String codigoAsiento) {
    if (_asientosOcupados.contains(codigoAsiento)) return;

    setState(() {
      if (_asientosSeleccionados.contains(codigoAsiento)) {
        _asientosSeleccionados.remove(codigoAsiento);
      } else {
        if (_asientosSeleccionados.length < widget.vuelo.asientosDisponibles) {
          _asientosSeleccionados.add(codigoAsiento);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Límite alcanzado: solo hay ${widget.vuelo.asientosDisponibles} cupos.'),
              duration: const Duration(seconds: 2),
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
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        title: const Text('Conflicto de Concurrencia (409)'),
        content: Text(
          '$mensaje\n\nLos cupos han cambiado simultáneamente por otra reserva. Regresando al catálogo...',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); 
            },
            child: const Text('Actualizar Catálogo'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarReserva() async {
    if (_cantidadAsientos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos un asiento.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_procesando) return;
    setState(() => _procesando = true);

    try {
      final reserva = await _api.crearReserva(
        vueloId: widget.vuelo.id,
        cantidad: _cantidadAsientos,
      );

      final rawXml = await _api.obtenerComprobanteXml(reserva.id);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ComprobanteXmlScreen(
            reserva: reserva,
            xmlContent: rawXml,
            asientosSeleccionados: _asientosSeleccionados.toList()..sort(),
          ),
        ),
      );
    } on ConcurrencyException catch (e) {
      if (!mounted) return;
      _mostrarDialogoConcurrencia(e.message);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');

      if (errorMsg.toLowerCase().contains('asientos') ||
          errorMsg.toLowerCase().contains('cupos') ||
          errorMsg.toLowerCase().contains('concurrencia')) {
        _mostrarDialogoConcurrencia(errorMsg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuario = _api.usuarioActual;
    final listaAsientosOrdenados = _asientosSeleccionados.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Selección de Asientos')),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.vuelo.origen} ➔ ${widget.vuelo.destino}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text('${widget.vuelo.fecha} | Salida: ${widget.vuelo.horaSalida}'),
                  ],
                ),
                Chip(
                  label: Text('Libres: ${widget.vuelo.asientosDisponibles}'),
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
                _buildItemLeyenda(Colors.white, Colors.grey.shade400, 'Disponible'),
                const SizedBox(width: 16),
                _buildItemLeyenda(theme.colorScheme.primary, theme.colorScheme.primary, 'Seleccionado', textoColor: Colors.white),
                const SizedBox(width: 16),
                _buildItemLeyenda(Colors.grey.shade300, Colors.grey.shade400, 'Ocupado', textoColor: Colors.grey.shade600),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(100), 
                      bottom: Radius.circular(20),
                    ),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.flight, size: 36, color: theme.colorScheme.primary),
                      const SizedBox(height: 4),
                      Text(
                        'FRENTE / CABINA',
                        style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 24, thickness: 1.5),

                      for (int fila = 1; fila <= _totalFilas; fila++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildWidgetAsiento('$fila A'),
                              const SizedBox(width: 6),
                              _buildWidgetAsiento('$fila B'),
                              
                              Container(
                                width: 36,
                                alignment: Alignment.center,
                                child: Text(
                                  '$fila',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),

                              _buildWidgetAsiento('$fila C'),
                              const SizedBox(width: 6),
                              _buildWidgetAsiento('$fila D'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          listaAsientosOrdenados.isEmpty
                              ? 'Ninguno seleccionado'
                              : listaAsientosOrdenados.join(', '),
                          style: TextStyle(
                            fontSize: 13,
                            color: listaAsientosOrdenados.isEmpty ? Colors.red : theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total (+15% IVA)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: (_cantidadAsientos > 0 && !_procesando) ? _confirmarReserva : null,
                  icon: _procesando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_procesando
                      ? 'Procesando Transacción...'
                      : 'Confirmar ${_cantidadAsientos} Asiento(s) y Emitir XML'),
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

  Widget _buildItemLeyenda(Color fondo, Color borde, String texto, {Color textoColor = Colors.black87}) {
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
          border: Border.all(color: colorBorde, width: estaSeleccionado ? 2 : 1),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(8),
            bottom: Radius.circular(4),
          ),
          boxShadow: estaSeleccionado
              ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.35), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              estaOcupado ? Icons.close : (estaSeleccionado ? Icons.check : Icons.airline_seat_recline_normal),
              size: 16,
              color: colorTexto,
            ),
            Text(
              codigo.split(' ').last,
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