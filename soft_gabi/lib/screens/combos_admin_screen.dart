import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';

/// La vendedora arma combos: elige 2 o más productos existentes y les pone
/// un precio especial. Se muestran a los clientes en Inicio y en el Menú.
class CombosAdminScreen extends StatelessWidget {
  const CombosAdminScreen({super.key});

  static void _abrirFormulario(BuildContext context, {Combo? combo}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FormularioCombo(combo: combo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);
    if (!cantina.puedeVerVentas) {
      return const Scaffold(body: Center(child: Text('🔒 Acceso exclusivo para la vendedora')));
    }
    final combos = cantina.todosLosCombos;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis combos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Armar combo'),
      ),
      body: combos.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no armaste ningún combo.\nTocá "Armar combo" para crear el primero.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.gris, fontWeight: FontWeight.w700),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: combos.length,
              itemBuilder: (context, i) => _ComboAdminTile(detalle: combos[i]),
            ),
    );
  }
}

class _ComboAdminTile extends StatelessWidget {
  final DetalleCombo detalle;

  const _ComboAdminTile({required this.detalle});

  Future<void> _confirmarEliminar(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar combo?'),
        content: Text('Se va a borrar "${detalle.combo.nombre}".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await CantinaScope.read(context).eliminarCombo(detalle.combo);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final combo = detalle.combo;
    final String? aviso = !combo.activo
        ? 'Pausado · oculto del menú'
        : !detalle.disponible
            ? 'Oculto: algún producto está agotado o se borró'
            : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            const Text('🍱', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${combo.nombre} · ${pesos(combo.precio)}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(detalle.descripcionItems.join(' + '),
                      style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                  if (aviso != null)
                    Text(aviso,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.rojo)),
                ],
              ),
            ),
            Switch(
              value: combo.activo,
              onChanged: (v) => CantinaScope.read(context).cambiarComboActivo(combo, v),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'editar') CombosAdminScreen._abrirFormulario(context, combo: combo);
                if (v == 'borrar') _confirmarEliminar(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'borrar', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormularioCombo extends StatefulWidget {
  final Combo? combo; // null = combo nuevo

  const _FormularioCombo({this.combo});

  @override
  State<_FormularioCombo> createState() => _FormularioComboState();
}

class _FormularioComboState extends State<_FormularioCombo> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _precio;
  late final List<ItemCombo> _items;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final c = widget.combo;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _descripcion = TextEditingController(text: c?.descripcion ?? '');
    _precio = TextEditingController(text: c != null ? '${c.precio}' : '');
    _items = [...?c?.items];
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _precio.dispose();
    super.dispose();
  }

  void _sumar(Producto p) {
    setState(() {
      final i = _items.indexWhere((it) => it.productoId == p.id);
      if (i >= 0) {
        _items[i] = ItemCombo(productoId: p.id, nombre: p.nombre, cantidad: _items[i].cantidad + 1);
      } else {
        _items.add(ItemCombo(productoId: p.id, nombre: p.nombre));
      }
    });
  }

  void _cambiarCantidad(int i, int delta) {
    setState(() {
      final it = _items[i];
      final nueva = it.cantidad + delta;
      if (nueva < 1) {
        _items.removeAt(i);
      } else {
        _items[i] = ItemCombo(productoId: it.productoId, nombre: it.nombre, cantidad: nueva);
      }
    });
  }

  Future<void> _elegirProducto(List<Producto> productos) async {
    final elegido = await showModalBottomSheet<Producto>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scroll) => ListView(
          controller: scroll,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Elegí un producto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
            for (final p in productos)
              ListTile(
                leading: Text(p.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(p.nombre),
                trailing: Text(pesos(p.precio)),
                onTap: () => Navigator.pop(sheetContext, p),
              ),
          ],
        ),
      ),
    );
    if (elegido != null) _sumar(elegido);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final error = await CantinaScope.read(context).guardarCombo(
      id: widget.combo?.id,
      nombre: _nombre.text,
      descripcion: _descripcion.text,
      precio: int.parse(_precio.text.trim()),
      items: _items,
      activo: widget.combo?.activo ?? true,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final productos = [...CantinaScope.of(context).todosLosProductos]
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    final precioNormal = _items.fold<int>(0, (s, it) {
      final p = productos.where((x) => x.id == it.productoId);
      return s + (p.isEmpty ? 0 : p.first.precio) * it.cantidad;
    });
    final precioCombo = int.tryParse(_precio.text.trim()) ?? 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.combo == null ? 'Armar combo' : 'Editar combo',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre del combo'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ponele un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcion,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: 16),
              const Text('Productos del combo',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              for (var i = 0; i < _items.length; i++)
                Row(
                  children: [
                    Expanded(child: Text(_items[i].nombre)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _cambiarCantidad(i, -1),
                      icon: Icon(_items[i].cantidad == 1
                          ? Icons.delete_outline
                          : Icons.remove_circle_outline),
                    ),
                    Text('${_items[i].cantidad}',
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _cambiarCantidad(i, 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _elegirProducto(productos),
                  icon: const Icon(Icons.add),
                  label: const Text('Sumar producto'),
                ),
              ),
              if (_items.isNotEmpty)
                Text('Por separado salen ${pesos(precioNormal)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.gris)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precio,
                decoration: const InputDecoration(labelText: 'Precio del combo', prefixText: '\$ '),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Poné un precio válido';
                  return null;
                },
              ),
              if (precioCombo > 0 && precioNormal > precioCombo)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('El cliente ahorra ${pesos(precioNormal - precioCombo)}',
                      style: const TextStyle(
                          color: AppColors.verde, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.combo == null ? 'Crear combo' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
