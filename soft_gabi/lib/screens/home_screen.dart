import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import 'auth_screen.dart';
import 'carrito_screen.dart';
import 'catalogo_screen.dart';
import 'categoria_screen.dart';
import 'inicio_screen.dart';
import 'ventas_screen.dart';

enum Seccion { inicio, menu, desayuno, bebidas, ventas }

/// Pantalla principal: barra superior (logo, cuenta, carrito) + navegación inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Seccion _seccion = Seccion.inicio;

  void _ir(Seccion s) => setState(() => _seccion = s);

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);

    // "Ventas" solo existe para la vendedora y para el login master.
    final visibles = <Seccion>[
      Seccion.inicio,
      Seccion.menu,
      Seccion.desayuno,
      Seccion.bebidas,
      if (cantina.puedeVerVentas) Seccion.ventas,
    ];
    // Si cierran sesión estando en Ventas, volvemos a Inicio.
    if (!visibles.contains(_seccion)) _seccion = Seccion.inicio;

    final cantidad = cantina.cantidadTotal;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo-micantina.png', height: 36),
        actions: [
          _BotonCuenta(onIngresar: () => AuthScreen.mostrar(context)),
          IconButton(
            tooltip: 'Mi pedido',
            onPressed: () => abrirCarrito(context),
            icon: Badge(
              isLabelVisible: cantidad > 0,
              label: Text('$cantidad'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: switch (_seccion) {
        Seccion.inicio => InicioScreen(onVerMenu: () => _ir(Seccion.menu)),
        Seccion.menu => const CatalogoScreen(),
        Seccion.desayuno => const CategoriaScreen(
            categoriaId: 'desayuno',
            titulo: 'Desayuno y Merienda',
            subtitulo: 'Para el recreo o la merienda.',
            icono: '🥐',
          ),
        Seccion.bebidas => const CategoriaScreen(
            categoriaId: 'bebidas',
            titulo: 'Bebidas',
            subtitulo: 'Bien frías, para acompañar.',
            icono: '🥤',
          ),
        Seccion.ventas => const VentasScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: visibles.indexOf(_seccion),
        onDestinationSelected: (i) => _ir(visibles[i]),
        destinations: [
          for (final s in visibles)
            switch (s) {
              Seccion.inicio => const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Inicio',
                ),
              Seccion.menu => const NavigationDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu),
                  label: 'Menú',
                ),
              Seccion.desayuno => const NavigationDestination(
                  icon: Icon(Icons.bakery_dining_outlined),
                  selectedIcon: Icon(Icons.bakery_dining),
                  label: 'Desayuno',
                ),
              Seccion.bebidas => const NavigationDestination(
                  icon: Icon(Icons.local_drink_outlined),
                  selectedIcon: Icon(Icons.local_drink),
                  label: 'Bebidas',
                ),
              Seccion.ventas => const NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Ventas',
                ),
            },
        ],
      ),
    );
  }
}

class _BotonCuenta extends StatelessWidget {
  final VoidCallback onIngresar;

  const _BotonCuenta({required this.onIngresar});

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);
    final usuario = cantina.usuario;

    if (usuario == null) {
      return TextButton.icon(
        onPressed: onIngresar,
        icon: const Icon(Icons.person_outline, size: 20),
        label: const Text('Ingresar'),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Cuenta',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (v) {
        if (v == 'salir') cantina.cerrarSesion();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            '${usuario.nombre}\n${_etiquetaRol(usuario)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'salir', child: Text('Cerrar sesión')),
      ],
    );
  }

  String _etiquetaRol(Usuario usuario) {
    if (usuario.rol == 'master') return 'Administrador';
    if (usuario.esVendedora) return 'Vendedora';
    return usuario.email;
  }
}
