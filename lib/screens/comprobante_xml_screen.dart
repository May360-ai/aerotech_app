import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reserva_model.dart';
import '../models/vuelo_model.dart';

class ComprobanteXmlScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final asientos = asientosSeleccionados.isEmpty
        ? reserva.asientos ?? 'Consulta los asientos de tu reserva'
        : asientosSeleccionados.join(', ');
    final detalle = [
      'Código de reserva: ${reserva.codigoReserva}',
      '${vuelo?.origen ?? reserva.origen ?? "Origen pendiente"} a ${vuelo?.destino ?? reserva.destino ?? "Destino pendiente"}',
      'Salida: ${vuelo?.fecha ?? reserva.fecha ?? "Por confirmar"} a las ${vuelo?.horaSalida ?? reserva.horaSalida ?? "Por confirmar"}',
      'Estado: ${reserva.estado}',
      'Asientos: $asientos',
      'Subtotal: \$${reserva.subtotal.toStringAsFixed(2)}',
      'IVA: \$${reserva.iva.toStringAsFixed(2)}',
      'Total de la reserva: \$${reserva.total.toStringAsFixed(2)}',
    ].join('\n');

    return Scaffold(
      appBar: AppBar(title: const Text('Comprobante de reserva')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (reserva.estaReembolsada) ...[
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SelectionArea(
              child: Text(
                detalle,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copiar comprobante'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: detalle));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comprobante copiado')),
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
