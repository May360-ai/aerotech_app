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
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      cedulaRuc: json['cedula_ruc'] as String? ?? '',
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