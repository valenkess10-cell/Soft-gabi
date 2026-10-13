import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/producto.dart';
import '../theme.dart';
import '../utils/formato.dart';
import 'posventa_screen.dart';

/// Ticket que ve el cliente al confirmar (se muestra como diálogo).
class TicketScreen extends StatelessWidget {
  final Pedido pedido;

  const TicketScreen({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final efectivo = pedido.metodoPago == 'efectivo';
    final textoTotal = efectivo
        ? 'Total a pagar al retirar: ${pesos(pedido.total)}'
        : 'Total abonado con ${pedido.metodoPagoLabel}: ${pesos(pedido.total)}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.verdeClaro,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.verde, size: 32),
            ),
            const SizedBox(height: 12),
            const Text('¡Pedido Confirmado!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text(
              'Mostrá este ticket en la caja de retiro de la cantina',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.gris),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.texto,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'TU NÚMERO DE TURNO',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    turno(pedido.numero),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: 'MICANTINA-${pedido.id}-${pedido.numero}',
              size: 130,
              backgroundColor: Colors.white,
            ),
            Text(
              'ID: CT-${pedido.fecha.year}-${pedido.numero}',
              style: const TextStyle(fontSize: 10, color: AppColors.gris),
            ),
            const SizedBox(height: 12),
            Text(
              textoTotal,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.texto),
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido / Hacer otro pedido'),
              ),
            ),
            TextButton(
              onPressed: () {
                // Guardamos el navigator antes de cerrar el diálogo.
                final nav = Navigator.of(context);
                nav.pop();
                nav.push(MaterialPageRoute(builder: (_) => PosventaScreen(pedido: pedido)));
              },
              child: const Text('Ver Posventa y Soporte'),
            ),
          ],
        ),
      ),
    );
  }
}
