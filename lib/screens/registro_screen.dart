import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;

  // Algoritmo oficial de validación de Cédula Ecuatoriana (Módulo 10)
  bool _validarCedulaEcuatoriana(String cedula) {
    if (cedula.length != 10) return false;
    final int provincia = int.tryParse(cedula.substring(0, 2)) ?? 0;
    if (provincia < 1 || (provincia > 24 && provincia != 30)) return false;

    final int tercerDigito = int.tryParse(cedula.substring(2, 3)) ?? 9;
    if (tercerDigito >= 6) return false; // Persona natural

    final List<int> coeficientes = [2, 1, 2, 1, 2, 1, 2, 1, 2];
    int suma = 0;

    for (int i = 0; i < 9; i++) {
      int valor = (int.tryParse(cedula[i]) ?? 0) * coeficientes[i];
      if (valor >= 10) valor -= 9;
      suma += valor;
    }

    final int digitoVerificador = int.tryParse(cedula[9]) ?? -1;
    final int decenaSuperior = (suma % 10 == 0) ? suma : ((suma ~/ 10) + 1) * 10;
    return (decenaSuperior - suma) == digitoVerificador;
  }

  // Validación de RUC (13 dígitos y los 10 primeros corresponden a una cédula válida)
  bool _validarCedulaORuc(String valor) {
    if (valor.length == 10) {
      return _validarCedulaEcuatoriana(valor);
    } else if (valor.length == 13) {
      final cedulaBase = valor.substring(0, 10);
      final establecimiento = valor.substring(10, 13);
      return _validarCedulaEcuatoriana(cedulaBase) && establecimiento == "001";
    }
    return false;
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await ApiService().registrarUsuario(
        nombre: _nombreCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        cedulaRuc: _cedulaCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario registrado con éxito. Inicie sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Pasajero')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    hintText: 'Ej. Juan Pérez',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                    if (v.trim().length < 3) return 'Mínimo 3 letras';
                    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(v.trim())) {
                      return 'Solo se permiten letras y espacios (sin números)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cedulaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cédula (10 dígitos) o RUC (13 dígitos)',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'La cédula o RUC es obligatorio';
                    if (!_validarCedulaORuc(v)) {
                      return 'Cédula o RUC ecuatoriano no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'El correo es obligatorio';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v.trim())) return 'Formato de correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.length < 3 ? 'Mínimo 3 caracteres' : null,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _cargando ? null : _registrar,
                  icon: _cargando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: Text(_cargando ? 'Validando datos...' : 'Crear Cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}