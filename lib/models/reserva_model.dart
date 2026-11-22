class Reserva {
  final int id;
  final String codigoReserva;
  final double subtotal;
  final double iva;
  final double total;
  final String estado;
  final String? origen;
  final String? destino;
  final String? fecha;
  final String? fechaLlegada;
  final String? horaSalida;
  final String? horaLlegada;
  final String? asientos;
  final String? fechaReserva;
  final int? cantidadAsientos;
  final double? precioUnitario;
  final bool reembolsable;

  Reserva({
    required this.id,
    required this.codigoReserva,
    required this.subtotal,
    required this.iva,
    required this.total,
    required this.estado,
    this.origen,
    this.destino,
    this.fecha,
    this.fechaLlegada,
    this.horaSalida,
    this.horaLlegada,
    this.asientos,
    this.fechaReserva,
    this.cantidadAsientos,
    this.precioUnitario,
    this.reembolsable = true,
  });

  static double _parseMoney(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get estaReembolsada => estado.trim().toLowerCase() == 'reembolsada';
  bool get estaCancelada => estado.trim().toLowerCase() == 'cancelada';

  DateTime? get fechaHoraSalida {
    final f = fecha?.trim() ?? '';
    if (f.isEmpty) return null;
    final base = DateTime.tryParse(f);
    if (base == null) return null;

    final h = horaSalida?.trim() ?? '';
    if (h.isEmpty) return DateTime(base.year, base.month, base.day, 23, 59, 59);
    final partes = h.split(':');
    final hora = partes.isNotEmpty ? int.tryParse(partes[0]) : null;
    final minuto = partes.length > 1 ? int.tryParse(partes[1]) : 0;
    final segundo = partes.length > 2 ? int.tryParse(partes[2]) : 0;
    if (hora == null || minuto == null || segundo == null) {
      return DateTime(base.year, base.month, base.day, 23, 59, 59);
    }
    return DateTime(base.year, base.month, base.day, hora, minuto, segundo);
  }

  bool get vueloYaPartio {
    final salida = fechaHoraSalida;
    if (salida == null) return false;
    return !salida.isAfter(DateTime.now());
  }

  bool get puedeSolicitarReembolso =>
      reembolsable && !estaReembolsada && !estaCancelada && !vueloYaPartio;

  factory Reserva.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['reserva_id'];
    final rawCant = json['cantidad_asientos'];
    return Reserva(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      codigoReserva: json['codigo_reserva']?.toString() ?? 'TICK-GEN',
      subtotal: _parseMoney(json['subtotal']),
      iva: _parseMoney(json['iva']),
      total: _parseMoney(json['total']),
      estado: json['estado']?.toString() ?? 'confirmada',
      origen: json['origen']?.toString(),
      destino: json['destino']?.toString(),
      fecha: json['fecha']?.toString(),
      fechaLlegada: json['fecha_llegada']?.toString(),
      horaSalida: json['hora_salida']?.toString(),
      horaLlegada: json['hora_llegada']?.toString(),
      asientos: json['asientos']?.toString(),
      fechaReserva: json['fecha_reserva']?.toString(),
      cantidadAsientos: rawCant is int
          ? rawCant
          : int.tryParse(rawCant?.toString() ?? ''),
      precioUnitario: json['precio'] != null
          ? _parseMoney(json['precio'])
          : null,
      reembolsable: json['reembolsable'] == null
          ? true
          : (json['reembolsable'] == true ||
                json['reembolsable'] == 1 ||
                json['reembolsable'] == 'true'),
    );
  }
}

class ReembolsoResultado {
  final int reservaId;
  final String codigoReserva;
  final double montoReembolsado;
  final double subtotal;
  final double iva;
  final String? asientosLiberados;
  final String motivo;
  final String fechaReembolso;
  final String estado;

  ReembolsoResultado({
    required this.reservaId,
    required this.codigoReserva,
    required this.montoReembolsado,
    required this.subtotal,
    required this.iva,
    this.asientosLiberados,
    required this.motivo,
    required this.fechaReembolso,
    required this.estado,
  });

  factory ReembolsoResultado.fromJson(Map<String, dynamic> json) {
    final rawId = json['reserva_id'] ?? json['id'];
    return ReembolsoResultado(
      reservaId: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      codigoReserva: json['codigo_reserva']?.toString() ?? '',
      montoReembolsado: Reserva._parseMoney(json['monto_reembolsado']),
      subtotal: Reserva._parseMoney(json['subtotal']),
      iva: Reserva._parseMoney(json['iva']),
      asientosLiberados: json['asientos_liberados']?.toString(),
      motivo: json['motivo']?.toString() ?? 'Solicitud del pasajero',
      fechaReembolso: json['fecha_reembolso']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'reembolsada',
    );
  }
}