import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';
import 'pago_mercadopago_screen.dart';
import 'pago_screen.dart';
import 'ticket_screen.dart';

/// Flujo completo del pedido: carrito -> pago -> (Mercado Pago) -> ticket.
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
  final resultado = await Navigator.of(context).push<ResultadoPago>(
    MaterialPageRoute(builder: (_) => PagoScreen(total: cantina.totalCarrito)),
  );
  if (resultado == null || !context.mounted) return;

  // Pantalla de carga mientras se guarda el pedido de verdad en Firebase.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  Pedido pedido;
  try {
    pedido = await cantina.confirmarPago(
      resultado.metodo,
      horaRetiro: resultado.horaRetiro,
      pagaCon: resultado.pagaCon,
    );
  } catch (_) {
    if (!context.mounted) return;
    Navigator.pop(context); // cierra el loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo enviar el pedido. Revisá tu conexión e intentá de nuevo.'),
      ),
    );
    return;
  }
  if (!context.mounted) return;
  Navigator.pop(context); // cierra el loading

  // Mercado Pago: se abre el link de pago y se espera la confirmación.
  if (pedido.esMercadoPago) {
    final pagado = await Navigator.of(context).push<Pedido>(
      MaterialPageRoute(builder: (_) => PagoMercadoPagoScreen(pedido: pedido)),
    );
    if (!context.mounted) return;
    if (pagado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tu pedido ${turno(pedido.numero)} quedó guardado, pero el pago todavía no se acreditó.',
          ),
        ),
      );
      return;
    }
    pedido = pagado;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TicketScreen(pedido: pedido),
  );
}

/// Contenido del carrito (se muestra como bottom sheet).
class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  Future<void> _editarNota(BuildContext context, ItemCarrito item) async {
    final ctrl = TextEditingController(text: item.nota);
    final nueva = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Aclaración · ${item.nombre}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 140,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej: sin mayonesa, bien cocida…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (nueva != null && context.mounted) {
      CantinaScope.read(context).cambiarNota(item, nueva);
    }
  }

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
                separatorBuilder: (_, _) => const Divider(height: 18),
                itemBuilder: (context, i) => _LineaCarrito(
                  item: items[i],
                  onEditarNota: () => _editarNota(context, items[i]),
                ),
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

class _LineaCarrito extends StatelessWidget {
  final ItemCarrito item;
  final VoidCallback onEditarNota;

  const _LineaCarrito({required this.item, required this.onEditarNota});

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.read(context);
    final foto = item.bytesFoto;
    final respaldo = ColoredBox(
      color: Colors.grey.shade100,
      child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 24))),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: foto != null
                ? Image.memory(foto, fit: BoxFit.cover, errorBuilder: (_, _, _) => respaldo)
                : item.imagenAsset != null
                    ? Image.asset(item.imagenAsset!, fit: BoxFit.cover, cacheWidth: 150)
                    : respaldo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.esCombo ? '🍱 ${item.nombre}' : item.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              if (item.detalle.isNotEmpty)
                Text(item.detalle.join(' · '),
                    style: const TextStyle(fontSize: 11, color: AppColors.gris)),
              for (final o in item.opciones)
                Text(
                  o.precio > 0 ? '+ ${o.nombre} (${pesos(o.precio)})' : '+ ${o.nombre}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              if (item.nota.isNotEmpty)
                Text('“${item.nota}”',
                    style: const TextStyle(
                        fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFB45309))),
              Text(
                pesos(item.subtotal),
                style: const TextStyle(color: AppColors.rojo, fontWeight: FontWeight.w900),
              ),
              if (!item.esCombo)
                InkWell(
                  onTap: onEditarNota,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      item.nota.isEmpty ? '✏️ Agregar aclaración' : '✏️ Cambiar aclaración',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gris),
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: item.cantidad == 1 ? 'Quitar' : 'Restar uno',
          onPressed: () => cantina.decrementarCantidad(item),
          icon: Icon(item.cantidad == 1 ? Icons.delete_outline : Icons.remove_circle_outline),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text('${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Sumar uno',
          onPressed: () => cantina.sumarCantidad(item),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
