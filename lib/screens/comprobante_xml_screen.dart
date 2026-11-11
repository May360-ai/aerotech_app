import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reserva_model.dart';

class ComprobanteXmlScreen extends StatelessWidget {
  final Reserva reserva;
  final String xmlContent;

  const ComprobanteXmlScreen({
    super.key,
    required this.reserva,
    required this.xmlContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprobante SOA (XML)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar XML al portapapeles',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: xmlContent));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comprobante XML copiado al portapapeles')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Reserva #${reserva.id} Confirmada!',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('Código: ${reserva.codigoReserva} | Total: \$${reserva.total.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black87,
            child: const Row(
              children: [
                Icon(Icons.code, color: Colors.amberAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  'Payload HTTP Response (application/xml)',
                  style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E), // Estilo editor de código
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: SingleChildScrollView(
                child: SelectableText(
                  xmlContent.isEmpty ? '<!-- Sin contenido XML -->' : xmlContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFF9CDCFE), // Sintaxis legible
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.tonalIcon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.home),
              label: const Text('Volver al Catálogo de Vuelos'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}