import 'package:flutter/material.dart';

import 'api_service.dart';
import 'ciclista_page.dart' show AppColors;

class _Plan {
  final String id;
  final String nombre;
  final String precio;
  final String detalle;
  final String? ahorro;

  const _Plan({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.detalle,
    this.ahorro,
  });
}

const List<_Plan> _planes = [
  _Plan(id: 'mensual', nombre: 'Mensual', precio: 'US\$ 4,99', detalle: 'por mes'),
  _Plan(id: 'anual', nombre: 'Anual', precio: 'US\$ 39,99', detalle: 'por año', ahorro: 'Ahorrás 33%'),
];

// Cada fila: (beneficio, qué da el plan gratis, qué da el premium).
// true = incluido, false = bloqueado, texto = limitación o ventaja.
const List<(String, Object, Object)> _beneficios = [
  ('Registrar recorridos con GPS', true, true),
  ('Mapa y ruta en vivo', true, true),
  ('Historial de recorridos', 'Últimos 5', 'Ilimitado'),
  ('Estadísticas avanzadas', false, true),
  ('Publicidad', 'Con anuncios', 'Sin anuncios'),
];

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  static const double _anchoColumna = 84;

  String _seleccionado = 'anual';
  bool _cargando = true;
  bool _esPremium = false;
  bool _cancelando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPlan();
  }

  Future<void> _cargarPlan() async {
    try {
      final perfil = await ApiService.instance.obtenerPerfil();
      if (!mounted) return;
      setState(() {
        _esPremium = perfil.esPremium;
        _cargando = false;
      });
    } on SesionExpirada {
      _irALogin();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _cargando = false;
        });
      }
    }
  }

  void _irALogin() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  }

  // --------------------------------------------------------------------------
  // Pago (simulado) y cancelación
  // --------------------------------------------------------------------------
  Future<void> _pagar() async {
    final plan = _planes.firstWhere((p) => p.id == _seleccionado);
    final pagado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutSheet(plan: plan),
    );
    if (pagado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Listo! Ya sos Premium')),
      );
      Navigator.of(context).pop(true); // la pantalla anterior se actualiza al recibir "true"
    }
  }

  Future<void> _cancelar() async {
    setState(() {
      _cancelando = true;
      _error = null;
    });
    try {
      await ApiService.instance.cancelarPremium();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Volviste al plan gratis')),
      );
      Navigator.of(context).pop(true);
    } on SesionExpirada {
      _irALogin();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _cancelando = false;
        });
      }
    }
  }

  // --------------------------------------------------------------------------
  // Pantalla
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        title: const Text('Syklist Premium', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  _encabezado(),
                  const SizedBox(height: 24),
                  _tablaComparativa(),
                  const SizedBox(height: 24),
                  ...(_esPremium ? _bloquePremium() : _bloqueCompra()),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _encabezado() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          child: const Icon(Icons.workspace_premium, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          _esPremium ? 'Ya sos Premium' : 'Pedaleá sin límites',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textOnLight),
        ),
        const SizedBox(height: 6),
        Text(
          _esPremium
              ? 'Gracias por apoyar Syklist.'
              : 'Tu plan actual es Gratis. Elegí un plan y desbloqueá todo.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textOnLight.withOpacity(0.7)),
        ),
      ],
    );
  }

  // --- Tabla Gratis vs Premium ---------------------------------------------
  Widget _tablaComparativa() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5DDF2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: _anchoColumna,
                  child: Center(
                    child: Text(
                      'GRATIS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.textOnLight.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _anchoColumna,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < _beneficios.length; i++) ...[
            _filaBeneficio(_beneficios[i].$1, _beneficios[i].$2, _beneficios[i].$3),
            if (i < _beneficios.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _filaBeneficio(String texto, Object gratis, Object premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 15, color: AppColors.textOnLight),
            ),
          ),
          SizedBox(width: _anchoColumna, child: Center(child: _celda(gratis))),
          SizedBox(width: _anchoColumna, child: Center(child: _celda(premium, destacada: true))),
        ],
      ),
    );
  }

  Widget _celda(Object valor, {bool destacada = false}) {
    if (valor is String) {
      return Text(
        valor,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: destacada ? FontWeight.w800 : FontWeight.w500,
          color: AppColors.textOnLight,
        ),
      );
    }
    if (valor == true) {
      return const Icon(Icons.check_circle, color: Color(0xFF2E9E5B), size: 22);
    }
    return Icon(Icons.lock_outline, color: AppColors.textOnLight.withOpacity(0.4), size: 22);
  }

  // --- Elegir plan y pagar -------------------------------------------------
  List<Widget> _bloqueCompra() {
    final plan = _planes.firstWhere((p) => p.id == _seleccionado);
    return [
      const Text(
        'Elegí tu plan',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textOnLight),
      ),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tarjetaPlan(_planes[0]),
            const SizedBox(width: 12),
            _tarjetaPlan(_planes[1]),
          ],
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _pagar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: const Icon(Icons.lock_open),
          label: Text(
            'Suscribirme · ${plan.precio}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Pago simulado: no se cobra nada. Podés volver al plan gratis cuando quieras.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: AppColors.textOnLight.withOpacity(0.6)),
      ),
    ];
  }

  Widget _tarjetaPlan(_Plan plan) {
    final activo = plan.id == _seleccionado;
    final colorTexto = activo ? AppColors.textOnDark : AppColors.textOnLight;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _seleccionado = plan.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: activo ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activo ? AppColors.accent : const Color(0xFFD5DDF2),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.nombre,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorTexto),
              ),
              const SizedBox(height: 6),
              Text(
                plan.precio,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorTexto),
              ),
              Text(
                plan.detalle,
                style: TextStyle(fontSize: 12, color: colorTexto.withOpacity(0.7)),
              ),
              if (plan.ahorro != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    plan.ahorro!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Ya es premium -------------------------------------------------------
  List<Widget> _bloquePremium() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.accent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tenés todo desbloqueado: historial ilimitado, estadísticas avanzadas y sin anuncios.',
                style: TextStyle(fontSize: 15, color: AppColors.textOnDark),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _cancelando ? null : _cancelar,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _cancelando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : const Text('Volver al plan gratis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    ];
  }
}

