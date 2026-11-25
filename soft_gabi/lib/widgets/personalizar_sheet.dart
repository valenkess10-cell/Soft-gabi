import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';

/// Abre la hoja para elegir extras y escribir una aclaración. Devuelve true
/// si el cliente agregó el producto al carrito.
Future<bool?> mostrarPersonalizar(BuildContext context, Producto producto) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PersonalizarSheet(producto: producto),
  );
}

class _PersonalizarSheet extends StatefulWidget {
  final Producto producto;

  const _PersonalizarSheet({required this.producto});

  @override
  State<_PersonalizarSheet> createState() => _PersonalizarSheetState();
}

class _PersonalizarSheetState extends State<_PersonalizarSheet> {
  final Set<String> _elegidas = {};
  final _nota = TextEditingController();

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  List<OpcionProducto> get _opcionesElegidas =>
      widget.producto.opciones.where((o) => _elegidas.contains(o.id)).toList();

  int get _precio =>
      widget.producto.precio + _opcionesElegidas.fold<int>(0, (s, o) => s + o.precio);

  void _agregar() {
    CantinaScope.read(context).agregarAlCarrito(
      widget.producto,
      opciones: _opcionesElegidas,
      nota: _nota.text,
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(p.descripcion, style: const TextStyle(fontSize: 13, color: AppColors.gris)),
            if (p.calorias != null) ...[
              const SizedBox(height: 6),
              Text('🔥 ${p.calorias} kcal',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFC2410C), fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 16),
            const Text('PERSONALIZALO',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gris,
                    letterSpacing: 0.6)),
            const SizedBox(height: 6),
            for (final o in p.opciones)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _elegidas.contains(o.id),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _elegidas.add(o.id);
                  } else {
                    _elegidas.remove(o.id);
                  }
                }),
                title: Text(o.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                secondary: Text(
                  o.precio > 0 ? '+${pesos(o.precio)}' : 'Gratis',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: o.precio > 0 ? AppColors.texto : AppColors.gris,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _nota,
              maxLength: 140,
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Aclaración para la cocina (opcional)',
                hintText: 'Ej: sin mayonesa, bien cocida…',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _agregar,
              icon: const Icon(Icons.add),
              label: Text('Agregar · ${pesos(_precio)}'),
            ),
          ],
        ),
      ),
    );
  }
}
