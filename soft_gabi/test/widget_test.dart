import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soft_gabi/data/catalogo.dart';
import 'package:soft_gabi/main.dart';
import 'package:soft_gabi/models/producto.dart';
import 'package:soft_gabi/providers/cantina_provider.dart';
import 'package:soft_gabi/utils/pedidos_util.dart';

/// Arma un provider "de prueba": en vez de conectarse a un proyecto de
/// Firebase real, usa una base y una autenticación simuladas en memoria
/// (fake_cloud_firestore / firebase_auth_mocks).
CantinaProvider nuevoProvider() => CantinaProvider(
      auth: MockFirebaseAuth(),
      db: FakeFirebaseFirestore(),
    );

void main() {
  group('CantinaProvider', () {
    test('carrito suma, resta y calcula el total', () {
      final c = nuevoProvider();
      final pizza = productos.first;

      c.agregarAlCarrito(pizza);
      c.agregarAlCarrito(pizza);
      expect(c.cantidadTotal, 2);
      expect(c.totalCarrito, pizza.precio * 2);

      c.decrementarCantidad(c.carrito.first);
      expect(c.cantidadTotal, 1);
      c.decrementarCantidad(c.carrito.first);
      expect(c.carrito, isEmpty);
    });

    test('las opciones suman precio y separan líneas del carrito', () {
      final c = nuevoProvider();
      const queso = OpcionProducto(id: 'q', nombre: 'Extra queso', precio: 500);
      const cebolla = OpcionProducto(id: 'c', nombre: 'Sin cebolla');
      final pizza = Producto(
        id: 'p',
        nombre: 'Pizza',
        descripcion: '',
        precio: 3000,
        tag: '',
        tiempo: 10,
        categoria: 'pizzas',
        categoriaLabel: 'Pizzas',
        opciones: const [queso, cebolla],
      );

      c.agregarAlCarrito(pizza, opciones: [queso]);
      c.agregarAlCarrito(pizza, opciones: [queso]); // misma combinación: suma
      c.agregarAlCarrito(pizza, opciones: [cebolla], nota: 'bien cocida');
      expect(c.carrito.length, 2);
      expect(c.totalCarrito, 3500 * 2 + 3000);
      expect(c.carrito.last.nota, 'bien cocida');
    });

    test('un combo usa su precio especial y detalla sus productos', () {
      final c = nuevoProvider();
      final combo = Combo(
        id: 'c1',
        nombre: 'Pizza + Coca',
        precio: 4000,
        items: [
          ItemCombo(productoId: productos.first.id, nombre: productos.first.nombre),
          const ItemCombo(productoId: '28', nombre: 'Coca-Cola'),
        ],
      );
      final detalle = DetalleCombo.calcular(combo, productos);
      expect(detalle.disponible, isTrue);
      expect(detalle.precioNormal, productos.first.precio + 1800);
      expect(detalle.ahorro, detalle.precioNormal - 4000);

      c.agregarComboAlCarrito(detalle);
      expect(c.totalCarrito, 4000);
      expect(c.carrito.first.aItemPedido().detalle, hasLength(2));
    });

    test('los horarios de retiro respetan la anticipación y el cierre', () {
      expect(horariosDeRetiro(DateTime(2026, 1, 1, 10, 0)).first, '10:30');
      expect(horariosDeRetiro(DateTime(2026, 1, 1, 6, 0)).first, horaRetiroDesde);
      expect(horariosDeRetiro(DateTime(2026, 1, 1, 17, 50)), isEmpty);
    });

    test('los pedidos viejos de la web se leen con el id del método de pago', () {
      expect(normalizarMetodoPago('Efectivo en caja'), 'efectivo');
      expect(normalizarMetodoPago('Transferencia bancaria'), 'transferencia');
      expect(normalizarMetodoPago('Tarjeta en caja'), 'tarjeta');
      expect(normalizarMetodoPago('mercadopago'), 'mercadopago');
    });

    test('el filtro Sin TACC solo devuelve productos aptos', () {
      final c = nuevoProvider()..seleccionarCategoria('sin-tacc');
      expect(c.productosFiltrados, isNotEmpty);
      expect(c.productosFiltrados.every((p) => p.esSinTacc), isTrue);
    });

    test('Desayuno/Merienda y Bebidas filtran bien y no tienen foto propia', () {
      final c = nuevoProvider();

      c.seleccionarCategoria('desayuno');
      expect(c.productosFiltrados, isNotEmpty);
      expect(c.productosFiltrados.every((p) => p.categoria == 'desayuno'), isTrue);
      expect(c.productosFiltrados.every((p) => p.imagen == null), isTrue);

      c.seleccionarCategoria('bebidas');
      expect(c.productosFiltrados, isNotEmpty);
      expect(c.productosFiltrados.any((p) => p.nombre == 'Coca-Cola'), isTrue);
    });

    test('confirmarPago guarda el pedido en Firestore y devuelve SU turno', () async {
      final c = nuevoProvider();
      await c.cargar(); // entra como invitado (sign-in anónimo), como en la app real
      c.agregarAlCarrito(productos.first);

      final pedido = await c.confirmarPago('efectivo', horaRetiro: '12:30', pagaCon: 5000);

      expect(pedido.numero, 1);
      expect(pedido.horaRetiro, '12:30');
      expect(pedido.vuelto, 5000 - productos.first.precio);
      expect(pedido.cliente, 'Invitado');
      expect(c.carrito, isEmpty);

      // El segundo pedido del día tiene que sacar el turno siguiente.
      c.agregarAlCarrito(productos.first);
      final segundo = await c.confirmarPago('tarjeta');
      expect(segundo.numero, 2);
    });

    test('tarjeta y Mercado Pago se guardan y se muestran con su nombre', () async {
      final c = nuevoProvider();
      await c.cargar();
      c.agregarAlCarrito(productos.first);
      final pedido = await c.confirmarPago('mercadopago');
      expect(pedido.metodoPagoLabel, 'Mercado Pago');
      // Mercado Pago queda pendiente hasta que el servidor confirma el pago.
      expect(pedido.estadoPago, 'pendiente');
      expect(pedido.cuentaComoCobrado, isFalse);

      c.agregarAlCarrito(productos.first);
      final pedido2 = await c.confirmarPago('tarjeta');
      expect(pedido2.metodoPagoLabel, 'Tarjeta de crédito/débito');
    });

    test('registro y login de un cliente', () async {
      final c = nuevoProvider();
      await c.cargar();

      expect(await c.registrar(nombre: 'Ana', email: 'ana@mail.com', password: '123456'), isNull);
      await Future<void>.delayed(Duration.zero); // deja propagar authStateChanges
      expect(c.usuario?.nombre, 'Ana');
      expect(c.esVendedora, isFalse);
      expect(c.esMaster, isFalse);

      expect(
        await c.registrar(nombre: 'Otra', email: 'ana@mail.com', password: 'abcdef'),
        'El email ya está registrado',
      );

      await c.cerrarSesion();
      await Future<void>.delayed(Duration.zero);
      expect(c.usuario, isNull);

      expect(await c.iniciarSesion(email: 'ana@mail.com', password: '123456'), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(c.usuario?.nombre, 'Ana');
    });

    test('nadie puede registrarse con el email de vendedora o master', () async {
      final c = nuevoProvider();
      await c.cargar();

      expect(
        await c.registrar(nombre: 'x', email: CantinaProvider.emailVendedora, password: '123456'),
        'Ese email está reservado',
      );
      expect(
        await c.registrar(nombre: 'x', email: CantinaProvider.emailMaster, password: '123456'),
        'Ese email está reservado',
      );
    });

    test('la vendedora entra con su cuenta fija sin necesidad de registrarse', () async {
      final c = nuevoProvider();
      await c.cargar();

      expect(
        await c.iniciarSesion(email: CantinaProvider.emailVendedora, password: 'mal'),
        'Email o contraseña incorrectos',
      );
      expect(
        await c.iniciarSesion(email: 'VENDEDORA@micantina.com', password: 'Vendedora2026'),
        isNull,
      );
      await Future<void>.delayed(Duration.zero);
      expect(c.esVendedora, isTrue);
      expect(c.puedeVerVentas, isTrue);
      expect(c.esMaster, isFalse);
    });

    test('la cuenta master ve el panel de ventas y la lista de usuarios', () async {
      final c = nuevoProvider();
      await c.cargar();
      await c.registrar(nombre: 'Ana', email: 'ana@mail.com', password: '123456');
      await c.cerrarSesion();
      await Future<void>.delayed(Duration.zero);

      expect(
        await c.iniciarSesion(email: CantinaProvider.emailMaster, password: 'Cantina2026'),
        isNull,
      );
      await Future<void>.delayed(Duration.zero);

      expect(c.esMaster, isTrue);
      expect(c.puedeVerVentas, isTrue);
      expect(c.usuariosRegistrados.any((u) => u.email == 'ana@mail.com'), isTrue);
    });
  });

  testWidgets('la app abre en Inicio y se puede agregar un producto', (tester) async {
    await tester.pumpWidget(MiCantinaApp(provider: nuevoProvider()));
    await tester.pump();

    expect(find.text('Comida rica,'), findsOneWidget);
    expect(find.text('Menú'), findsOneWidget); // barra de navegación inferior

    await tester.tap(find.byTooltip('Agregar al pedido').first);
    await tester.pump();
    expect(find.text('1'), findsWidgets); // badge del carrito
  });
}
