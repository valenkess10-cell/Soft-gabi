import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../data/catalogo.dart' as catalogo;
import '../models/producto.dart';

/// Estado global de la app: carrito, sesión, pedidos y filtro del menú.
///
/// Usuarios y pedidos viven en Firebase (Authentication + Cloud Firestore),
/// así que se sincronizan solos entre todos los celulares: si alguien pide
/// desde su teléfono, la vendedora lo ve en el suyo al instante.
class CantinaProvider extends ChangeNotifier {
  CantinaProvider({fb.FirebaseAuth? auth, FirebaseFirestore? db, FirebaseFunctions? functions})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _functionsPropio = functions;

  /// Login de la vendedora: entra directo con este email y contraseña fijos,
  /// sin que nadie tenga que registrarla antes. La primera vez que alguien
  /// inicia sesión con estos datos, la cuenta se crea sola en Firebase.
  /// Cambiá esta contraseña antes de usar la app de verdad.
  static const emailVendedora = 'vendedora@micantina.com';
  static const _passwordVendedora = 'Vendedora2026';

  /// Login master: ve todo el Panel de Ventas más la lista de usuarios
  /// registrados. Mismo mecanismo de alta automática que la vendedora.
  static const emailMaster = 'master@micantina.com';
  static const _passwordMaster = 'Cantina2026';

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions? _functionsPropio;
  // Se pide recién al usarlo (cobro con Mercado Pago), así los tests que no
  // tienen Firebase real pueden crear el provider igual.
  FirebaseFunctions get _functions => _functionsPropio ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _colUsuarios => _db.collection('usuarios');
  CollectionReference<Map<String, dynamic>> get _colPedidos => _db.collection('pedidos');
  CollectionReference<Map<String, dynamic>> get _colProductos => _db.collection('productos');
  CollectionReference<Map<String, dynamic>> get _colCombos => _db.collection('combos');
  CollectionReference<Map<String, dynamic>> get _colNotas => _db.collection('notas');
  DocumentReference<Map<String, dynamic>> get _docContadorTurnos =>
      _db.collection('contadores').doc('turnos');

  StreamSubscription<fb.User?>? _subAuth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subPedidos;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subUsuarios;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subProductos;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subCombos;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subNotas;

  List<Pedido> _pedidos = []; // el más reciente primero
  List<Usuario> _usuariosRegistrados = [];
  List<Producto> _productos = []; // el catálogo "vivo" que viene de Firestore
  List<Combo> _combos = [];
  List<Nota> _notas = [];
  final List<ItemCarrito> _carrito = [];
  Usuario? _usuario;
  String _categoriaActiva = 'todos';
  bool _listo = false; // ya resolvió la sesión inicial (evita parpadeo al abrir la app)

