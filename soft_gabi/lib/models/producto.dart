import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/pedidos_util.dart';

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

/// Lee un número de Firestore sin romperse si llega como double o como int.
int? _entero(Object? v) => v is num ? v.toInt() : null;

/// Decodifica una foto en base64; devuelve null si el texto está roto.
Uint8List? _decodificarFoto(String? valor) {
  if (valor == null || valor.isEmpty) return null;
  try {
    return base64Decode(valor);
  } catch (_) {
    return null;
  }
}

/// Un extra que el cliente puede tildar al pedir ("Extra queso" +$500,
/// "Sin cebolla" $0). Lo define la vendedora en cada producto.
class OpcionProducto {
  final String id;
  final String nombre;
  final int precio;

  const OpcionProducto({required this.id, required this.nombre, this.precio = 0});

  Map<String, dynamic> aCampos() => {'id': id, 'nombre': nombre, 'precio': precio};

  factory OpcionProducto.deCampos(Map<String, dynamic> j) => OpcionProducto(
        id: j['id']?.toString() ?? '',
        nombre: j['nombre'] as String? ?? '',
        precio: _entero(j['precio']) ?? 0,
      );

  static List<OpcionProducto> listaDe(Object? valor) {
    if (valor is! List) return const [];
    return [
      for (final e in valor)
        if (e is Map) OpcionProducto.deCampos(Map<String, dynamic>.from(e)),
    ];
  }
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

  /// Decodifica [imagenBase64] a bytes para mostrarla con Image.memory. Si el
  /// texto guardado no es un base64 válido (por ejemplo, un dato corrupto o
  /// incompleto que llegó mal desde la web), devuelve null en vez de tirar
  /// una excepción, así la tarjeta cae sola al emoji/ícono de respaldo en
  /// lugar de romperse o quedar en blanco.
  Uint8List? get bytesFoto => _decodificarFoto(imagenBase64);

  final String emoji;

  final String tag;
  final int tiempo; // minutos de preparación
  final String categoria;
  final String categoriaLabel;
  final bool destacado;
  final bool esSinTacc;

  /// null = sin control de stock; 0 = agotado (se oculta del menú).
  /// Se edita desde la web ("Mis productos").
  final int? stock;

  /// Calorías por unidad (kcal). null = no se muestra.
  final int? calorias;

  /// Extras que el cliente puede elegir al pedir.
  final List<OpcionProducto> opciones;

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
    this.stock,
    this.calorias,
    this.opciones = const [],
  });

  /// Categorías que son kiosco (golosinas, gaseosas): se compran y se llevan
  /// al toque, no se "preparan", así que no tiene sentido mostrarles un
  /// tiempo de preparación (a diferencia de la comida del almuerzo, que sí
  /// se cocina al pedido).
  static const _categoriasDeKiosco = {'desayuno', 'bebidas'};
  bool get esComidaDeAlmuerzo => !_categoriasDeKiosco.contains(categoria);

  bool get tieneStock => stock == null || stock! > 0;

  /// Campos para guardar en Firestore (sin el id: ese lo pone el documento).
  /// Solo se usa al sembrar el catálogo y al crear productos nuevos; para
  /// editar se actualizan solo los campos que cambian (ver
  /// CantinaProvider.editarProducto), así no se pisa el stock de la web.
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
        'stock': stock,
        'calorias': calorias,
        'opciones': opciones.map((o) => o.aCampos()).toList(),
      };

  factory Producto.deDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    return Producto(
      id: doc.id,
      nombre: j['nombre'] as String? ?? '',
      descripcion: j['descripcion'] as String? ?? '',
      // Firestore puede guardar el precio como entero o como decimal según
      // cómo lo haya escrito cada plataforma (la web, por ejemplo, siempre
      // manda un Number de JS). Un "as int" directo tira una excepción si
      // llega como double, por eso se lee pasando por `num`.
      precio: _entero(j['precio']) ?? 0,
      imagen: j['imagen'] as String?,
      imagenBase64: j['imagenBase64'] as String?,
      emoji: j['emoji'] as String? ?? '🍽️',
      tag: j['tag'] as String? ?? '',
      tiempo: _entero(j['tiempo']) ?? 5,
      categoria: j['categoria'] as String? ?? 'platos',
      categoriaLabel: j['categoriaLabel'] as String? ?? '',
      destacado: j['destacado'] as bool? ?? false,
      esSinTacc: j['esSinTacc'] as bool? ?? false,
      stock: _entero(j['stock']),
      calorias: _entero(j['calorias']),
      opciones: OpcionProducto.listaDe(j['opciones']),
    );
  }
}

