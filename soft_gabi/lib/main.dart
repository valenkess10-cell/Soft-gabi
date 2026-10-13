import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'providers/cantina_provider.dart';
import 'providers/cantina_scope.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // En Android, el plugin de Google Services ya inicializa Firebase solo
    // (lee google-services.json antes de que arranque Flutter). Si acá lo
    // volvemos a inicializar sin chequear, choca contra esa inicialización
    // nativa y tira "[core/duplicate-app] A Firebase App named [DEFAULT]
    // already exists". Por eso solo lo hacemos si todavía no existe.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    final provider = CantinaProvider();
    await provider.cargar(); // conecta con Firebase y resuelve la sesión actual
    runApp(MiCantinaApp(provider: provider));
  } catch (error, stack) {
    // Si algo falla acá (Firebase mal configurado, sin conexión la primera
    // vez, etc.) la app NO puede quedarse en una pantalla negra sin avisar:
    // mostramos el motivo para poder diagnosticarlo.
    debugPrint('Error al iniciar la app: $error\n$stack');
    runApp(_AppDeError(error: error));
  }
}

class _AppDeError extends StatelessWidget {
  final Object error;

  const _AppDeError({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF5F5),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo iniciar MiCantina',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mandale esta pantalla a quien te ayuda con la app:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      '$error',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MiCantinaApp extends StatelessWidget {
  final CantinaProvider provider;

  const MiCantinaApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    // El CantinaScope va ARRIBA del MaterialApp: así las pantallas, los
    // bottom sheets y los diálogos comparten el mismo estado y siempre tienen
    // un Navigator disponible.
    return CantinaScope(
      provider: provider,
      child: MaterialApp(
        title: 'MiCantina',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
