import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reserva_model.dart';
import '../models/vuelo_model.dart';
import '../services/api_service.dart';

class ComprobanteXmlScreen extends StatefulWidget {
  final Reserva reserva;
  final List<String> asientosSeleccionados;
  final Vuelo? vuelo;

  const ComprobanteXmlScreen({
    super.key,
    required this.reserva,
    this.asientosSeleccionados = const [],
    this.vuelo,
  });

  @override
  State<ComprobanteXmlScreen> createState() => _ComprobanteXmlScreenState();
}

class _ComprobanteXmlScreenState extends State<ComprobanteXmlScreen> {
  final ApiService _api = ApiService();

  bool _mostrarXml = false;
  bool _cargandoXml = false;
  String? _xmlContenido;
  String? _errorXml;

  String get _origen =>
      widget.vuelo?.origen ?? widget.reserva.origen ?? 'Origen por confirmar';
  String get _destino =>
      widget.vuelo?.destino ?? widget.reserva.destino ?? 'Destino por confirmar';
  String get _fechaSalida =>
      widget.vuelo?.fecha ?? widget.reserva.fecha ?? 'Por confirmar';
  String? get _fechaLlegada =>
      widget.vuelo?.fechaLlegada ?? widget.reserva.fechaLlegada;
  String get _horaSalida =>
      widget.vuelo?.horaSalida ?? widget.reserva.horaSalida ?? 'Por confirmar';
  String? get _horaLlegada =>
      widget.vuelo?.horaLlegada ?? widget.reserva.horaLlegada;
  bool get _esReembolsable =>
      widget.vuelo?.reembolsable ?? widget.reserva.reembolsable;
  double? get _precioUnitario =>
      widget.vuelo?.precio ?? widget.reserva.precioUnitario;

