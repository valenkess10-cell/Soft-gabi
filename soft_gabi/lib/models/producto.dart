class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String tag;
  final bool esSinTacc;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.tag,
    this.esSinTacc = false,
  });
}

class ItemCarrito {
  final Producto producto;
  int cantidad;

  ItemCarrito({
    required this.producto,
    this.cantidad = 1,
  });
}