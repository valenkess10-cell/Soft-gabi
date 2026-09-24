import 'package:flutter/material.dart';

class TicketScreen extends StatelessWidget {
  final int numeroTurno;
  final VoidCallback alIrAPosventa;

  const TicketScreen({
    super.key,
    required this.numeroTurno,
    required this.alIrAPosventa,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.emerald, size: 60),
            const SizedBox(height: 12),
            const Text('¡Pedido en Preparación!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Presentate en la cantina con este turno:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            Text(
              '#$numeroTurno',
              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.black, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: alIrAPosventa,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ver Posventa y Soporte', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}