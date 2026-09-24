import 'package:flutter/material.dart';
import 'providers/cantina_provider.dart';
import 'screens/catalogo_screen.dart';
import 'screens/carrito_screen.dart';
import 'screens/ticket_screen.dart';
import 'screens/posventa_screen.dart';

void main() {
  runApp(const MiCantinaApp());
}

class MiCantinaApp extends StatefulWidget {
  const MiCantinaApp({super.key});

  @override
  State<MiCantinaApp> createState() => _MiCantinaAppState();
}

class _MiCantinaAppState extends State<MiCantinaApp> {
  final CantinaProvider _provider = CantinaProvider();

  @override
  void initState() {
    super.initState();
    _provider.addListener(() => setState(() {}));
  }

  void _abrirCarrito(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => CarritoScreen(
        provider: _provider,
        alConfirmarPago: () {
          Navigator.pop(ctx);
          _provider.confirmarPago();
          _mostrarTicket(context);
        },
      ),
    );
  }

  void _mostrarTicket(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => TicketScreen(
        numeroTurno: _provider.numeroTurno,
        alIrAPosventa: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => PosventaScreen(numeroTurno: _provider.numeroTurno),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiCantina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: CatalogoScreen(
        provider: _provider,
        alAbrirCarrito: () => _abrirCarrito(context),
      ),
    );
  }
}