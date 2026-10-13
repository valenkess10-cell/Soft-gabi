import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soft_gabi/data/catalogo.dart';
import 'package:soft_gabi/main.dart';
import 'package:soft_gabi/providers/cantina_provider.dart';

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

      c.decrementarCantidad(pizza);
      expect(c.cantidadTotal, 1);
      c.decrementarCantidad(pizza);
      expect(c.carrito, isEmpty);
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

      final pedido = await c.confirmarPago('efectivo');

      expect(pedido.numero, 1);
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