/// Valor "centinela" para distinguir entre "no me pasaron imagenBase64"
/// (dejar la que había) y "me pasaron null a propósito" (borrar la foto
/// subida y volver a imagen/emoji). Lo usa CantinaProvider.editarProducto.
const Object sinCambioImagen = Object();

// --------------------------------------------------------------- combos
class ItemCombo {
  final String productoId;
  final String nombre; // copia del nombre, por si el producto se borra
  final int cantidad;

  const ItemCombo({required this.productoId, required this.nombre, this.cantidad = 1});

  Map<String, dynamic> aCampos() => {'productoId': productoId, 'nombre': nombre, 'cantidad': cantidad};

  factory ItemCombo.deCampos(Map<String, dynamic> j) => ItemCombo(
        productoId: j['productoId']?.toString() ?? '',
        nombre: j['nombre'] as String? ?? '',
        cantidad: _entero(j['cantidad']) ?? 1,
      );
}

/// Combo que arma la vendedora: 2 o más productos con un precio especial.
class Combo {
  final String id;
  final String nombre;
  final String descripcion;
  final int precio;
  final List<ItemCombo> items;
  final bool activo;
  final String? imagenBase64;

  const Combo({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.precio,
    required this.items,
    this.activo = true,
    this.imagenBase64,
  });

  Uint8List? get bytesFoto => _decodificarFoto(imagenBase64);

  Map<String, dynamic> aCampos() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'items': items.map((i) => i.aCampos()).toList(),
        'activo': activo,
        'imagenBase64': imagenBase64,
      };

  factory Combo.deDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    final items = j['items'];
    return Combo(
      id: doc.id,
      nombre: j['nombre'] as String? ?? '',
      descripcion: j['descripcion'] as String? ?? '',
      precio: _entero(j['precio']) ?? 0,
      items: [
        if (items is List)
          for (final e in items)
            if (e is Map) ItemCombo.deCampos(Map<String, dynamic>.from(e)),
      ],
      activo: j['activo'] as bool? ?? true,
      imagenBase64: j['imagenBase64'] as String?,
    );
  }
}

Producto? _buscarProducto(List<Producto> catalogo, String id) {
  for (final p in catalogo) {
    if (p.id == id) return p;
  }
  return null;
}

/// Un combo con los datos calculados a partir del catálogo actual.
class DetalleCombo {
  final Combo combo;
  final int precioNormal; // lo que saldrían los productos por separado
  final int? calorias;
  final bool disponible; // activo, con todos sus productos y ninguno agotado
  final List<String> descripcionItems; // ["1x Pizza", "1x Coca-Cola"]

  const DetalleCombo({
    required this.combo,
    required this.precioNormal,
    required this.calorias,
    required this.disponible,
    required this.descripcionItems,
  });

  int get ahorro => precioNormal > combo.precio ? precioNormal - combo.precio : 0;

