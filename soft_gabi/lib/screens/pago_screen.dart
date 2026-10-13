import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/catalogo.dart';
import '../theme.dart';
import '../utils/formato.dart';

class _MetodoPago {
  final String id;
  final String icono;
  final String titulo;
  final Color color;

  const _MetodoPago(this.id, this.icono, this.titulo, this.color);
}

const _metodos = [
  _MetodoPago('transferencia', '🏦', 'Transferencia', AppColors.rojo),
  _MetodoPago('mercadopago', '💙', 'Mercado Pago', Color(0xFF009EE3)),
  _MetodoPago('tarjeta', '💳', 'Tarjeta', Color(0xFF1E293B)),
  _MetodoPago('efectivo', '💵', 'Efectivo', Color(0xFFD97706)),
];

/// Pantalla de pago. Al confirmar devuelve el id del método elegido
/// ('transferencia' | 'mercadopago' | 'tarjeta' | 'efectivo') con
/// Navigator.pop; si el usuario vuelve atrás devuelve null (no se registra nada).
///
/// NOTA: acá no hay ninguna pasarela real conectada (ni de tarjeta ni de
/// Mercado Pago): el "pago" se simula con un cartel de carga, igual que ya
/// pasaba con la transferencia. Para cobrar de verdad hace falta integrar
/// el SDK de Mercado Pago (o de la procesadora que uses) con sus propias
/// credenciales del lado del servidor.
class PagoScreen extends StatefulWidget {
  final int total;

  const PagoScreen({super.key, required this.total});

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  String _tipo = 'transferencia';
  bool _copiado = false;

  // ---- solo para la simulación del formulario de tarjeta ----
  final _formTarjeta = GlobalKey<FormState>();
  final _numeroTarjeta = TextEditingController();
  final _nombreTarjeta = TextEditingController();
  final _vencimiento = TextEditingController();
  final _cvv = TextEditingController();

  @override
  void dispose() {
    _numeroTarjeta.dispose();
    _nombreTarjeta.dispose();
    _vencimiento.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _copiarAlias() async {
    await Clipboard.setData(const ClipboardData(text: aliasPago));
    if (!mounted) return;
    setState(() => _copiado = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copiado = false);
  }

  void _confirmar() {
    if (_tipo == 'tarjeta' && !_formTarjeta.currentState!.validate()) return;
    // El pedido se guarda de verdad en Firebase recién en la pantalla
    // siguiente (carrito_screen.dart), que ya muestra su propio loading.
    Navigator.pop(context, _tipo);
  }

  String _textoBoton() => switch (_tipo) {
        'transferencia' => 'Ya transferí / Enviar pedido',
        'mercadopago' => 'Pagar con Mercado Pago',
        'tarjeta' => 'Pagar con tarjeta',
        _ => 'Confirmar pedido en efectivo',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('💳 Abonar Pedido')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Text('Total a pagar',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gris)),
                  Text(
                    pesos(widget.total),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.rojo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Elegí cómo pagar',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: [
                for (final m in _metodos) _TarjetaMetodo(
                  metodo: m,
                  seleccionado: _tipo == m.id,
                  onTap: () => setState(() => _tipo = m.id),
                ),
              ],
            ),
            const SizedBox(height: 16),
            switch (_tipo) {
              'transferencia' => _PanelTransferencia(
                  total: widget.total,
                  copiado: _copiado,
                  onCopiar: _copiarAlias,
                ),
              'mercadopago' => const _PanelMercadoPago(),
              'tarjeta' => _PanelTarjeta(
                  formKey: _formTarjeta,
                  numero: _numeroTarjeta,
                  nombre: _nombreTarjeta,
                  vencimiento: _vencimiento,
                  cvv: _cvv,
                ),
              _ => _PanelEfectivo(total: widget.total),
            },
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _confirmar,
              child: Text(_textoBoton()),
            ),
          ],
        ),
      );
  }
}

