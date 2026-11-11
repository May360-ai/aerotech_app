class Vuelo {
  final int id;
  final String origen;
  final String destino;
  final String fecha;
  final String horaSalida;
  final String horaLlegada;
  final double precio;
  final int asientosDisponibles;
  final int asientosTotales;

  Vuelo({
    required this.id,
    required this.origen,
    required this.destino,
    required this.fecha,
    required this.horaSalida,
    required this.horaLlegada,
    required this.precio,
    required this.asientosDisponibles,
    this.asientosTotales = 40,
  });

  static double _parseMoney(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Vuelo.fromJson(Map<String, dynamic> json) {
    return Vuelo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      origen: json['origen']?.toString() ?? '',
      destino: json['destino']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      horaSalida: json['hora_salida']?.toString() ?? '',
      horaLlegada: json['hora_llegada']?.toString() ?? '',
      precio: _parseMoney(json['precio']),
      asientosDisponibles: json['asientos_disponibles'] is int
          ? json['asientos_disponibles']
          : int.tryParse(json['asientos_disponibles'].toString()) ?? 0,
      asientosTotales: json['asientos_totales'] is int
          ? json['asientos_totales']
          : int.tryParse(json['asientos_totales']?.toString() ?? '') ?? 40,
    );
  }
}