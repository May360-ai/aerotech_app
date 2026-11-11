import 'package:flutter/material.dart';
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

  Future<void> _verComprobante(Reserva reserva) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final xml = await _api.obtenerComprobanteXml(reserva.id);
      if (!mounted) return;
      Navigator.pop(context); // Cierra loader

      final listaAsientos = reserva.asientos != null
          ? reserva.asientos!.split(',').map((e) => e.trim()).toList()
          : <String>[];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComprobanteXmlScreen(
            reserva: reserva,
            xmlContent: xml,
            asientosSeleccionados: listaAsientos,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cierra loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener XML: $e'), backgroundColor: Colors.redAccent),
      );
    }
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
                    const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _cargarReservas, child: const Text('Reintentar')),
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
                  Icon(Icons.airplane_ticket_outlined, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 14),
                  const Text('No tienes reservaciones activas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Reserva tu primer vuelo desde el catálogo.', style: TextStyle(color: Colors.grey.shade600)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r.codigoReserva,
                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16),
                          ),
                          Chip(
                            label: Text(r.estado.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.green.shade50,
                            side: BorderSide(color: Colors.green.shade300),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      if (r.origen != null && r.destino != null)
                        Row(
                          children: [
                            const Icon(Icons.flight_takeoff, size: 20, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text(
                              '${r.origen} ➔ ${r.destino}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('${r.fecha ?? "N/A"}  |  Salida: ${r.horaSalida ?? "N/A"}', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.event_seat, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Asientos: ${r.asientos ?? "${r.subtotal > 0 ? "Asignados" : "N/A"}"}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pagado: \$${r.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _verComprobante(r),
                            icon: const Icon(Icons.code, size: 18),
                            label: const Text('Ver Pasaje'),
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