  List<String> get _listaAsientos {
    if (widget.asientosSeleccionados.isNotEmpty) {
      return widget.asientosSeleccionados
          .where((a) => a.trim().isNotEmpty)
          .toList();
    }
    final raw = widget.reserva.asientos ?? '';
    if (raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
  }

  String _construirResumenTexto() {
    final usuario = _api.usuarioActual;
    final asientosTexto = _listaAsientos.isEmpty
        ? (widget.reserva.asientos ?? 'Asignados')
        : _listaAsientos.join(', ');

    final lineas = <String>[
      'RECIBO ELECTRONICO DE RESERVA - AEROANDES',
      'Codigo de reserva: ${widget.reserva.codigoReserva}',
      'Estado: ${widget.reserva.estado.toUpperCase()}',
      if (widget.reserva.fechaReserva != null &&
          widget.reserva.fechaReserva!.isNotEmpty)
        'Fecha de emision: ${widget.reserva.fechaReserva}',
      if (usuario != null) ...[
        'Pasajero: ${usuario.nombre}',
        'Cedula/RUC: ${usuario.cedulaRuc}',
        'Correo: ${usuario.correo}',
      ],
      'Ruta: $_origen -> $_destino',
      'Salida: $_fechaSalida $_horaSalida',
      if (_horaLlegada != null && _horaLlegada!.isNotEmpty)
        'Llegada: ${_fechaLlegada ?? _fechaSalida} $_horaLlegada',
      'Asientos: $asientosTexto',
      'Politica de tarifa: ${_esReembolsable ? "Reembolsable" : "No reembolsable"}',
      'Subtotal: \$${widget.reserva.subtotal.toStringAsFixed(2)}',
      'IVA (15%): \$${widget.reserva.iva.toStringAsFixed(2)}',
      '${widget.reserva.estaReembolsada ? "Total reembolsado" : "Total pagado"}: \$${widget.reserva.total.toStringAsFixed(2)}',
    ];
    return lineas.join('\n');
  }

  Future<void> _alternarXml() async {
    if (_mostrarXml) {
      setState(() => _mostrarXml = false);
      return;
    }

    setState(() => _mostrarXml = true);
    if (_xmlContenido != null || _cargandoXml) return;

    setState(() {
      _cargandoXml = true;
      _errorXml = null;
    });

    try {
      final xml = await _api.obtenerComprobanteXml(widget.reserva.id);
      if (!mounted) return;
      setState(() {
        _xmlContenido = xml;
        _cargandoXml = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorXml = e.toString().replaceAll('Exception: ', '');
        _cargandoXml = false;
      });
    }
  }

  Future<void> _copiarTexto(String texto, String mensaje) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final usuario = _api.usuarioActual;
    final asientos = _listaAsientos;
    final cantidad = r.cantidadAsientos ?? (asientos.isNotEmpty ? asientos.length : 1);

    final Color colorEstado;
    final Color fondoEstado;
    final IconData iconoEstado;
    final String tituloEstado;

    if (r.estaReembolsada) {
      colorEstado = Colors.orange.shade900;
      fondoEstado = Colors.amber.shade50;
      iconoEstado = Icons.currency_exchange_rounded;
      tituloEstado = 'RESERVA REEMBOLSADA';
    } else if (r.estaCancelada) {
      colorEstado = Colors.red.shade900;
      fondoEstado = Colors.red.shade50;
      iconoEstado = Icons.cancel_outlined;
      tituloEstado = 'RESERVA CANCELADA';
    } else {
      colorEstado = Colors.green.shade800;
      fondoEstado = Colors.green.shade50;
      iconoEstado = Icons.verified_rounded;
      tituloEstado = 'RESERVA CONFIRMADA';
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Recibo de Reserva'),
        actions: [
          IconButton(
            tooltip: 'Copiar recibo',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copiarTexto(
              _construirResumenTexto(),
              'Recibo copiado al portapapeles',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (r.estaReembolsada) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.currency_exchange_rounded,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Esta reserva fue reembolsada. Los asientos han sido liberados y el pasaje ya no está activo.',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // TARJETA PRINCIPAL DEL RECIBO / PASE DE ABORDAR
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera aerolínea + código
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.indigo.shade900,
                              Colors.blue.shade800,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.flight_takeoff_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'AeroAndes',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: fondoEstado,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        iconoEstado,
                                        size: 14,
                                        color: colorEstado,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        tituloEstado,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: colorEstado,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Código de reserva',
                                      style: TextStyle(
                                        color: Colors.blue.shade100,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    SelectableText(
                                      r.codigoReserva,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  tooltip: 'Copiar código',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.15,
                                    ),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _copiarTexto(
                                    r.codigoReserva,
                                    'Código ${r.codigoReserva} copiado',
                                  ),
                                  icon: const Icon(Icons.copy, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Ruta y horarios
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ORIGEN',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _origen,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$_fechaSalida • $_horaSalida',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.flight_rounded,
                                        color: Colors.indigo.shade700,
                                        size: 26,
                                      ),
                                      Text(
                                        'Directo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'DESTINO',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _destino,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo.shade900,
                                        ),
                                      ),
                                      if (_horaLlegada != null &&
                                          _horaLlegada!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_fechaLlegada ?? _fechaSalida} • $_horaLlegada',
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Asientos asignados
                            Text(
                              'Asientos asignados ($cantidad)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (asientos.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: asientos
                                    .map(
                                      (asiento) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.indigo.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.event_seat_rounded,
                                              size: 14,
                                              color: Colors.indigo.shade800,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              asiento,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo.shade900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              )
                            else
                              Text(
                                r.asientos ?? 'Asignados en mostrador',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Política de reembolso y fecha de emisión
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _esReembolsable
                                        ? Colors.teal.shade50
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _esReembolsable
                                          ? Colors.teal.shade200
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _esReembolsable
                                            ? Icons.currency_exchange_rounded
                                            : Icons.block_rounded,
                                        size: 14,
                                        color: _esReembolsable
                                            ? Colors.teal.shade800
                                            : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _esReembolsable
                                            ? 'Tarifa reembolsable'
                                            : 'Tarifa no reembolsable',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _esReembolsable
                                              ? Colors.teal.shade900
                                              : Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (r.fechaReserva != null &&
                                    r.fechaReserva!.isNotEmpty)
                                  Text(
                                    'Emitido: ${r.fechaReserva}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),

                            if (usuario != null) ...[
                              const Divider(height: 28),
                              Text(
                                'Datos del pasajero',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _filaDato('Nombre', usuario.nombre),
                              const SizedBox(height: 4),
                              _filaDato('Cédula / RUC', usuario.cedulaRuc),
                              const SizedBox(height: 4),
                              _filaDato('Correo', usuario.correo),
                            ],
                          ],
                        ),
                      ),

                      // Separador tipo boleto perforado
                      _SeparadorPerforado(colorFondo: Colors.grey.shade100),

                      // Desglose financiero
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detalle de facturación',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_precioUnitario != null &&
                                _precioUnitario! > 0) ...[
                              _filaDato(
                                'Tarifa base ($cantidad x \$${_precioUnitario!.toStringAsFixed(2)})',
                                '\$${r.subtotal.toStringAsFixed(2)}',
                              ),
                              const SizedBox(height: 6),
                            ] else ...[
                              _filaDato(
                                'Subtotal',
                                '\$${r.subtotal.toStringAsFixed(2)}',
                              ),
                              const SizedBox(height: 6),
                            ],
                            _filaDato(
                              'IVA (15%)',
                              '\$${r.iva.toStringAsFixed(2)}',
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r.estaReembolsada
                                      ? 'Total reembolsado'
                                      : 'Total pagado',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${r.total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: r.estaReembolsada
                                        ? Colors.orange.shade900
                                        : Colors.indigo.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Acciones del recibo
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _copiarTexto(
                          _construirResumenTexto(),
                          'Recibo copiado al portapapeles',
                        ),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copiar recibo'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _alternarXml,
                        icon: Icon(
                          _mostrarXml ? Icons.visibility_off : Icons.code,
                        ),
                        label: Text(_mostrarXml ? 'Ocultar XML' : 'Ver XML'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_mostrarXml) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Comprobante XML oficial',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (_xmlContenido != null)
                              TextButton.icon(
                                onPressed: () => _copiarTexto(
                                  _xmlContenido!,
                                  'XML copiado al portapapeles',
                                ),
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copiar XML'),
                              ),
                          ],
                        ),
                        const Divider(),
                        if (_cargandoXml)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorXml != null)
                          Column(
                            children: [
                              Text(
                                _errorXml!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  _xmlContenido = null;
                                  _mostrarXml = false;
                                  _alternarXml();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          )
                        else if (_xmlContenido != null)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              _xmlContenido!,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filaDato(String etiqueta, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _SeparadorPerforado extends StatelessWidget {
  final Color colorFondo;
  const _SeparadorPerforado({required this.colorFondo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 24,
            decoration: BoxDecoration(
              color: colorFondo,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = (constraints.maxWidth / 10).floor();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    count,
                    (_) => Container(
                      width: 5,
                      height: 1.5,
                      color: Colors.grey.shade300,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: 12,
            height: 24,
            decoration: BoxDecoration(
              color: colorFondo,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
