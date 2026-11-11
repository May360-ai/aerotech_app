class Vuelo {
  final int id;
  final String origen;
  final String destino;
  final String fecha;
  final String horaSalida;
  final String horaLlegada;
  final double precio;
  final int asientosDisponibles;

  Vuelo({
    required this.id,
    required this.origen,
    required this.destino,
    required this.fecha,
    required this.horaSalida,
    required this.horaLlegada,
    required this.precio,
    required this.asientosDisponibles,
  });

  factory Vuelo.fromJson(Map<String, dynamic> json) {
    return Vuelo(
      id: json['id'] as int,
      origen: json['origen'] as String,
      destino: json['destino'] as String,
      fecha: json['fecha'] as String,
      horaSalida: json['hora_salida'] as String,
      horaLlegada: json['hora_llegada'] as String,
      precio: (json['precio'] as num).toDouble(),
      asientosDisponibles: json['asientos_disponibles'] as int,
    );
  }
}