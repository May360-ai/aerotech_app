class Vuelo {
  final int id;
  final String origen;
  final String destino;
  final String fecha;
  final String fechaLlegada;
  final String horaSalida;
  final String horaLlegada;
  final double precio;
  final int asientosDisponibles;
  final int asientosTotales;
  final bool activo;
  final bool reembolsable;

  Vuelo({
    required this.id,
    required this.origen,
    required this.destino,
    required this.fecha,
    required this.fechaLlegada,
    required this.horaSalida,
    required this.horaLlegada,
    required this.precio,
    required this.asientosDisponibles,
    this.asientosTotales = 40,
    this.activo = true,
    this.reembolsable = true,
  });

  static double _parseMoney(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Combina [fecha] y [horaSalida] en un [DateTime] local para validar salidas pasadas.
  DateTime? get fechaHoraSalida {
    final fechaLimpia = fecha.trim();
    if (fechaLimpia.isEmpty) return null;

    DateTime? base = DateTime.tryParse(fechaLimpia);
    if (base == null) {
      final partes = fechaLimpia.split(RegExp(r'[-/]'));
      if (partes.length == 3) {
        final p0 = int.tryParse(partes[0]);
        final p1 = int.tryParse(partes[1]);
        final p2 = int.tryParse(partes[2]);
        if (p0 != null && p1 != null && p2 != null) {
          if (partes[0].length == 4) {
            base = DateTime(p0, p1, p2);
          } else if (partes[2].length == 4) {
            base = DateTime(p2, p1, p0);
          }
        }
      }
    }
    if (base == null) return null;

    final horaPartes = horaSalida.trim().split(':');
    final hora = horaPartes.isNotEmpty ? int.tryParse(horaPartes[0]) : null;
    final minuto = horaPartes.length > 1 ? int.tryParse(horaPartes[1]) : 0;
    final segundo = horaPartes.length > 2 ? int.tryParse(horaPartes[2]) : 0;

    if (hora == null || minuto == null || segundo == null) {
      return DateTime(base.year, base.month, base.day, 23, 59, 59);
    }

    return DateTime(base.year, base.month, base.day, hora, minuto, segundo);
  }

  /// Indica si la fecha y hora de salida del vuelo ya pasaron respecto al momento actual.
  bool get yaPaso {
    final salida = fechaHoraSalida;
    if (salida == null) return false;
    return !salida.isAfter(DateTime.now());
  }

  factory Vuelo.fromJson(Map<String, dynamic> json) {
    final fSalida = json['fecha']?.toString() ?? '';
    final fLlegada = json['fecha_llegada']?.toString() ?? fSalida;

    return Vuelo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      origen: json['origen']?.toString() ?? '',
      destino: json['destino']?.toString() ?? '',
      fecha: fSalida,
      fechaLlegada: fLlegada,
      horaSalida: json['hora_salida']?.toString() ?? '',
      horaLlegada: json['hora_llegada']?.toString() ?? '',
      precio: _parseMoney(json['precio']),
      asientosDisponibles: json['asientos_disponibles'] is int
          ? json['asientos_disponibles']
          : int.tryParse(json['asientos_disponibles'].toString()) ?? 0,
      asientosTotales: json['asientos_totales'] is int
          ? json['asientos_totales']
          : int.tryParse(json['asientos_totales'].toString()) ?? 40,
      activo: json['activo'] == true || json['activo'] == 1 || json['activo'] == 'true',
      reembolsable: json['reembolsable'] == null
          ? true
          : (json['reembolsable'] == true ||
                json['reembolsable'] == 1 ||
                json['reembolsable'] == 'true'),
    );
  }
}