  factory DetalleCombo.calcular(Combo combo, List<Producto> catalogo) {
    final partes = [
      for (final it in combo.items)
        (it, _buscarProducto(catalogo, it.productoId)),
    ];
    final completos = partes.every((pt) => pt.$2 != null);
    final precioNormal = partes.fold<int>(0, (s, pt) => s + (pt.$2?.precio ?? 0) * pt.$1.cantidad);
    final conCalorias = partes.every((pt) => pt.$2?.calorias != null);
    return DetalleCombo(
      combo: combo,
      precioNormal: precioNormal,
      calorias: conCalorias && partes.isNotEmpty
          ? partes.fold<int>(0, (s, pt) => s + pt.$2!.calorias! * pt.$1.cantidad)
          : null,
      disponible: combo.activo &&
          partes.isNotEmpty &&
          completos &&
          partes.every((pt) => pt.$2!.tieneStock),
      descripcionItems: [
        for (final pt in partes) '${pt.$1.cantidad}x ${pt.$2?.nombre ?? pt.$1.nombre}',
      ],
    );
  }
}

// -------------------------------------------------------------- carrito
/// Una línea del carrito: un producto (con sus opciones y aclaración) o un
/// combo. Dos líneas se juntan solo si son lo mismo con las mismas opciones.
class ItemCarrito {
  final Producto? producto;
  final DetalleCombo? combo;
  final List<OpcionProducto> opciones;
  String nota;
  int cantidad;

  ItemCarrito({
    this.producto,
    this.combo,
    this.opciones = const [],
    this.nota = '',
    this.cantidad = 1,
  }) : assert((producto == null) != (combo == null), 'Una línea es un producto o un combo');

  bool get esCombo => combo != null;
  String get tipo => esCombo ? 'combo' : 'producto';
  String get refId => esCombo ? combo!.combo.id : producto!.id;
  String get nombre => esCombo ? combo!.combo.nombre : producto!.nombre;

  String get clave {
    final ids = opciones.map((o) => o.id).toList()..sort();
    return '$tipo:$refId:${ids.join(',')}';
  }

  int get precioUnitario => esCombo
      ? combo!.combo.precio
      : producto!.precio + opciones.fold<int>(0, (s, o) => s + o.precio);

  int get subtotal => precioUnitario * cantidad;

  List<String> get detalle => esCombo ? combo!.descripcionItems : const [];

  String get emoji => esCombo ? '🍱' : producto!.emoji;
  Uint8List? get bytesFoto => esCombo ? combo!.combo.bytesFoto : producto!.bytesFoto;
  String? get imagenAsset => esCombo ? null : producto!.imagen;

  ItemPedido aItemPedido() => ItemPedido(
        nombre: nombre,
        cantidad: cantidad,
        tipo: tipo,
        refId: refId,
        precioUnitario: precioUnitario,
        opciones: opciones,
        nota: nota.trim().isEmpty ? null : nota.trim(),
        detalle: detalle,
      );
}

class ItemPedido {
  final String nombre;
  final int cantidad;
  final String? tipo; // 'producto' | 'combo' (null en pedidos viejos)
  final String? refId;
  final int? precioUnitario;
  final List<OpcionProducto> opciones;
  final String? nota;
  final List<String> detalle;

  const ItemPedido({
    required this.nombre,
    required this.cantidad,
    this.tipo,
    this.refId,
    this.precioUnitario,
    this.opciones = const [],
    this.nota,
    this.detalle = const [],
  });

  bool get esCombo => tipo == 'combo';

  Map<String, dynamic> aCampos() => {
        'tipo': tipo,
        'id': refId,
        'nombre': nombre,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'opciones': opciones.map((o) => o.aCampos()).toList(),
        'nota': nota,
        'detalle': detalle,
      };

