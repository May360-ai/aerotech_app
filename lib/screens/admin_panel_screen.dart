import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/usuario_model.dart';
import '../models/origen_model.dart';
import '../models/vuelo_model.dart';
import '../services/api_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administración SOA'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.location_city), text: 'Orígenes'),
              Tab(icon: Icon(Icons.flight_takeoff), text: 'Vuelos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GestionUsuariosTab(),
            _GestionOrigenesTab(),
            _GestionVuelosTab(),
          ],
        ),
      ),
    );
  }
}

// ==================== TAB 1: GESTIÓN DE USUARIOS ====================
class _GestionUsuariosTab extends StatefulWidget {
  const _GestionUsuariosTab();

  @override
  State<_GestionUsuariosTab> createState() => _GestionUsuariosTabState();
}

class _GestionUsuariosTabState extends State<_GestionUsuariosTab> {
  late Future<List<Usuario>> _futureUsuarios;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futureUsuarios = ApiService().obtenerUsuariosAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Usuario>>(
      future: _futureUsuarios,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final usuarios = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final u = usuarios[index];
            final esElMismo = u.id == ApiService().usuarioActual?.id;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: u.activo ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: u.activo ? Colors.green : Colors.red),
                ),
                title: Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${u.correo}\nCédula: ${u.cedulaRuc} | Rol: ${u.rol.toUpperCase()}'),
                isThreeLine: true,
                trailing: Switch(
                  value: u.activo,
                  onChanged: esElMismo
                      ? null
                      : (valor) async {
                          try {
                            await ApiService().alternarEstadoUsuario(u.id, valor);
                            _cargar();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                            );
                          }
                        },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==================== TAB 2: GESTIÓN DE ORÍGENES (EDITAR Y SOFT DELETE) ====================
class _GestionOrigenesTab extends StatefulWidget {
  const _GestionOrigenesTab();

  @override
  State<_GestionOrigenesTab> createState() => _GestionOrigenesTabState();
}