class _TarjetaMetodo extends StatelessWidget {
  final _MetodoPago metodo;
  final bool seleccionado;
  final VoidCallback? onTap;

  const _TarjetaMetodo({required this.metodo, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: seleccionado ? metodo.color.withValues(alpha: 0.10) : Colors.white,
          border: Border.all(
            color: seleccionado ? metodo.color : Colors.grey.shade300,
            width: seleccionado ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(metodo.icono, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                metodo.titulo,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (seleccionado) Icon(Icons.check_circle, color: metodo.color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PanelTransferencia extends StatelessWidget {
  final int total;
  final bool copiado;
  final VoidCallback onCopiar;

  const _PanelTransferencia({required this.total, required this.copiado, required this.onCopiar});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              QrImageView(
                data: 'Alias:$aliasPago Monto:$total',
                size: 180,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 6),
              const Text(
                'Escaneá desde Mercado Pago, Naranja X o tu banco',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gris),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALIAS MERCADO PAGO / CBU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gris,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(aliasPago, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.texto,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: onCopiar,
                child: Text(copiado ? '¡Copiado! ✓' : 'Copiar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelMercadoPago extends StatelessWidget {
  const _PanelMercadoPago();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9FF),
        border: Border.all(color: const Color(0xFFBEE7FD)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Text('💙', style: TextStyle(fontSize: 32)),
          SizedBox(height: 6),
          Text('Pagás con Mercado Pago',
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF00527A))),
          SizedBox(height: 4),
          Text(
            'Vas a poder elegir dinero en cuenta, tarjeta guardada o QR dentro de Mercado Pago. '
            'Al confirmar, simulamos la aprobación.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF00527A)),
          ),
        ],
      ),
    );
  }
}

class _PanelTarjeta extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController numero;
  final TextEditingController nombre;
  final TextEditingController vencimiento;
  final TextEditingController cvv;

  const _PanelTarjeta({
    required this.formKey,
    required this.numero,
    required this.nombre,
    required this.vencimiento,
    required this.cvv,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💳 Datos de la tarjeta',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 12),
            TextFormField(
              controller: numero,
              keyboardType: TextInputType.number,
              maxLength: 19,
              decoration: const InputDecoration(
                labelText: 'Número de tarjeta',
                counterText: '',
                hintText: '1234 5678 9012 3456',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _EspaciadorTarjeta(),
              ],
              validator: (v) {
                final limpio = (v ?? '').replaceAll(' ', '');
                if (limpio.length < 15) return 'Número inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nombre,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Nombre y apellido (como figura)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá el nombre' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: vencimiento,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: const InputDecoration(labelText: 'MM/AA', counterText: ''),
                    inputFormatters: [_FormateadorVencimiento()],
                    validator: (v) {
                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v ?? '')) return 'MM/AA';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: cvv,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'CVV', counterText: ''),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (v == null || v.length < 3) ? 'CVV inválido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '🔒 Estos datos no se envían a ningún servidor: esta pantalla es una demo.',
              style: TextStyle(fontSize: 11, color: AppColors.gris),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelEfectivo extends StatelessWidget {
  final int total;

  const _PanelEfectivo({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🏬', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 6),
          const Text('Pago en Mostrador',
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF78350F))),
          const SizedBox(height: 4),
          Text(
            'Abonás ${pesos(total)} en efectivo directamente al retirar tu pedido en la cantina.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
          ),
        ],
      ),
    );
  }
}

/// Agrupa el número de tarjeta de a 4 dígitos mientras se escribe: 1234 5678 ...
class _EspaciadorTarjeta extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitos = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digitos[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Formatea el vencimiento como MM/AA mientras se escribe.
class _FormateadorVencimiento extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digitos = newValue.text.replaceAll('/', '').replaceAll(RegExp(r'\D'), '');
    final recortado = digitos.length > 4 ? digitos.substring(0, 4) : digitos;
    final texto = recortado.length > 2
        ? '${recortado.substring(0, 2)}/${recortado.substring(2)}'
        : recortado;
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
