class Origen {
  final int id;
  final String nombre;
  final String codigoIata;
  final bool activo;

  Origen({
    required this.id,
    required this.nombre,
    required this.codigoIata,
    this.activo = true,
  });

  factory Origen.fromJson(Map<String, dynamic> json) {
    return Origen(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      codigoIata: json['codigo_iata']?.toString() ?? '',
      activo: json['activo'] == true,
    );
  }
}