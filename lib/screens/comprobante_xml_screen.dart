import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reserva_model.dart';
import '../models/vuelo_model.dart';
import '../services/api_service.dart';

class ComprobanteXmlScreen extends StatelessWidget {
  final Reserva reserva;
  final String xmlContent;
  final List<String> asientosSeleccionados;
  final Vuelo? vuelo;

  const ComprobanteXmlScreen({
    super.key,
    required this.reserva,
    required this.xmlContent,
    this.asientosSeleccionados = const [],
    this.vuelo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usuario = ApiService().usuarioActual;

    // Obtener datos consolidados (desde el vuelo o desde la reserva)
    final origen = vuelo?.origen ?? reserva.origen ?? 'Quito (UIO)';
    final destino = vuelo?.destino ?? reserva.destino ?? 'Guayaquil (GYE)';
    final fechaVuelo = vuelo?.fecha ?? reserva.fecha ?? '2026-06-21';
    final horaSalida = vuelo?.horaSalida ?? reserva.horaSalida ?? '08:00';
    final listaAsientos = asientosSeleccionados.isNotEmpty
        ? asientosSeleccionados
        : (reserva.asientos != null
            ? reserva.asientos!.split(',').map((e) => e.trim()).toList()
            : ['Asignado']);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Boleto Electrónico'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, true),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.airplane_ticket), text: 'Boleto Renderizado'),
              Tab(icon: Icon(Icons.code), text: 'XML Crudo (SOA)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ================= PESTAÑA 1: BOLETO DIGITAL RENDERIZADO =================
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Tarjeta tipo Pase de Abordar / Factura Comercial
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cabecera de la Aerolínea
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.flight_takeoff, color: Colors.white, size: 26),
                                  SizedBox(width: 8),
                                  Text(
                                    'AeroTech Airlines',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  reserva.estado.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sección de Ruta de Vuelo
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ORIGEN', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(origen, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.arrow_forward_rounded, color: Colors.indigo, size: 28),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('DESTINO', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(destino, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Grid de Itinerario
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildDetalle('FECHA', fechaVuelo),
                                  _buildDetalle('HORA SALIDA', horaSalida),
                                  _buildDetalle('PUERTA', 'GATE 3'),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Separador Perforado de Boleto
                        Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 28,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                                ),
                              ),
                            ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Flex(
                                    direction: Axis.horizontal,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      (constraints.constrainWidth() / 10).floor(),
                                      (_) => const SizedBox(width: 5, height: 1.5, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey))),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              width: 14,
                              height: 28,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Datos del Pasajero y Asientos
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('PASAJERO TITULAR', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(usuario?.nombre ?? 'Pasajero Registrado', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('CÉDULA / RUC', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(usuario?.cedulaRuc ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Asientos Asignados
                              Text('ASIENTOS RESERVADOS', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: listaAsientos.map((asiento) {
                                  return Chip(
                                    avatar: const Icon(Icons.airline_seat_recline_normal, size: 16, color: Colors.white),
                                    label: Text(asiento, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    backgroundColor: theme.colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                  );
                                }).toList(),
                              ),
                              const Divider(height: 28),

                              // Desglose Financiero (Factura Electrónica SOA)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Subtotal', style: TextStyle(color: Colors.grey.shade700)),
                                  Text('\$${reserva.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('IVA (15%)', style: TextStyle(color: Colors.grey.shade700)),
                                  Text('\$${reserva.iva.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL PAGADO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(
                                    '\$${reserva.total.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Simulación de Código de Barras Electrónico
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      height: 44,
                                      width: 240,
                                      color: Colors.transparent,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(42, (index) {
                                          return Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                            width: (index % 3 == 0) ? 3.5 : ((index % 2 == 0) ? 2 : 1),
                                            color: Colors.black87,
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      reserva.codigoReserva,
                                      style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.home),
                    label: const Text('Volver al Catálogo de Vuelos'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),

            // ================= PESTAÑA 2: XML CRUDO (INTEROPERABILIDAD SOA) =================
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.black87,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.code, color: Colors.amberAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'XML Response (application/xml)',
                            style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                        tooltip: 'Copiar XML',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: xmlContent));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('XML copiado al portapapeles')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFF1E1E1E),
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        xmlContent.isEmpty ? '<!-- Sin contenido XML -->' : xmlContent,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Color(0xFF9CDCFE),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalle(String titulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}