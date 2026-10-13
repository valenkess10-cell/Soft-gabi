import 'dart:convert';

import 'package:flutter/material.dart';

import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';
import 'pago_screen.dart';
import 'ticket_screen.dart';

/// Flujo completo del pedido: carrito -> pago -> ticket.
/// Se llama con un contexto que está DENTRO del MaterialApp (ej: el de HomeScreen).
Future<void> abrirCarrito(BuildContext context) async {
  final irAPagar = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const CarritoScreen(),
  );
  if (irAPagar != true || !context.mounted) return;

  final cantina = CantinaScope.read(context);
  final metodo = await Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => PagoScreen(total: cantina.totalCarrito)),
  );
  if (metodo == null || !context.mounted) return;

  // Pantalla de carga mientras se guarda el pedido de verdad en Firebase.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final pedido = await cantina.confirmarPago(metodo);
    if (!context.mounted) return;
    Navigator.pop(context); // cierra el loading
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TicketScreen(pedido: pedido),
    );
  } catch (_) {
    if (!context.mounted) return;
    Navigator.pop(context); // cierra el loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo enviar el pedido. Revisá tu conexión e intentá de nuevo.'),
      ),
    );
  }
}

/// Contenido del carrito (se muestra como bottom sheet).
class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);
    final items = cantina.carrito;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🛒 Tu Pedido',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Text('🧺', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 8),
                    Text('El carrito está vacío',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('Elegí productos del menú para ir sumándolos.',
                        style: TextStyle(color: AppColors.gris, fontSize: 12)),
                  ],
                ),
              ),
            )
          else ...[
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: item.producto.imagenBase64 != null
                              ? Image.memory(
                                  base64Decode(item.producto.imagenBase64!),
                                  fit: BoxFit.cover,
                                )
                              : item.producto.imagen != null
                                  ? Image.asset(
                                      item.producto.imagen!,
                                      fit: BoxFit.cover,
                                      cacheWidth: 150,
                                    )
                                  : ColoredBox(
                                      color: Colors.grey.shade100,
                                      child: Center(
                                        child: Text(item.producto.emoji,
                                            style: const TextStyle(fontSize: 24)),
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.producto.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            Text(
                              pesos(item.subtotal),
                              style: const TextStyle(
                                color: AppColors.rojo,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: item.cantidad == 1 ? 'Quitar' : 'Restar uno',
                        onPressed: () => cantina.decrementarCantidad(item.producto),
                        icon: Icon(
                          item.cantidad == 1
                              ? Icons.delete_outline
                              : Icons.remove_circle_outline,
                        ),
                      ),
                      Text('${item.cantidad}',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Sumar uno',
                        onPressed: () => cantina.agregarAlCarrito(item.producto),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(
                  pesos(cantina.totalCarrito),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.rojo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar pedido  ➔'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
