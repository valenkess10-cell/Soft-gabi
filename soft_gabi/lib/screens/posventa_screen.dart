import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';

/// Calificación del pedido. Queda guardada y la vendedora la ve en el Panel de Ventas.
class PosventaScreen extends StatefulWidget {
  final Pedido pedido;

  const PosventaScreen({super.key, required this.pedido});

  @override
  State<PosventaScreen> createState() => _PosventaScreenState();
}

class _PosventaScreenState extends State<PosventaScreen> {
  late int _calificacion = widget.pedido.calificacion ?? 0;
  late bool _enviado = widget.pedido.calificacion != null;
  bool _enviando = false;
  final _comentario = TextEditingController();

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      await CantinaScope.read(context)
          .calificarPedido(widget.pedido, _calificacion, _comentario.text);
      if (!mounted) return;
      setState(() {
        _enviado = true;
        _enviando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar. Revisá tu conexión e intentá de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atención Posventa')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Seguimiento del pedido ${turno(widget.pedido.numero)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Queremos saber tu opinión sobre el servicio recibido.',
            style: TextStyle(color: AppColors.gris),
          ),
          const SizedBox(height: 20),
          if (!_enviado) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  tooltip: '${i + 1} de 5',
                  onPressed: () => setState(() => _calificacion = i + 1),
                  icon: Icon(
                    i < _calificacion ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 38,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentario,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: (_calificacion == 0 || _enviando) ? null : _enviar,
              child: _enviando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Enviar calificación'),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.verdeClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '¡Gracias por tu opinión! Nos ayuda a mejorar el servicio.',
                style: TextStyle(color: AppColors.verde, fontWeight: FontWeight.w800),
              ),
            ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              '¿Algún problema con tu pedido? Acercate a la caja de la cantina '
              'con tu número de turno y te ayudamos.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