  factory ItemPedido.deCampos(Map<String, dynamic> j) {
    final detalle = j['detalle'];
    return ItemPedido(
      nombre: j['nombre'] as String? ?? '',
      cantidad: _entero(j['cantidad']) ?? 1,
      tipo: j['tipo'] as String?,
      refId: j['id']?.toString(),
      precioUnitario: _entero(j['precioUnitario']),
      opciones: OpcionProducto.listaDe(j['opciones']),
      nota: j['nota'] as String?,
      detalle: [if (detalle is List) for (final d in detalle) d.toString()],
    );
  }
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
  final String? horaRetiro; // "HH:MM" de hoy, o null = lo antes posible
  /// Solo Mercado Pago: 'pendiente' | 'aprobado' | 'rechazado'. Lo cambia
  /// el servidor (functions/) cuando Mercado Pago confirma el pago.
  final String? estadoPago;
  final int? pagaCon; // efectivo: con cuánto paga
  final int? vuelto;
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
    this.horaRetiro,
    this.estadoPago,
    this.pagaCon,
    this.vuelto,
    this.calificacion,
    this.comentario,
  });

  String get metodoPagoLabel => switch (metodoPago) {
        'transferencia' => 'Transferencia bancaria',
        'mercadopago' => 'Mercado Pago',
        'tarjeta' => 'Tarjeta de crédito/débito',
        _ => 'Efectivo en caja',
      };

  bool get esMercadoPago => metodoPago == 'mercadopago';
  bool get pagoAprobado => estadoPago == 'aprobado';

  /// Plata que realmente entró: un pedido de Mercado Pago cuenta solo si
  /// el pago se acreditó.
  bool get cuentaComoCobrado => !esMercadoPago || estadoPago == null || pagoAprobado;

  /// Campos para guardar en Firestore (sin el id: ese lo pone el documento).
  Map<String, dynamic> aCampos() => {
        'numero': numero,
        'fecha': Timestamp.fromDate(fecha),
        'cliente': cliente,
        'uid': uid,
        'items': items.map((i) => i.aCampos()).toList(),
        'total': total,
        'metodoPago': metodoPago,
        'horaRetiro': horaRetiro,
        'estadoPago': estadoPago,
        'pagaCon': pagaCon,
        'vuelto': vuelto,
        'calificacion': calificacion,
        'comentario': comentario,
      };

  factory Pedido.deDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    final fecha = j['fecha'];
    final items = j['items'];
    return Pedido(
      id: doc.id,
      numero: _entero(j['numero']) ?? 0,
      // Recién creado desde la web, la fecha puede venir vacía un instante
      // (la pone el servidor): mientras tanto usamos la hora actual.
      fecha: fecha is Timestamp ? fecha.toDate() : DateTime.now(),
      cliente: j['cliente'] as String? ?? 'Invitado',
      uid: j['uid'] as String?,
      items: [
        if (items is List)
          for (final e in items)
            if (e is Map) ItemPedido.deCampos(Map<String, dynamic>.from(e)),
      ],
      total: _entero(j['total']) ?? 0,
      metodoPago: normalizarMetodoPago(j['metodoPago']),
      horaRetiro: j['horaRetiro'] as String?,
      estadoPago: j['estadoPago'] as String?,
      pagaCon: _entero(j['pagaCon']),
      vuelto: _entero(j['vuelto']),
      calificacion: _entero(j['calificacion']),
      comentario: j['comentario'] as String?,
    );
  }
}

/// Una nota del anotador de la vendedora.
class Nota {
  final String id;
  final String texto;
  final bool hecha;
  final String autor;
  final DateTime fecha;

  const Nota({
    required this.id,
    required this.texto,
    required this.hecha,
    required this.autor,
    required this.fecha,
  });

  factory Nota.deDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    final fecha = j['fecha'];
    return Nota(
      id: doc.id,
      texto: j['texto'] as String? ?? '',
      hecha: j['hecha'] as bool? ?? false,
      autor: j['autor'] as String? ?? '',
      fecha: fecha is Timestamp ? fecha.toDate() : DateTime.now(),
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
      nombre: j['nombre'] as String? ?? '',
      email: j['email'] as String? ?? '',
      rol: j['rol'] as String? ?? 'cliente',
    );
  }
}