class _GestionOrigenesTabState extends State<_GestionOrigenesTab> {
  late Future<List<Origen>> _futureOrigenes;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futureOrigenes = ApiService().obtenerTodosOrigenesAdmin();
    });
  }

  void _dialogoOrigen({Origen? origenEditar}) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: origenEditar?.nombre ?? '');
    final iataCtrl = TextEditingController(text: origenEditar?.codigoIata ?? '');
    bool activo = origenEditar?.activo ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(origenEditar == null ? 'Nuevo Origen' : 'Editar Origen'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder()),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s\(\)\-]'))],
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 letras' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: iataCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Código IATA (3 letras)', border: OutlineInputBorder()),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')), LengthLimitingTextInputFormatter(3)],
                  validator: (v) => (v == null || v.trim().length != 3) ? 'Exactamente 3 letras' : null,
                ),
                if (origenEditar != null) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Estado Activo'),
                    value: activo,
                    onChanged: (v) => setDialogState(() => activo = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  if (origenEditar == null) {
                    await ApiService().crearOrigen(nombreCtrl.text.trim(), iataCtrl.text.trim().toUpperCase());
                  } else {
                    await ApiService().editarOrigen(origenEditar.id, nombreCtrl.text.trim(), iataCtrl.text.trim().toUpperCase(), activo);
                  }
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _cargar();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarSoftDelete(Origen o) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar Origen'),
        content: Text('¿Desea dar de baja "${o.nombre}" (${o.codigoIata})? No se mostrará en los filtros para nuevos vuelos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ApiService().softDeleteOrigen(o.id);
                if (!mounted) return;
                Navigator.pop(ctx);
                _cargar();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _dialogoOrigen(),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Nuevo Origen'),
      ),
      body: FutureBuilder<List<Origen>>(
        future: _futureOrigenes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final origenes = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
            itemCount: origenes.length,
            itemBuilder: (context, index) {
              final o = origenes[index];
              return Card(
                color: o.activo ? Colors.white : Colors.grey.shade200,
                child: ListTile(
                  leading: Chip(
                    label: Text(o.codigoIata, style: TextStyle(fontWeight: FontWeight.bold, color: o.activo ? Colors.black : Colors.grey)),
                  ),
                  title: Text(o.nombre, style: TextStyle(fontWeight: FontWeight.bold, decoration: o.activo ? null : TextDecoration.lineThrough)),
                  subtitle: Text(o.activo ? 'Habilitado' : 'Desactivado (Soft Delete)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _dialogoOrigen(origenEditar: o)),
                      if (o.activo)
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmarSoftDelete(o)),
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

// ==================== TAB 3: GESTIÓN DE VUELOS (HORARIOS NOCTURNOS + EDITAR + SOFT DELETE) ====================
class _GestionVuelosTab extends StatefulWidget {
  const _GestionVuelosTab();

  @override
  State<_GestionVuelosTab> createState() => _GestionVuelosTabState();
}

class _GestionVuelosTabState extends State<_GestionVuelosTab> {
  late Future<List<Vuelo>> _futureVuelos;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _futureVuelos = ApiService().obtenerVuelos();
    });
  }

  void _modalVuelo({Vuelo? vueloEditar}) async {
    final origenes = await ApiService().obtenerOrigenes();
    if (origenes.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Se requieren al menos 2 orígenes activos.')));
      return;
    }

    final formKey = GlobalKey<FormState>();

    String origenSel = vueloEditar?.origen ?? origenes[0].nombre;
    String destinoSel = vueloEditar?.destino ?? origenes[1].nombre;

    DateTime fechaSalida = vueloEditar != null ? DateTime.parse(vueloEditar.fecha) : DateTime.now().add(const Duration(days: 1));
    DateTime fechaLlegada = vueloEditar != null ? DateTime.parse(vueloEditar.fechaLlegada) : fechaSalida;

    TimeOfDay horaSalida = vueloEditar != null
        ? TimeOfDay(hour: int.parse(vueloEditar.horaSalida.split(':')[0]), minute: int.parse(vueloEditar.horaSalida.split(':')[1]))
        : const TimeOfDay(hour: 23, minute: 0); // Ejemplo nocturno default: 23:00

    TimeOfDay horaLlegada = vueloEditar != null
        ? TimeOfDay(hour: int.parse(vueloEditar.horaLlegada.split(':')[0]), minute: int.parse(vueloEditar.horaLlegada.split(':')[1]))
        : const TimeOfDay(hour: 3, minute: 0);  // Ejemplo nocturno default: 03:00 del día siguiente

    final precioCtrl = TextEditingController(text: vueloEditar?.precio.toStringAsFixed(2) ?? "85.00");
    final capacidadCtrl = TextEditingController(text: vueloEditar?.asientosTotales.toString() ?? "40");

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          String formatFecha(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
          String formatHora(TimeOfDay t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

          final dtSalida = DateTime(fechaSalida.year, fechaSalida.month, fechaSalida.day, horaSalida.hour, horaSalida.minute);
          final dtLlegada = DateTime(fechaLlegada.year, fechaLlegada.month, fechaLlegada.day, horaLlegada.hour, horaLlegada.minute);
          final esCruceDeMedianoche = dtLlegada.day != dtSalida.day;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(vueloEditar == null ? 'Programar Vuelo' : 'Editar Vuelo #${vueloEditar.id}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: origenSel,
                      decoration: const InputDecoration(labelText: 'Origen', border: OutlineInputBorder()),
                      items: origenes.map((o) => DropdownMenuItem(value: o.nombre, child: Text(o.nombre))).toList(),
                      onChanged: (v) => setModalState(() => origenSel = v!),
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: destinoSel,
                      decoration: const InputDecoration(labelText: 'Destino', border: OutlineInputBorder()),
                      items: origenes.map((o) => DropdownMenuItem(value: o.nombre, child: Text(o.nombre))).toList(),
                      onChanged: (v) => setModalState(() => destinoSel = v!),
                      validator: (v) => (v == origenSel) ? 'Origen y destino no pueden ser iguales' : null,
                    ),
                    const SizedBox(height: 12),

                    // SALIDA: Fecha y Hora
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Fecha Salida', style: TextStyle(fontSize: 12)),
                            subtitle: Text(formatFecha(fechaSalida), style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.calendar_today, size: 18),
                            onTap: () async {
                              final p = await showDatePicker(
                                context: context,
                                initialDate: fechaSalida,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (p != null) {
                                setModalState(() {
                                  fechaSalida = p;
                                  if (fechaLlegada.isBefore(p)) fechaLlegada = p;
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Hora Salida', style: TextStyle(fontSize: 12)),
                            subtitle: Text(formatHora(horaSalida), style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.access_time, size: 18),
                            onTap: () async {
                              final p = await showTimePicker(context: context, initialTime: horaSalida);
                              if (p != null) setModalState(() => horaSalida = p);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(),

                    // LLEGADA: Fecha y Hora (Soporta Cruce de Medianoche)
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Fecha Llegada', style: TextStyle(fontSize: 12)),
                            subtitle: Text(formatFecha(fechaLlegada), style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.calendar_month, size: 18),
                            onTap: () async {
                              final p = await showDatePicker(
                                context: context,
                                initialDate: fechaLlegada,
                                firstDate: fechaSalida, // No puede llegar en fecha anterior a la salida
                                lastDate: fechaSalida.add(const Duration(days: 3)),
                              );
                              if (p != null) setModalState(() => fechaLlegada = p);
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Hora Llegada', style: TextStyle(fontSize: 12)),
                            subtitle: Text(formatHora(horaLlegada), style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Icon(Icons.access_time_filled, size: 18),
                            onTap: () async {
                              final p = await showTimePicker(context: context, initialTime: horaLlegada);
                              if (p != null) setModalState(() => horaLlegada = p);
                            },
                          ),
                        ),
                      ],
                    ),

                    // Badge informativo de vuelo nocturno
                    if (esCruceDeMedianoche)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber)),
                        child: Row(
                          children: const [
                            Icon(Icons.nightlight_round, color: Colors.amber, size: 18),
                            SizedBox(width: 8),
                            Expanded(child: Text('Vuelo Nocturno: Llega al día siguiente (+1 día)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: precioCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Precio (\$)', border: OutlineInputBorder()),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Mayor a 0' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: capacidadCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Butacas (10-350)', border: OutlineInputBorder()),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              final n = int.tryParse(v ?? '') ?? 0;
                              return (n < 10 || n > 350) ? '10 - 350' : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    FilledButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        // Comprobación Timestamp completa
                        if (!dtLlegada.isAfter(dtSalida)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('La fecha y hora de llegada deben ser posteriores a la salida.'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        try {
                          if (vueloEditar == null) {
                            await ApiService().crearVueloAdmin(
                              origen: origenSel,
                              destino: destinoSel,
                              fecha: formatFecha(fechaSalida),
                              fechaLlegada: formatFecha(fechaLlegada),
                              horaSalida: formatHora(horaSalida),
                              horaLlegada: formatHora(horaLlegada),
                              precio: double.parse(precioCtrl.text),
                              asientosTotales: int.parse(capacidadCtrl.text),
                            );
                          } else {
                            await ApiService().editarVueloAdmin(
                              id: vueloEditar.id,
                              origen: origenSel,
                              destino: destinoSel,
                              fecha: formatFecha(fechaSalida),
                              fechaLlegada: formatFecha(fechaLlegada),
                              horaSalida: formatHora(horaSalida),
                              horaLlegada: formatHora(horaLlegada),
                              precio: double.parse(precioCtrl.text),
                              asientosTotales: int.parse(capacidadCtrl.text),
                            );
                          }
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          _cargar();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: Text(vueloEditar == null ? 'Publicar Vuelo' : 'Guardar Cambios'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmarSoftDeleteVuelo(Vuelo v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar Vuelo (Soft Delete)'),
        content: Text('¿Desea dar de baja el vuelo #${v.id} (${v.origen} ➔ ${v.destino})? Se retirará de la venta al público sin afectar las reservas ya emitidas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ApiService().softDeleteVueloAdmin(v.id);
                if (!mounted) return;
                Navigator.pop(ctx);
                _cargar();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _modalVuelo(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Vuelo'),
      ),
      body: FutureBuilder<List<Vuelo>>(
        future: _futureVuelos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final vuelos = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
            itemCount: vuelos.length,
            itemBuilder: (context, index) {
              final v = vuelos[index];
              final esNocturno = v.fechaLlegada != v.fecha;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.flight, color: Colors.indigo),
                  title: Text('${v.origen} ➔ ${v.destino}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Salida: ${v.fecha} ${v.horaSalida}\n'
                    'Llegada: ${v.fechaLlegada} ${v.horaLlegada} ${esNocturno ? "(+1 día)" : ""}\n'
                    '\$${v.precio.toStringAsFixed(2)} | Cupos: ${v.asientosDisponibles}/${v.asientosTotales}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _modalVuelo(vueloEditar: v)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmarSoftDeleteVuelo(v)),
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