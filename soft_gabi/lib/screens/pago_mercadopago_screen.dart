import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';

/// Abre el link de pago de Mercado Pago y espera, mirando el pedido en
/// Firestore, a que el servidor confirme el pago. Cuando se acredita hace
/// pop con el pedido actualizado; si el cliente vuelve atrás, devuelve null
/// (el pedido queda guardado como "pago pendiente").
class PagoMercadoPagoScreen extends StatefulWidget {
  final Pedido pedido;

  const PagoMercadoPagoScreen({super.key, required this.pedido});

  @override
  State<PagoMercadoPagoScreen> createState() => _PagoMercadoPagoScreenState();
}

class _PagoMercadoPagoScreenState extends State<PagoMercadoPagoScreen> {
  StreamSubscription<Pedido?>? _sub;
  late Pedido _pedido = widget.pedido;
  bool _abriendo = false;
  bool _cerrado = false; // evita cerrar dos veces si llegan dos avisos seguidos
  String? _error;

  @override
  void initState() {
    super.initState();
    final cantina = CantinaScope.read(context);
    _sub = cantina.escucharPedido(widget.pedido.id).listen((actual) {
      if (actual == null || !mounted) return;
      setState(() => _pedido = actual);
      if (actual.pagoAprobado && !_cerrado) {
        _cerrado = true;
        Navigator.pop(context, actual);
      }
    }, onError: (_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirMercadoPago());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _abrirMercadoPago() async {
    setState(() {
      _abriendo = true;
      _error = null;
    });
    try {
      final url = await CantinaScope.read(context).crearPagoMercadoPago(widget.pedido.id);
      final abierto = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!abierto) throw StateError('No se pudo abrir el link');
    } on FirebaseFunctionsException catch (e) {
      _error = e.message ?? 'No se pudo abrir Mercado Pago. Probá de nuevo.';
    } catch (_) {
      _error = 'No se pudo abrir Mercado Pago. Probá de nuevo.';
    }
    if (mounted) setState(() => _abriendo = false);
  }

  @override
  Widget build(BuildContext context) {
    final rechazado = _pedido.estadoPago == 'rechazado';
    return Scaffold(
      appBar: AppBar(title: const Text('Pago con Mercado Pago')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          Center(
            child: _abriendo || (!rechazado && _error == null)
                ? const SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(color: Color(0xFF009EE3)),
                  )
                : Icon(Icons.error_outline, size: 56, color: AppColors.rojo.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 20),
          Text(
            rechazado
                ? 'El pago no se completó'
                : _error != null
                    ? 'No pudimos abrir Mercado Pago'
                    : 'Esperando la confirmación del pago…',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            _error ??
                (rechazado
                    ? 'Mercado Pago rechazó o canceló el pago. Podés intentarlo de nuevo.'
                    : 'Pagá en Mercado Pago y volvé a esta pantalla: se actualiza sola cuando se acredita.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.gris),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pedido ${turno(_pedido.numero)}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(pesos(_pedido.total),
                    style: const TextStyle(
                        color: AppColors.rojo, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF009EE3)),
            onPressed: _abriendo ? null : _abrirMercadoPago,
            icon: const Icon(Icons.open_in_new),
            label: Text(rechazado || _error != null ? 'Intentar de nuevo' : 'Abrir Mercado Pago otra vez'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Pagar más tarde'),
          ),
        ],
      ),
    );
  }
}
