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
  int _cantidadAsientos = 1;
  bool _procesando = false;

  double get subtotal => widget.vuelo.precio * _cantidadAsientos;
  double get iva => subtotal * 0.15; // 15% IVA vigente
  double get total => subtotal + iva;

  Future<void> _confirmarReserva() async {
    setState(() => _procesando = true);
    try {
      final reserva = await _api.crearReserva(
        vueloId: widget.vuelo.id,
        cantidad: _cantidadAsientos,
      );

      if (!mounted) return;

      // Descargamos de inmediato el XML para evidenciar el contrato SOA
      final rawXml = await _api.obtenerComprobanteXml(reserva.id);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ComprobanteXmlScreen(
            reserva: reserva,
            xmlContent: rawXml,
          ),
        ),
      );
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
    final usuario = _api.usuarioActual;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de Reserva')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Itinerario de Vuelo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${widget.vuelo.origen} ➔ ${widget.vuelo.destino}', style: const TextStyle(fontSize: 16)),
                    Text('Fecha: ${widget.vuelo.fecha} | Salida: ${widget.vuelo.horaSalida}'),
                    Text('Asientos restantes: ${widget.vuelo.asientosDisponibles}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Datos del Pasajero Titular', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Nombre: ${usuario?.nombre ?? "Invitado"}'),
                    Text('Cédula/RUC: ${usuario?.cedulaRuc ?? "N/A"}'),
                    Text('Correo: ${usuario?.correo ?? "N/A"}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cantidad de Asientos:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _cantidadAsientos > 1
                          ? () => setState(() => _cantidadAsientos--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_cantidadAsientos', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton.filledTonal(
                      onPressed: _cantidadAsientos < widget.vuelo.asientosDisponibles
                          ? () => setState(() => _cantidadAsientos++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 36),
            Text('Desglose Económico (SOA Facturación):', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal ($_cantidadAsientos x \$${widget.vuelo.precio.toStringAsFixed(2)})'),
                Text('\$${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IVA (15%)'),
                Text('\$${iva.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a Pagar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _procesando ? null : _confirmarReserva,
              icon: _procesando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_procesando ? 'Procesando Transacción...' : 'Confirmar y Emitir Boleto XML'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}