  // ---------------------------------------------------------------- carga
  /// Se llama una sola vez, al abrir la app.
  Future<void> cargar() async {
    _subAuth = _auth.authStateChanges().listen(_onCambioSesion);
    // Sin esto, alguien que no se registró (invitado) no podría ni leer el
    // menú ni crear un pedido: las reglas de Firestore exigen estar logueado.
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
      } catch (_) {
        // Sin internet al abrir la app: se sigue viendo el menú (es local),
        // solo falla si intenta pedir o iniciar sesión.
      }
    }
    // El catálogo de productos lo ve TODO el mundo (cliente, invitado,
    // vendedora o master), a diferencia de pedidos/usuarios que dependen
    // del rol. Por eso se escucha acá, no en _aplicarUsuario. Sembrar el
    // catálogo de fábrica, en cambio, SÍ depende del rol (ver
    // _sembrarProductosSiHaceFalta): las reglas de Firestore solo dejan
    // escribir en `productos` a la vendedora/master.
    _escucharProductos();
    _escucharCombos();
    _listo = true;
    notifyListeners();
  }

  /// La primera vez que la vendedora o la cuenta master entran a un proyecto
  /// de Firebase nuevo (la colección `productos` está vacía), copiamos ahí
  /// el catálogo que trae la app de fábrica (`catalogo.productos`). Usamos
  /// IDs fijos ('1', '2', ...) así, aunque pase dos veces, se pisan los
  /// mismos documentos en vez de duplicarse. Un cliente común nunca podría
  /// hacer esto: las reglas de Firestore solo dejan escribir en `productos`
  /// a la vendedora/master, así que se dispara solo cuando ese rol entra.
  Future<void> _sembrarProductosSiHaceFalta() async {
    try {
      final hayAlguno = await _colProductos.limit(1).get();
      if (hayAlguno.docs.isNotEmpty) return;
      final lote = _db.batch();
      for (final p in catalogo.productos) {
        lote.set(_colProductos.doc(p.id), p.aCampos());
      }
      await lote.commit();
    } catch (_) {
      // Sin conexión esa vez: se reintenta solo la próxima vez que la
      // vendedora/master abra la app con internet.
    }
  }

  void _escucharProductos() {
    _subProductos = _colProductos.snapshots().listen((snap) {
      // Se parsea documento por documento (en vez de un solo
      // snap.docs.map(...).toList()) para que, si alguno viene con un dato
      // raro, se lo salte en vez de tirar abajo la actualización de TODA la
      // lista de productos y dejar el menú desactualizado en el celular.
      final productos = <Producto>[];
      for (final doc in snap.docs) {
        try {
          productos.add(Producto.deDocumento(doc));
        } catch (e) {
          debugPrint('No se pudo leer el producto ${doc.id}: $e');
        }
      }
      _productos = productos;
      notifyListeners();
    });
  }

  void _escucharCombos() {
    _subCombos = _colCombos.snapshots().listen((snap) {
      final combos = <Combo>[];
      for (final doc in snap.docs) {
        try {
          combos.add(Combo.deDocumento(doc));
        } catch (e) {
          debugPrint('No se pudo leer el combo ${doc.id}: $e');
        }
      }
      _combos = combos;
      notifyListeners();
    }, onError: (Object e) => debugPrint('No se pudieron leer los combos: $e'));
  }

  Future<void> _onCambioSesion(fb.User? user) async {
    if (user == null || user.isAnonymous) {
      _aplicarUsuario(null);
      return;
    }
    // Si el login/registro de esta MISMA sesión ya dejó cargado el perfil
    // correcto (ver registrar/iniciarSesion), no lo pisamos con una lectura
    // vieja: evita la condición de carrera que hacía que, la primera vez
    // que alguien entraba como vendedora/master, el perfil llegara ANTES
    // de que termináramos de guardarlo en Firestore (y se quedara sin ver
    // el Panel de Ventas hasta cerrar y volver a abrir la app).
    if (_usuario != null && _usuario!.uid == user.uid) return;

    try {
      final doc = await _colUsuarios.doc(user.uid).get();
      _aplicarUsuario(doc.exists ? Usuario.deDocumento(doc) : null);
    } catch (_) {
      _aplicarUsuario(null);
    }
  }

  /// Punto único que actualiza quién está logueado y prende/apaga los
  /// listeners de Firestore que le corresponden. Se llama tanto desde el
  /// listener de authStateChanges como apenas termina un registro/login,
  /// así la UI no tiene que esperar a una segunda lectura a Firestore.
  void _aplicarUsuario(Usuario? nuevo) {
    _usuario = nuevo;
    _subUsuarios?.cancel();
    _subPedidos?.cancel();
    _subNotas?.cancel();
    _subUsuarios = null;
    _subPedidos = null;
    _subNotas = null;
    _usuariosRegistrados = [];
    _pedidos = [];
    _notas = [];

    // Solo quien ve el Panel de Ventas necesita escuchar TODOS los pedidos
    // (las reglas de Firestore además lo exigen: un cliente común no puede
    // leer los pedidos de otras personas).
    if (puedeVerVentas) {
      _escucharPedidos();
      _escucharNotas();
      if (esMaster) _escucharUsuarios();
      // Sin "await": no hace falta bloquear el login para esto, y el
      // listener de productos ya activo recoge el resultado solo.
      _sembrarProductosSiHaceFalta();
    }
    notifyListeners();
  }

  void _escucharPedidos() {
    _subPedidos = _colPedidos
        .orderBy('fecha', descending: true)
        .limit(300)
        .snapshots()
        .listen((snap) {
      final pedidos = <Pedido>[];
      for (final doc in snap.docs) {
        try {
          pedidos.add(Pedido.deDocumento(doc));
        } catch (e) {
          debugPrint('No se pudo leer el pedido ${doc.id}: $e');
        }
      }
      _pedidos = pedidos;
      notifyListeners();
    });
  }

  void _escucharNotas() {
    _subNotas = _colNotas.orderBy('fecha', descending: true).snapshots().listen((snap) {
      _notas = snap.docs.map(Nota.deDocumento).toList();
      notifyListeners();
    }, onError: (Object e) => debugPrint('No se pudo leer el anotador: $e'));
  }

  void _escucharUsuarios() {
    _subUsuarios = _colUsuarios.snapshots().listen((snap) {
      _usuariosRegistrados = snap.docs.map(Usuario.deDocumento).toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subAuth?.cancel();
    _subPedidos?.cancel();
    _subUsuarios?.cancel();
    _subProductos?.cancel();
    _subCombos?.cancel();
    _subNotas?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------- sesión
  bool get listo => _listo;
  Usuario? get usuario => _usuario;
  bool get esVendedora => _usuario?.esVendedora ?? false;
  bool get esMaster => _usuario?.esMaster ?? false;

  /// La vendedora y la cuenta master comparten el Panel de Ventas;
  /// la master además ve la lista de usuarios registrados.
  bool get puedeVerVentas => esVendedora || esMaster;

  /// Solo tiene datos cuando la cuenta activa es la master (ver _onCambioSesion).
  List<Usuario> get usuariosRegistrados => List.unmodifiable(_usuariosRegistrados);

  /// Devuelve un mensaje de error, o null si salió bien.
  Future<String?> registrar({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final mail = email.trim().toLowerCase();
    if (mail == emailMaster || mail == emailVendedora) {
      return 'Ese email está reservado';
    }
    try {
      final credencial =
          await _auth.createUserWithEmailAndPassword(email: mail, password: password);
      final nuevo =
          Usuario(uid: credencial.user!.uid, nombre: nombre.trim(), email: mail, rol: 'cliente');
      await _colUsuarios.doc(nuevo.uid).set(nuevo.aCampos());
      _aplicarUsuario(nuevo);
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _mensajeError(e);
    } catch (_) {
      return 'No se pudo completar el registro. Probá de nuevo.';
    }
  }

  /// Devuelve un mensaje de error, o null si salió bien.
  Future<String?> iniciarSesion({required String email, required String password}) async {
    final mail = email.trim().toLowerCase();
    try {
      final credencial = await _auth.signInWithEmailAndPassword(email: mail, password: password);
      final doc = await _colUsuarios.doc(credencial.user!.uid).get();
      _aplicarUsuario(doc.exists ? Usuario.deDocumento(doc) : null);
      return null;
    } on fb.FirebaseAuthException catch (e) {
      // Primera vez que alguien usa el login fijo de vendedora/master:
      // si la contraseña coincide con la fija, creamos la cuenta en el momento.
      final esCuentaDeStaff = mail == emailVendedora || mail == emailMaster;
      final noExiste = e.code == 'user-not-found' || e.code == 'invalid-credential';
      if (esCuentaDeStaff && noExiste) {
        final claveFija = mail == emailMaster ? _passwordMaster : _passwordVendedora;
        if (password != claveFija) return 'Email o contraseña incorrectos';
        return _crearCuentaDeStaff(mail);
      }
      return _mensajeError(e);
    } catch (_) {
      return 'No se pudo iniciar sesión. Probá de nuevo.';
    }
  }

  Future<String?> _crearCuentaDeStaff(String mail) async {
    try {
      final claveFija = mail == emailMaster ? _passwordMaster : _passwordVendedora;
      final credencial =
          await _auth.createUserWithEmailAndPassword(email: mail, password: claveFija);
      final rol = mail == emailMaster ? 'master' : 'vendedora';
      final nombre = mail == emailMaster ? 'Administrador' : 'Vendedora';
      final nuevo = Usuario(uid: credencial.user!.uid, nombre: nombre, email: mail, rol: rol);
      await _colUsuarios.doc(nuevo.uid).set(nuevo.aCampos());
      _aplicarUsuario(nuevo);
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _mensajeError(e);
    } catch (_) {
      return 'No se pudo iniciar sesión. Probá de nuevo.';
    }
  }

  String _mensajeError(fb.FirebaseAuthException e) => switch (e.code) {
        'email-already-in-use' => 'El email ya está registrado',
        'invalid-email' => 'El email no es válido',
        'weak-password' => 'La contraseña debe tener al menos 6 caracteres',
        'network-request-failed' => 'No hay conexión a internet',
        _ => 'Email o contraseña incorrectos',
      };

  Future<void> cerrarSesion() async {
    await _auth.signOut();
    // Volvemos a entrar como invitado para poder seguir pidiendo sin cuenta.
    try {
      await _auth.signInAnonymously();
    } catch (_) {}
  }

  // --------------------------------------------------------------- menú
  String get categoriaActiva => _categoriaActiva;

  void seleccionarCategoria(String id) {
    if (id == _categoriaActiva) return;
    _categoriaActiva = id;
    notifyListeners();
  }

  /// Mientras Firestore todavía no trajo nada (recién se abrió la app, o no
  /// hay internet) mostramos el catálogo de fábrica para que la pantalla no
  /// se vea vacía; apenas llega el primer snapshot, se usa el real.
  List<Producto> get _productosActuales => _productos.isEmpty ? catalogo.productos : _productos;

  /// Lo que ve un cliente: sin los productos agotados (stock 0).
  List<Producto> get _productosVisibles => _productosActuales.where((p) => p.tieneStock).toList();

  List<Producto> get productosFiltrados {
    final base = _productosVisibles;
    switch (_categoriaActiva) {
      case 'todos':
        return base;
      case 'sin-tacc':
        return base.where((p) => p.esSinTacc).toList();
      default:
        return base.where((p) => p.categoria == _categoriaActiva).toList();
    }
  }

  List<Producto> get destacados => _productosVisibles.where((p) => p.destacado).toList();

  List<Producto> productosDeCategoria(String categoriaId) =>
      _productosVisibles.where((p) => p.categoria == categoriaId).toList();

  /// Combos que se ofrecen a los clientes (activos y con todo en stock).
  List<DetalleCombo> get combosVisibles => [
        for (final c in _combos)
          if (DetalleCombo.calcular(c, _productosActuales) case final d when d.disponible) d,
      ];

  /// Todos los combos (también pausados), para el panel de la vendedora.
  List<DetalleCombo> get todosLosCombos =>
      [for (final c in _combos) DetalleCombo.calcular(c, _productosActuales)];

  /// Catálogo completo (todas las categorías), para el panel de productos
  /// de la vendedora/master.
  List<Producto> get todosLosProductos => List.unmodifiable(_productosActuales);

  // ------------------------------------------------- productos (vendedora)
  /// Agrega un producto nuevo al catálogo compartido. Devuelve un mensaje de
  /// error, o null si salió bien. Las reglas de Firestore también exigen ser
  /// vendedora o master para escribir en `productos`, así que este chequeo es
  /// solo para dar un mensaje claro en vez de un error crudo de permisos.
  Future<String?> agregarProducto({
    required String nombre,
    required int precio,
    required String categoriaId,
    String? descripcion,
    String? imagenBase64,
    int? calorias,
    List<OpcionProducto> opciones = const [],
  }) async {
    if (!puedeVerVentas) return 'No tenés permiso para agregar productos';
    try {
      final cat = catalogo.categorias.firstWhere(
        (c) => c.id == categoriaId,
        orElse: () => catalogo.categorias.first,
      );
      final ref = _colProductos.doc();
      final nombreLimpio = nombre.trim();
      final nuevo = Producto(
        id: ref.id,
        nombre: nombreLimpio,
        descripcion: (descripcion?.trim().isNotEmpty ?? false) ? descripcion!.trim() : nombreLimpio,
        precio: precio,
        imagenBase64: imagenBase64,
        tag: 'Nuevo',
        tiempo: 5,
        categoria: cat.id,
        categoriaLabel: cat.nombre,
        calorias: calorias,
        opciones: opciones,
      );
      await ref.set(nuevo.aCampos());
      return null;
    } catch (_) {
      return 'No se pudo agregar el producto. Probá de nuevo.';
    }
  }

  /// Edita un producto existente (incluidos los del catálogo original: al
  /// venir todos de Firestore, cualquiera se puede modificar o borrar).
  /// Solo actualiza los campos de este formulario: así no se pierde el
  /// stock ni otros datos que se cargan desde la web.
  Future<String?> editarProducto({
    required Producto original,
    required String nombre,
    required int precio,
    required String categoriaId,
    String? descripcion,
    Object? imagenBase64 = sinCambioImagen,
    int? calorias,
    List<OpcionProducto> opciones = const [],
  }) async {
    if (!puedeVerVentas) return 'No tenés permiso para editar productos';
    try {
      final cat = catalogo.categorias.firstWhere(
        (c) => c.id == categoriaId,
        orElse: () => catalogo.categorias.first,
      );
      final nombreLimpio = nombre.trim();
      final cambios = <String, dynamic>{
        'nombre': nombreLimpio,
        'descripcion':
            (descripcion?.trim().isNotEmpty ?? false) ? descripcion!.trim() : nombreLimpio,
        'precio': precio,
        'categoria': cat.id,
        'categoriaLabel': cat.nombre,
        'calorias': calorias,
        'opciones': opciones.map((o) => o.aCampos()).toList(),
      };
      if (!identical(imagenBase64, sinCambioImagen)) {
        cambios['imagenBase64'] = imagenBase64 as String?;
        // Si borran la foto subida, tampoco se vuelve a la foto de fábrica.
        if (imagenBase64 == null) cambios['imagen'] = null;
      }
      await _colProductos.doc(original.id).set(cambios, SetOptions(merge: true));
      return null;
    } catch (_) {
      return 'No se pudo guardar el cambio. Probá de nuevo.';
    }
  }

  /// Elimina un producto del catálogo compartido.
  Future<String?> eliminarProducto(Producto producto) async {
    if (!puedeVerVentas) return 'No tenés permiso para eliminar productos';
    try {
      await _colProductos.doc(producto.id).delete();
      return null;
    } catch (_) {
      return 'No se pudo eliminar el producto. Probá de nuevo.';
    }
  }

  // --------------------------------------------------- combos (vendedora)
  /// Crea (id == null) o edita un combo. Devuelve un error o null.
  Future<String?> guardarCombo({
    String? id,
    required String nombre,
    String descripcion = '',
    required int precio,
    required List<ItemCombo> items,
    bool activo = true,
  }) async {
    if (!puedeVerVentas) return 'No tenés permiso para armar combos';
    final unidades = items.fold<int>(0, (s, i) => s + i.cantidad);
    if (unidades < 2) return 'Un combo lleva al menos 2 productos';
    try {
      final ref = id == null ? _colCombos.doc() : _colCombos.doc(id);
      final anterior = _combos.where((c) => c.id == id).toList();
      final combo = Combo(
        id: ref.id,
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
        precio: precio,
        items: items,
        activo: activo,
        imagenBase64: anterior.isEmpty ? null : anterior.first.imagenBase64,
      );
      await ref.set(combo.aCampos());
      return null;
    } catch (_) {
      return 'No se pudo guardar el combo. Probá de nuevo.';
    }
  }

  Future<String?> cambiarComboActivo(Combo combo, bool activo) async {
    try {
      await _colCombos.doc(combo.id).update({'activo': activo});
      return null;
    } catch (_) {
      return 'No se pudo cambiar el combo.';
    }
  }

  Future<String?> eliminarCombo(Combo combo) async {
    try {
      await _colCombos.doc(combo.id).delete();
      return null;
    } catch (_) {
      return 'No se pudo eliminar el combo.';
    }
  }

  // ------------------------------------------------- anotador (vendedora)
  List<Nota> get notas => List.unmodifiable(_notas);

  Future<String?> agregarNota(String texto) async {
    final t = texto.trim();
    if (t.isEmpty) return null;
    try {
      await _colNotas.add({
        'texto': t,
        'hecha': false,
        'autor': _usuario?.nombre ?? '',
        'fecha': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (_) {
      return 'No se pudo guardar la nota.';
    }
  }

  Future<void> marcarNota(Nota nota, bool hecha) => _colNotas.doc(nota.id).update({'hecha': hecha});

  Future<void> eliminarNota(Nota nota) => _colNotas.doc(nota.id).delete();

  // ------------------------------------------------------------ carrito
  List<ItemCarrito> get carrito => List.unmodifiable(_carrito);
  int get totalCarrito => _carrito.fold(0, (s, i) => s + i.subtotal);
  int get cantidadTotal => _carrito.fold(0, (s, i) => s + i.cantidad);

  void _sumarLinea(ItemCarrito nueva) {
    final index = _carrito.indexWhere((i) => i.clave == nueva.clave);
    if (index >= 0) {
      _carrito[index].cantidad++;
      if (nueva.nota.trim().isNotEmpty) _carrito[index].nota = nueva.nota.trim();
    } else {
      _carrito.add(nueva);
    }
    notifyListeners();
  }

  /// Mismo producto con las mismas opciones suma cantidad; con opciones
  /// distintas va en otra línea.
  void agregarAlCarrito(
    Producto producto, {
    List<OpcionProducto> opciones = const [],
    String nota = '',
  }) =>
      _sumarLinea(ItemCarrito(producto: producto, opciones: opciones, nota: nota.trim()));

  void agregarComboAlCarrito(DetalleCombo combo) => _sumarLinea(ItemCarrito(combo: combo));

  void sumarCantidad(ItemCarrito item) {
    item.cantidad++;
    notifyListeners();
  }

  void decrementarCantidad(ItemCarrito item) {
    if (item.cantidad > 1) {
      item.cantidad--;
    } else {
      _carrito.remove(item);
    }
    notifyListeners();
  }

  void quitarDelCarrito(ItemCarrito item) {
    _carrito.remove(item);
    notifyListeners();
  }

  void cambiarNota(ItemCarrito item, String nota) {
    item.nota = nota.trim();
    notifyListeners();
  }

  // ------------------------------------------------------------ pedidos
  /// Solo tiene datos si la cuenta activa puede ver el Panel de Ventas
  /// (ver _onCambioSesion): un cliente común no escucha los pedidos ajenos.
  List<Pedido> get pedidos => List.unmodifiable(_pedidos);
  int get totalRecaudado =>
      _pedidos.where((p) => p.cuentaComoCobrado).fold(0, (s, p) => s + p.total);
  int get pedidosHoy {
    final hoy = DateTime.now();
    return _pedidos.where((p) => _mismoDia(p.fecha, hoy)).length;
  }

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _claveDelDia(DateTime f) =>
      '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

  /// Registra el pedido en Firestore y vacía el carrito. El número de turno
  /// se asigna con una transacción (vuelve a 1 cada día) para que dos
  /// pedidos simultáneos nunca puedan terminar con el mismo número.
  ///
  /// [horaRetiro]: "HH:MM" de hoy, o null = lo antes posible.
  /// Con Mercado Pago el pedido queda con estadoPago 'pendiente' hasta que
  /// el servidor recibe la confirmación (ver crearPagoMercadoPago).
  Future<Pedido> confirmarPago(String metodoPago, {String? horaRetiro, int? pagaCon}) async {
    assert(_carrito.isNotEmpty, 'No se puede confirmar un pedido vacío');
    final ahora = DateTime.now();
    final hoy = _claveDelDia(ahora);
    final pedidoRef = _colPedidos.doc();
    final items = _carrito.map((i) => i.aItemPedido()).toList();
    final total = totalCarrito;
    final cliente = _usuario?.nombre ?? 'Invitado';
    final uid = _auth.currentUser?.uid;
    final esEfectivo = metodoPago == 'efectivo';

    Pedido armar(int numero) => Pedido(
          id: pedidoRef.id,
          numero: numero,
          fecha: ahora,
          cliente: cliente,
          uid: uid,
          items: items,
          total: total,
          metodoPago: metodoPago,
          horaRetiro: horaRetiro,
          estadoPago: metodoPago == 'mercadopago' ? 'pendiente' : null,
          pagaCon: esEfectivo ? pagaCon : null,
          vuelto: esEfectivo && pagaCon != null ? pagaCon - total : null,
        );

    final numero = await _db.runTransaction<int>((tx) async {
      final snap = await tx.get(_docContadorTurnos);
      final datos = snap.data();
      final mismaFecha = datos != null && datos['fecha'] == hoy;
      final nuevoNumero = mismaFecha ? ((datos['ultimo'] as num?)?.toInt() ?? 0) + 1 : 1;
      tx.set(_docContadorTurnos, {'fecha': hoy, 'ultimo': nuevoNumero});
      tx.set(pedidoRef, armar(nuevoNumero).aCampos());
      return nuevoNumero;
    });

    _carrito.clear();
    notifyListeners();

    return armar(numero);
  }

  /// Le pide al servidor (functions/index.js) el link de pago de Mercado
  /// Pago para un pedido ya creado. El servidor recalcula el total con los
  /// precios de Firestore. Devuelve la URL a abrir.
  Future<String> crearPagoMercadoPago(String pedidoId) async {
    // Sin tipo genérico: en Android la respuesta llega como Map<Object?, Object?>
    // y forzarla a Map<String, dynamic> rompería en tiempo de ejecución.
    final resultado = await _functions
        .httpsCallable('crearPagoMercadoPago')
        .call({'pedidoId': pedidoId, 'origen': 'app'});
    final datos = resultado.data;
    final url = datos is Map ? datos['initPoint'] : null;
    if (url is! String || url.isEmpty) throw StateError('Mercado Pago no devolvió el link');
    return url;
  }

  /// Sigue en vivo un pedido puntual (para ver cuándo se acredita el pago).
  Stream<Pedido?> escucharPedido(String pedidoId) => _colPedidos
      .doc(pedidoId)
      .snapshots()
      .map((d) => d.exists ? Pedido.deDocumento(d) : null);

  Future<void> calificarPedido(Pedido pedido, int estrellas, String? comentario) async {
    final c = comentario?.trim();
    final comentarioFinal = (c == null || c.isEmpty) ? null : c;
    await _colPedidos.doc(pedido.id).update({
      'calificacion': estrellas,
      'comentario': comentarioFinal,
    });
    pedido.calificacion = estrellas;
    pedido.comentario = comentarioFinal;
    notifyListeners();
  }
}
