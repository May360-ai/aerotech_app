import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reserva_model.dart';
import '../services/api_service.dart';
import 'comprobante_xml_screen.dart';

class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  final ApiService _api = ApiService();
  late Future<List<Reserva>> _futureReservas;

  static const List<String> _motivosReembolso = [
    'Cambio de planes',
    'Error en fecha o ruta',
    'Emergencia personal',
    'Cambio de tarifa',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _cargarReservas();
  }

  void _cargarReservas() {
    setState(() {
      _futureReservas = _api.obtenerMisReservas();
    });
  }

  void _verComprobante(Reserva reserva) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComprobanteXmlScreen(
          reserva: reserva,
          asientosSeleccionados:
              reserva.asientos?.split(',').map((a) => a.trim()).toList() ?? [],
        ),
      ),
    );
  }

  Future<void> _abrirFlujoReembolso(Reserva reserva) async {
    String motivoSeleccionado = _motivosReembolso.first;
    final otroMotivoCtrl = TextEditingController();
    bool procesando = false;

    final resultado = await showDialog<ReembolsoResultado>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              icon: Icon(
                Icons.currency_exchange_rounded,
                color: Colors.orange.shade800,
                size: 36,
              ),
              title: const Text('Solicitar reembolso'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserva ${reserva.codigoReserva}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (reserva.origen != null && reserva.destino != null) ...[
                      const SizedBox(height: 4),
                      Text('${reserva.origen} a ${reserva.destino}'),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Salida: ${reserva.fecha ?? "N/A"} • ${reserva.horaSalida ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (reserva.asientos != null &&
                        reserva.asientos!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Asientos a liberar: ${reserva.asientos}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Divider(height: 20),
                    _filaResumen(
                      'Subtotal',
                      '\$${reserva.subtotal.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 4),
                    _filaResumen(
                      'IVA (15%)',
                      '\$${reserva.iva.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 6),
                    _filaResumen(
                      'Monto a reembolsar',
                      '\$${reserva.total.toStringAsFixed(2)}',
                      destacado: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: motivoSeleccionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Motivo del reembolso',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _motivosReembolso
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: procesando
                          ? null
                          : (valor) {
                              if (valor == null) return;
                              setDialogState(() => motivoSeleccionado = valor);
                            },
                    ),
                    if (motivoSeleccionado == 'Otro') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: otroMotivoCtrl,
                        enabled: !procesando,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Describe el motivo',
                          hintText: 'Ej. Reprogramación de viaje',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: Colors.orange.shade900,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Al confirmar, tus asientos se liberarán inmediatamente y el pasaje pasará a estado REEMBOLSADA.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: procesando
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                  ),
                  onPressed: procesando
                      ? null
                      : () async {
                          final motivoFinal = motivoSeleccionado == 'Otro' &&
                                  otroMotivoCtrl.text.trim().isNotEmpty
                              ? otroMotivoCtrl.text.trim()
                              : motivoSeleccionado;

                          setDialogState(() => procesando = true);
                          try {
                            final res = await _api.solicitarReembolso(
                              reservaId: reserva.id,
                              motivo: motivoFinal,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, res);
                            }
                          } catch (e) {
                            setDialogState(() => procesando = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  icon: procesando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    procesando ? 'Procesando...' : 'Confirmar reembolso',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    otroMotivoCtrl.dispose();

    if (resultado != null && mounted) {
      _cargarReservas();
      await _mostrarComprobanteReembolso(resultado);
    }
  }

  Future<void> _mostrarComprobanteReembolso(ReembolsoResultado resultado) {
    final textoResumen = [
      'COMPROBANTE DE REEMBOLSO - AEROANDES',
      'Código de reserva: ${resultado.codigoReserva}',
      'Estado: ${resultado.estado.toUpperCase()}',
      if (resultado.asientosLiberados != null &&
          resultado.asientosLiberados!.isNotEmpty)
        'Asientos liberados: ${resultado.asientosLiberados}',
      'Motivo: ${resultado.motivo}',
      if (resultado.fechaReembolso.isNotEmpty)
        'Fecha de reembolso: ${resultado.fechaReembolso}',
      'Subtotal: \$${resultado.subtotal.toStringAsFixed(2)}',
      'IVA (15%): \$${resultado.iva.toStringAsFixed(2)}',
      'Monto reembolsado: \$${resultado.montoReembolsado.toStringAsFixed(2)}',
    ].join('\n');

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green.shade700,
                      size: 40,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Comprobante de Reembolso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resultado.codigoReserva,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _filaResumen('Estado', resultado.estado.toUpperCase()),
              if (resultado.asientosLiberados != null &&
                  resultado.asientosLiberados!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _filaResumen('Asientos liberados', resultado.asientosLiberados!),
              ],
              const SizedBox(height: 8),
              _filaResumen('Motivo', resultado.motivo),
              if (resultado.fechaReembolso.isNotEmpty) ...[
                const SizedBox(height: 8),
                _filaResumen('Fecha', resultado.fechaReembolso),
              ],
              const Divider(height: 22),
              _filaResumen(
                'Subtotal',
                '\$${resultado.subtotal.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 6),
              _filaResumen(
                'IVA (15%)',
                '\$${resultado.iva.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              _filaResumen(
                'Total reembolsado',
                '\$${resultado.montoReembolsado.toStringAsFixed(2)}',
                destacado: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: textoResumen));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comprobante de reembolso copiado'),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _filaResumen(String etiqueta, String valor, {bool destacado = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: destacado ? 15 : 13,
              fontWeight: destacado ? FontWeight.bold : FontWeight.w600,
              color: destacado ? Colors.indigo.shade900 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoChip(Reserva r) {
    Color fondo;
    Color borde;
    Color texto;

    if (r.estaReembolsada) {
      fondo = Colors.amber.shade50;
      borde = Colors.orange.shade300;
      texto = Colors.orange.shade900;
    } else if (r.estaCancelada) {
      fondo = Colors.red.shade50;
      borde = Colors.red.shade300;
      texto = Colors.red.shade900;
    } else {
      fondo = Colors.green.shade50;
      borde = Colors.green.shade300;
      texto = Colors.green.shade900;
    }

    return Chip(
      label: Text(
        r.estado.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: texto,
        ),
      ),
      backgroundColor: fondo,
      side: BorderSide(color: borde),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarReservas,
          ),
        ],
      ),
      body: FutureBuilder<List<Reserva>>(
        future: _futureReservas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString().replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _cargarReservas,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final reservas = snapshot.data ?? [];
          if (reservas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.airplane_ticket_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Todavía no tienes reservas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reserva tu primer vuelo desde el catálogo.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final r = reservas[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              r.codigoReserva,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _buildEstadoChip(r),
                        ],
                      ),
                      const Divider(height: 16),
                      if (r.origen != null && r.destino != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.flight_takeoff,
                              size: 20,
                              color: Colors.indigo,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${r.origen} a ${r.destino}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${r.fecha ?? "N/A"}  |  Salida: ${r.horaSalida ?? "N/A"}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_seat,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Asientos: ${r.asientos ?? (r.subtotal > 0 ? "Asignados" : "N/A")}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            r.estaReembolsada
                                ? 'Reembolsado: \$${r.total.toStringAsFixed(2)}'
                                : 'Total: \$${r.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: r.estaReembolsada
                                  ? Colors.orange.shade900
                                  : Colors.black87,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (r.puedeSolicitarReembolso)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange.shade900,
                                    side: BorderSide(
                                      color: Colors.orange.shade400,
                                    ),
                                  ),
                                  onPressed: () => _abrirFlujoReembolso(r),
                                  icon: const Icon(
                                    Icons.currency_exchange_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Reembolso'),
                                )
                              else if (!r.reembolsable &&
                                  !r.estaReembolsada &&
                                  !r.estaCancelada)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    'No reembolsable',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              OutlinedButton.icon(
                                onPressed: () => _verComprobante(r),
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text('Ver Recibo'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
