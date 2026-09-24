import 'package:flutter/material.dart';
import '../models/producto.dart';

class CantinaProvider extends ChangeNotifier {
  int _numeroTurno = 42;
  int get numeroTurno => _numeroTurno;

  final List<ItemCarrito> _carrito = [];
  List<ItemCarrito> get carrito => List.unmodifiable(_carrito);

  final List<Producto> _productos = [
    Producto(
      id: 1,
      nombre: 'Pizza Muzzarella',
      descripcion: 'Pizza artesanal a la piedra con abundante muzzarella.',
      precio: 3500,
      tag: 'Popular',
    ),
    Producto(
      id: 2,
      nombre: 'Empanadas J&Q',
      descripcion: 'Empanadas horneadas con queso derretido y jamón.',
      precio: 1200,
      tag: 'Clásico',
    ),
    Producto(
      id: 3,
      nombre: 'Tarta de Verduras',
      descripcion: 'Porción de tarta casera dorada al horno.',
      precio: 2200,
      tag: 'Saludable',
    ),
    Producto(
      id: 4,
      nombre: 'Pollo con Ensalada',
      descripcion: 'Suprema de pollo condimentada con hierbas finas.',
      precio: 3000,
      tag: 'Apto Celiacos',
      esSinTacc: true,
    ),
    Producto(
      id: 5,
      nombre: 'Ensalada Mixta',
      descripcion: 'Hojas verdes, tomate y aderezo especial.',
      precio: 2000,
      tag: 'Apto Celiacos',
      esSinTacc: true,
    ),
  ];

  List<Producto> get productos => _productos;
  List<Producto> get productosSinTacc => _productos.where((p) => p.esSinTacc).toList();

  double get totalCarrito => _carrito.fold(0, (sum, i) => sum + (i.producto.precio * i.cantidad));
  int get cantidadTotal => _carrito.fold(0, (sum, i) => sum + i.cantidad);

  void agregarAlCarrito(Producto producto) {
    final index = _carrito.indexWhere((i) => i.producto.id == producto.id);
    if (index >= 0) {
      _carrito[index].cantidad++;
    } else {
      _carrito.add(ItemCarrito(producto: producto));
    }
    notifyListeners();
  }

  void decrementarCantidad(Producto producto) {
    final index = _carrito.indexWhere((i) => i.producto.id == producto.id);
    if (index >= 0) {
      if (_carrito[index].cantidad > 1) {
        _carrito[index].cantidad--;
      } else {
        _carrito.removeAt(index);
      }
      notifyListeners();
    }
  }

  void confirmarPago() {
    _numeroTurno++;
    _carrito.clear();
    notifyListeners();
  }
}