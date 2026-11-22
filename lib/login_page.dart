// lib/login_page.dart
// Pantalla de inicio de sesión y registro (RF01).
// Para crear una cuenta hay que marcar la casilla de aceptación de los Términos de uso
// y la Política de Privacidad; la API también lo exige y guarda qué versión se aceptó.
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'ciclista_page.dart' show AppColors;
import 'legal_content.dart';
import 'legal_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();

  bool _modoRegistro = false;
  bool _enviando = false;
  bool _verPassword = false;
  bool _aceptaTerminos = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _abrirLegal(String titulo, List<SeccionLegal> secciones) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalPage(titulo: titulo, secciones: secciones)),
    );
  }

  Future<void> _enviar() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final nombre = _nombreCtrl.text.trim();

    if (!email.contains('@')) {
      setState(() => _error = 'Ingresá un email válido');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (_modoRegistro && nombre.isEmpty) {
      setState(() => _error = 'Ingresá tu nombre');
      return;
    }
    if (_modoRegistro && !_aceptaTerminos) {
      setState(() => _error = 'Para crear la cuenta tenés que aceptar los Términos de uso y la Política de Privacidad.');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      if (_modoRegistro) {
        await ApiService.instance.registrarse(
          email: email,
          password: password,
          nombre: nombre,
          aceptoTerminos: _aceptaTerminos,
          versionTerminos: versionTerminos,
        );
      } else {
        await ApiService.instance.iniciarSesion(email, password);
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // En el registro, el botón queda bloqueado hasta aceptar los términos.
    final puedeEnviar = !_enviando && (!_modoRegistro || _aceptaTerminos);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pedal_bike, color: AppColors.accent, size: 56),
                  const SizedBox(height: 8),
                  const Text(
                    'Ciclista App',
                    style: TextStyle(color: AppColors.textOnDark, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Registrá tus recorridos y andá seguro',
                    style: TextStyle(color: AppColors.textOnDark.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _modoRegistro ? 'Crear cuenta' : 'Iniciar sesión',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnLight,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_modoRegistro) ...[
                            _campo(_nombreCtrl, 'Nombre', Icons.person_outline),
                            const SizedBox(height: 12),
                          ],
                          _campo(
                            _emailCtrl,
                            'Email',
                            Icons.mail_outline,
                            teclado: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _campo(
                            _passCtrl,
                            'Contraseña',
                            Icons.lock_outline,
                            oculto: !_verPassword,
                            sufijo: IconButton(
                              icon: Icon(
                                _verPassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.primary,
                              ),
                              onPressed: () => setState(() => _verPassword = !_verPassword),
                            ),
                          ),
                          if (_modoRegistro) ...[
                            const SizedBox(height: 8),
                            _casillaTerminos(),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: puedeEnviar ? _enviar : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.accent.withOpacity(0.35),
                              disabledForegroundColor: AppColors.primary.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _enviando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  )
                                : Text(
                                    _modoRegistro ? 'Crear cuenta' : 'Entrar',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _enviando
                                ? null
                                : () => setState(() {
                                      _modoRegistro = !_modoRegistro;
                                      _aceptaTerminos = false;
                                      _error = null;
                                    }),
                            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                            child: Text(
                              _modoRegistro
                                  ? '¿Ya tenés cuenta? Iniciá sesión'
                                  : '¿No tenés cuenta? Creá una',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Casilla "Acepto los Términos de uso y la Política de Privacidad", con enlaces a cada texto.
  Widget _casillaTerminos() {
    const estilo = TextStyle(fontSize: 14, color: AppColors.textOnLight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: _aceptaTerminos,
          onChanged: _enviando
              ? null
              : (valor) => setState(() {
                    _aceptaTerminos = valor ?? false;
                    _error = null;
                  }),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: AppColors.primary,
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Acepto los ', style: estilo),
              _enlace('Términos de uso', () => _abrirLegal('Términos de uso', terminosDeUso)),
              const Text(' y la ', style: estilo),
              _enlace(
                'Política de Privacidad',
                () => _abrirLegal('Política de privacidad', politicaDePrivacidad),
              ),
            ],
          ),
        ),
        if (!_aceptaTerminos)
          Text(
            'Necesitás aceptarlos para crear la cuenta.',
            style: TextStyle(fontSize: 12, color: AppColors.textOnLight.withOpacity(0.6)),
          ),
      ],
    );
  }

  Widget _enlace(String texto, VoidCallback alTocar) {
    return GestureDetector(
      onTap: alTocar,
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2F6DB5),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController controlador,
    String etiqueta,
    IconData icono, {
    bool oculto = false,
    TextInputType? teclado,
    Widget? sufijo,
  }) {
    return TextField(
      controller: controlador,
      obscureText: oculto,
      keyboardType: teclado,
      style: const TextStyle(color: AppColors.textOnLight),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: const TextStyle(color: AppColors.textOnLight),
        prefixIcon: Icon(icono, color: AppColors.primary),
        suffixIcon: sufijo,
        isDense: true,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}