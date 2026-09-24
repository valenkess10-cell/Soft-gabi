import 'package:flutter/material.dart';

class PosventaScreen extends StatefulWidget {
  final int numeroTurno;

  const PosventaScreen({super.key, required this.numeroTurno});

  @override
  State<PosventaScreen> createState() => _PosventaScreenState();
}

class _PosventaScreenState extends State<PosventaScreen> {
  int _calificacion = 0;
  bool _enviado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atención Posventa')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seguimiento del Pedido #${widget.numeroTurno}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Queremos saber tu opinión sobre el servicio recibido.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            if (!_enviado) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _calificacion ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () => setState(() => _calificacion = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                  onPressed: _calificacion == 0 ? null : () => setState(() => _enviado = true),
                  child: const Text('Enviar Calificación', style: TextStyle(color: Colors.white)),
                ),
              )
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.emerald.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Text('¡Gracias por tu opinión! Nos ayuda a mejorar el servicio.', style: TextStyle(color: Colors.emerald, fontWeight: FontWeight.bold)),
              )
          ],
        ),
      ),
    );
  }
}