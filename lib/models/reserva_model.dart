class Reserva {
  final int id;
  final String codigoReserva;
  final double subtotal;
  final double iva;
  final double total;
  final String estado;

  Reserva({
    required this.id,
    required this.codigoReserva,
    required this.subtotal,
    required this.iva,
    required this.total,
    required this.estado,
  });

  static double _parseMoney(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Reserva.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['reserva_id'];
    return Reserva(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      codigoReserva: json['codigo_reserva']?.toString() ?? 'TICK-GEN',
      subtotal: _parseMoney(json['subtotal']),
      iva: _parseMoney(json['iva']),
      total: _parseMoney(json['total']),
      estado: json['estado']?.toString() ?? 'confirmada',
    );
  }
}