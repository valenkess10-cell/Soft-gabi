import 'package:flutter/material.dart';

import '../providers/cantina_scope.dart';
import '../theme.dart';

/// Login / registro (se muestra como bottom sheet).
class AuthScreen extends StatefulWidget {
  final bool registro;

  const AuthScreen({super.key, this.registro = false});

  static Future<void> mostrar(BuildContext context, {bool registro = false}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AuthScreen(registro: registro),
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  late bool _esLogin = !widget.registro;
  bool _verPassword = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate() || _cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    final cantina = CantinaScope.read(context);
    final error = _esLogin
        ? await cantina.iniciarSesion(email: _email.text, password: _password.text)
        : await cantina.registrar(
            nombre: _nombre.text,
            email: _email.text,
            password: _password.text,
          );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _error = error;
        _cargando = false;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sube el formulario cuando aparece el teclado.
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _esLogin ? 'Iniciá sesión' : 'Creá tu cuenta',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                _esLogin
                    ? 'Ingresá a tu cuenta de MiCantina'
                    : 'Registrate para hacer pedidos más rápido',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.gris),
              ),
              const SizedBox(height: 18),
              if (!_esLogin) ...[
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresá tu nombre' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (v) {
                  final mail = v?.trim() ?? '';
                  if (mail.isEmpty) return 'Ingresá tu email';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
                    return 'El email no es válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: !_verPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _verPassword = !_verPassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresá tu contraseña';
                  if (!_esLogin && v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
                onFieldSubmitted: (_) => _enviar(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.rojo,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _cargando ? null : _enviar,
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_esLogin ? 'Entrar' : 'Registrarme'),
              ),
              TextButton(
                onPressed: _cargando
                    ? null
                    : () => setState(() {
                          _esLogin = !_esLogin;
                          _error = null;
                        }),
                child: Text(
                  _esLogin
                      ? '¿No tenés cuenta? Registrate acá'
                      : '¿Ya tenés cuenta? Iniciá sesión',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
