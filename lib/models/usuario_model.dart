class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String cedulaRuc;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.cedulaRuc,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      cedulaRuc: json['cedula_ruc']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'cedula_ruc': cedulaRuc,
    };
  }
}