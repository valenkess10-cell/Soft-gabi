import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/catalogo.dart';
import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';

/// Panel de productos: la vendedora y la cuenta master pueden agregar,
/// editar o eliminar cualquier producto del catálogo (incluidos los que
/// trae la app de fábrica), con nombre, precio y una foto opcional.
class ProductosAdminScreen extends StatelessWidget {
  const ProductosAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);

    if (!cantina.puedeVerVentas) {
      return const Scaffold(
        body: Center(child: Text('🔒 Acceso exclusivo para la vendedora')),
      );
    }

    final productos = [...cantina.todosLosProductos]
      ..sort((a, b) => a.categoriaLabel.compareTo(b.categoriaLabel));

    return Scaffold(
      appBar: AppBar(title: const Text('Mis productos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar producto'),
      ),
      body: productos.isEmpty
          ? const Center(
              child: Text('Todavía no hay productos cargados.',
                  style: TextStyle(color: AppColors.gris, fontWeight: FontWeight.w700)),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: productos.length,
              itemBuilder: (context, i) => _ProductoAdminTile(producto: productos[i]),
            ),
    );
  }

  static void _abrirFormulario(BuildContext context, {Producto? producto}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FormularioProducto(producto: producto),
    );
  }
}

class _ProductoAdminTile extends StatelessWidget {
  final Producto producto;

  const _ProductoAdminTile({required this.producto});

  Uint8List? get _bytesFoto =>
      producto.imagenBase64 != null ? base64Decode(producto.imagenBase64!) : null;

  Future<void> _confirmarEliminar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text('Se va a borrar "${producto.nombre}" para todo el mundo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    final error = await CantinaScope.read(context).eliminarProducto(producto);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? '${producto.nombre} eliminado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytesFoto;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : producto.imagen != null
                    ? Image.asset(producto.imagen!, fit: BoxFit.cover)
                    : ColoredBox(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: Text(producto.emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
          ),
        ),
        title: Text(producto.nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${producto.categoriaLabel} · ${pesos(producto.precio)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => ProductosAdminScreen._abrirFormulario(context, producto: producto),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline, color: AppColors.rojo),
              onPressed: () => _confirmarEliminar(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulario de alta/edición: nombre, precio, categoría y una foto opcional
/// (galería o cámara). Se usa tanto para productos nuevos como existentes.
class _FormularioProducto extends StatefulWidget {
  final Producto? producto; // null = alta de un producto nuevo

  const _FormularioProducto({this.producto});

  @override
  State<_FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<_FormularioProducto> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _descripcionCtrl;
  late String _categoriaId;

  Uint8List? _fotoNueva; // foto recién elegida, todavía no guardada
  bool _fotoBorrada = false; // la vendedora sacó la foto que había
  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _precioCtrl = TextEditingController(text: p != null ? p.precio.toString() : '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _categoriaId = p?.categoria ?? categorias.first.id;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto(ImageSource origen) async {
    try {
      final picker = ImagePicker();
      final archivo = await picker.pickImage(
        source: origen,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 70, // comprime para que entre cómodo en el documento
      );
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      setState(() {
        _fotoNueva = bytes;
        _fotoBorrada = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la cámara/galería.')),
      );
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _elegirFoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Sacar una foto'),
              onTap: () {
                Navigator.pop(context);
                _elegirFoto(ImageSource.camera);
              },
            ),
            if (_fotoNueva != null || (widget.producto?.imagenBase64 != null && !_fotoBorrada))
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.rojo),
                title: const Text('Sacar la foto'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _fotoNueva = null;
                    _fotoBorrada = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final cantina = CantinaScope.read(context);
    final nombre = _nombreCtrl.text;
    final precio = int.parse(_precioCtrl.text.trim());
    final descripcion = _descripcionCtrl.text;

    final String? error;
    if (_esEdicion) {
      error = await cantina.editarProducto(
        original: widget.producto!,
        nombre: nombre,
        precio: precio,
        categoriaId: _categoriaId,
        descripcion: descripcion,
        imagenBase64: _fotoNueva != null
            ? base64Encode(_fotoNueva!)
            : (_fotoBorrada ? null : sinCambioImagen),
      );
    } else {
      error = await cantina.agregarProducto(
        nombre: nombre,
        precio: precio,
        categoriaId: _categoriaId,
        descripcion: descripcion,
        imagenBase64: _fotoNueva != null ? base64Encode(_fotoNueva!) : null,
      );
    }

    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_esEdicion ? 'Producto actualizado' : 'Producto agregado')),
    );
  }

  Widget _vistaPreviaFoto() {
    if (_fotoNueva != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(_fotoNueva!, width: 90, height: 90, fit: BoxFit.cover),
      );
    }
    final existente = widget.producto;
    if (!_fotoBorrada && existente?.imagenBase64 != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(base64Decode(existente!.imagenBase64!),
            width: 90, height: 90, fit: BoxFit.cover),
      );
    }
    if (!_fotoBorrada && existente?.imagen != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(existente!.imagen!, width: 90, height: 90, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _esEdicion ? 'Editar producto' : 'Agregar producto',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _mostrarOpcionesFoto,
                    child: _vistaPreviaFoto(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _mostrarOpcionesFoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Elegir foto'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Poné un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precioCtrl,
                decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ '),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Poné un precio válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoriaId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  for (final c in categorias)
                    DropdownMenuItem(value: c.id, child: Text('${c.icono} ${c.nombre}')),
                ],
                onChanged: (v) => setState(() => _categoriaId = v ?? _categoriaId),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Si la dejás vacía, se usa el nombre',
                ),
                maxLines: 2,
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
                    : Text(_esEdicion ? 'Guardar cambios' : 'Agregar producto'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
