import 'package:flutter/material.dart';
import '../models/vuelo_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'reserva_screen.dart';

class VuelosScreen extends StatefulWidget {
  const VuelosScreen({super.key});

  @override
  State<VuelosScreen> createState() => _VuelosScreenState();
}

class _VuelosScreenState extends State<VuelosScreen> {
  final ApiService _api = ApiService();
  late Future<List<Vuelo>> _futureVuelos;

  @override
  void initState() {
    super.initState();
    _cargarVuelos();
  }

  void _cargarVuelos() {
    setState(() {
      _futureVuelos = _api.obtenerVuelos();
    });
  }

  void _cerrarSesion() {
    _api.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _api.usuarioActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vuelos Disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarVuelos,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
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
                    child: Text(usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : 'U'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pasajero: ${usuario.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Cédula/RUC: ${usuario.cedulaRuc}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const Chip(
                    label: Text('JWT Activo', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.white70,
                  )
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Vuelo>>(
              future: _futureVuelos,
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
                          const Icon(Icons.cloud_off, size: 50, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(snapshot.error.toString(), textAlign: TextAlign.center),
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

                final vuelos = snapshot.data ?? [];
                if (vuelos.isEmpty) {
                  return const Center(child: Text('No hay vuelos disponibles en este momento.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: vuelos.length,
                  itemBuilder: (context, index) {
                    final vuelo = vuelos[index];
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
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const Icon(Icons.flight_takeoff, color: Colors.indigo),
                                Text(
                                  vuelo.destino,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(vuelo.fecha),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
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
                                      'Cupos: ${vuelo.asientosDisponibles}',
                                      style: TextStyle(
                                        color: vuelo.asientosDisponibles > 0 ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                FilledButton.icon(
                                  onPressed: vuelo.asientosDisponibles > 0
                                      ? () async {
                                          final recargar = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ReservaScreen(vuelo: vuelo),
                                            ),
                                          );
                                          if (recargar == true) {
                                            _cargarVuelos();
                                          }
                                        }
                                      : null,
                                  icon: const Icon(Icons.airplane_ticket),
                                  label: const Text('Reservar'),
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
          ),
        ],
      ),
    );
  }
}