// ============================================================================
// Hoja de pago (simulada)
// ============================================================================
class _CheckoutSheet extends StatefulWidget {
  final _Plan plan;

  const _CheckoutSheet({required this.plan});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  static const List<String> _metodos = ['Tarjeta', 'Billetera digital'];

  int _metodo = 0;
  bool _procesando = false;
  String? _error;

  Future<void> _confirmar() async {
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      await Future<void>.delayed(const Duration(seconds: 2)); // simula el cobro
      await ApiService.instance.activarPremium(widget.plan.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on SesionExpirada {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _procesando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirmar pago',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textOnLight),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Syklist Premium',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textOnDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plan ${plan.nombre}',
                          style: TextStyle(fontSize: 13, color: AppColors.textOnDark.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    plan.precio,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Método de pago',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textOnLight),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < _metodos.length; i++)
                  ChoiceChip(
                    label: Text(_metodos[i]),
                    labelStyle: const TextStyle(color: AppColors.textOnLight),
                    selected: _metodo == i,
                    selectedColor: AppColors.accent,
                    checkmarkColor: AppColors.primary,
                    onSelected: _procesando ? null : (_) => setState(() => _metodo = i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Simulación: no se cobra nada ni se guardan datos de pago.',
              style: TextStyle(fontSize: 12, color: AppColors.textOnLight.withOpacity(0.6)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _procesando ? null : _confirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _procesando
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        SizedBox(width: 12),
                        Text('Procesando pago...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Text(
                      'Pagar ${plan.precio}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}