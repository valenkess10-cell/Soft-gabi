import 'package:flutter/material.dart';
import '../providers/cantina_provider.dart';

class CarritoScreen extends StatelessWidget {
  final CantinaProvider provider;
  final VoidCallback alConfirmarPago;

  const CarritoScreen({
    super.key,
    required this.provider,
    required this.alConfirmarPago,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🛒 Tu Pedido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          if (provider.carrito.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('El carrito está vacío.')),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.carrito.length,
                itemBuilder: (context, index) {
                  final item = provider.carrito[index];
                  return ListTile(
                    title: Text(item.producto.nombre),
                    subtitle: Text('x${item.cantidad}'),
                    trailing: Text('\$${(item.producto.precio * item.cantidad).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('\$${provider.totalCarrito.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.black, color: Color(0xFFDC2626))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: provider.carrito.isEmpty ? null : alConfirmarPago,
              child: const Text('Abonar y Confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}