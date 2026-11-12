class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String cedulaRuc;
  final String rol;
  final bool activo;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.cedulaRuc,
    this.rol = 'cliente',
    this.activo = true,
  });

  bool get isAdmin => rol == 'admin';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      cedulaRuc: json['cedula_ruc']?.toString() ?? '',
      rol: json['rol']?.toString() ?? 'cliente',
      activo: json['activo'] == true || json['activo'] == 1 || json['activo'] == 'true',
    );
  }
}