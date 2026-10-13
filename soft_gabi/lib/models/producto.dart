import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Categoria {
  final String id;
  final String nombre;
  final String icono;
  final Color color;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.color,
  });
}

class Producto {
  /// ID del documento en la colección `productos` de Firestore. Los
  /// productos originales del catálogo usan IDs fijos ('1', '2', ...) para
  /// poder "sembrarlos" en Firestore la primera vez sin duplicarlos; los que
  /// agrega la vendedora desde la app reciben un ID generado por Firestore.
  final String id;
  final String nombre;
  final String descripcion;
  final int precio;

  /// Foto real del producto (assets/images/...). Puede faltar: para los
  /// productos de kiosco (golosinas, gaseosas de marca) no usamos fotos de
  /// las marcas, así que en su lugar se muestra [emoji] como ícono.
  final String? imagen;

  /// Foto que subió la vendedora al crear/editar el producto desde la app,
  /// guardada como JPEG en base64 directamente en el documento de Firestore
  /// (así no hace falta configurar Firebase Storage aparte). Si está
  /// presente, tiene prioridad sobre [imagen] y [emoji] al mostrar la foto.
  final String? imagenBase64;

  final String emoji;

  final String tag;
  final int tiempo; // minutos de preparación
  final String categoria;
  final String categoriaLabel;
  final bool destacado;
  final bool esSinTacc;

  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.imagen,
    this.imagenBase64,
    this.emoji = '🍽️',
    required this.tag,
    required this.tiempo,
    required this.categoria,
    required this.categoriaLabel,
    this.destacado = false,
    this.esSinTacc = false,
  });

  /// Categorías que son kiosco (golosinas, gaseosas): se compran y se llevan
  /// al toque, no se "preparan", así que no tiene sentido mostrarles un
  /// tiempo de preparación (a diferencia de la comida del almuerzo, que sí
  /// se cocina al pedido).
  static const _categoriasDeKiosco = {'desayuno', 'bebidas'};
  bool get esComidaDeAlmuerzo => !_categoriasDeKiosco.contains(categoria);

  Producto copyWith({
    String? nombre,
    String? descripcion,
    int? precio,
    String? categoria,
    String? categoriaLabel,
    Object? imagenBase64 = sinCambioImagen,
  }) {
    return Producto(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      imagen: identical(imagenBase64, sinCambioImagen) ? imagen : null,
      imagenBase64:
          identical(imagenBase64, sinCambioImagen) ? this.imagenBase64 : imagenBase64 as String?,
      emoji: emoji,
      tag: tag,
      tiempo: tiempo,
      categoria: categoria ?? this.categoria,
      categoriaLabel: categoriaLabel ?? this.categoriaLabel,
      destacado: destacado,
      esSinTacc: esSinTacc,
    );
  }

  /// Campos para guardar en Firestore (sin el id: ese lo pone el documento).
  Map<String, dynamic> aCampos() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'imagen': imagen,
        'imagenBase64': imagenBase64,
        'emoji': emoji,
        'tag': tag,
        'tiempo': tiempo,
        'categoria': categoria,
        'categoriaLabel': categoriaLabel,
        'destacado': destacado,
        'esSinTacc': esSinTacc,
      };

  factory Producto.deDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    return Producto(
      id: doc.id,
      nombre: j['nombre'] as String,
      descripcion: j['descripcion'] as String? ?? '',
      precio: j['precio'] as int,
      imagen: j['imagen'] as String?,
      imagenBase64: j['imagenBase64'] as String?,
      emoji: j['emoji'] as String? ?? '🍽️',
      tag: j['tag'] as String? ?? '',
      tiempo: j['tiempo'] as int? ?? 5,
      categoria: j['categoria'] as String,
      categoriaLabel: j['categoriaLabel'] as String? ?? '',
      destacado: j['destacado'] as bool? ?? false,
      esSinTacc: j['esSinTacc'] as bool? ?? false,
    );
  }
}

/// Valor "centinela" para que copyWith pueda distinguir entre "no me pasaron
/// imagenBase64" (dejar la que había) y "me pasaron null a propósito"
/// (borrar la foto subida y volver a imagen/emoji). Pública porque también
/// la usa CantinaProvider.editarProducto con el mismo propósito.
const Object sinCambioImagen = Object();

class ItemCarrito {
  final Producto producto;
  int cantidad;

  ItemCarrito({required this.producto, this.cantidad = 1});

  int get subtotal => producto.precio * cantidad;
}

class ItemPedido {
  final String nombre;
  final int cantidad;

  const ItemPedido({required this.nombre, required this.cantidad});

  Map<String, dynamic> aCampos() => {'nombre': nombre, 'cantidad': cantidad};

  factory ItemPedido.deCampos(Map<String, dynamic> j) =>
      ItemPedido(nombre: j['nombre'] as String, cantidad: j['cantidad'] as int);
}

class Pedido {
  /// ID del documento en la colección `pedidos` de Firestore.
  final String id;
  final int numero; // número de turno que ve el cliente
  final DateTime fecha;
  final String cliente;
  final String? uid; // dueño del pedido en Firebase Auth (null = invitado)
  final List<ItemPedido> items;
  final int total;
  final String metodoPago; // 'transferencia' | 'mercadopago' | 'tarjeta' | 'efectivo'
  int? calificacion;
  String? comentario;

  Pedido({
    required this.id,
    required this.numero,
    required this.fecha,
    required this.cliente,
    required this.uid,
    required this.items,
    required this.total,
    required this.metodoPago,
    this.calificacion,
    this.comentario,
  });

  String get metodoPagoLabel => switch (metodoPago) {
        'transferencia' => 'Transferencia bancaria',
        'mercadopago' => 'Mercado Pago',
        'tarjeta' => 'Tarjeta de crédito/débito',
        _ => 'Efectivo en caja',
      };

  /// Campos para guardar en Firestore (sin el id: ese lo pone el documento).
  Map<String, dynamic> aCampos() => {
        'numero': numero,
        'fecha': Timestamp.fromDate(fecha),
        'cliente': cliente,
        'uid': uid,
        'items': items.map((i) => i.aCampos()).toList(),
        'total': total,
        'metodoPago': metodoPago,
        'calificacion': calificacion,
        'comentario': comentario,
      };

  factory Pedido.deDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    return Pedido(
      id: doc.id,
      numero: j['numero'] as int,
      fecha: (j['fecha'] as Timestamp).toDate(),
      cliente: j['cliente'] as String,
      uid: j['uid'] as String?,
      items: (j['items'] as List)
          .map((e) => ItemPedido.deCampos(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: j['total'] as int,
      metodoPago: j['metodoPago'] as String,
      calificacion: j['calificacion'] as int?,
      comentario: j['comentario'] as String?,
    );
  }
}

class Usuario {
  final String uid;
  final String nombre;
  final String email;
  final String rol; // 'cliente' | 'vendedora' | 'master'

  const Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  bool get esVendedora => rol == 'vendedora';
  bool get esMaster => rol == 'master';

  /// Campos para guardar en Firestore (sin contraseña: eso lo guarda
  /// Firebase Authentication de forma segura, nunca la base de datos).
  Map<String, dynamic> aCampos() => {'nombre': nombre, 'email': email, 'rol': rol};

  factory Usuario.deDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    return Usuario(
      uid: doc.id,
      nombre: j['nombre'] as String,
      email: j['email'] as String,
      rol: j['rol'] as String,
    );
  }
}
