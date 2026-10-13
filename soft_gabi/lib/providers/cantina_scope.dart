import 'package:flutter/widgets.dart';
import 'cantina_provider.dart';

/// Reparte el [CantinaProvider] a toda la app (sin depender de paquetes extra).
///
/// - [of]: para usar dentro de `build`. El widget se reconstruye solo cuando
///   cambia el carrito, la sesión, los pedidos, etc.
/// - [read]: para usar dentro de botones/callbacks (no se suscribe a cambios).
class CantinaScope extends InheritedNotifier<CantinaProvider> {
  const CantinaScope({
    super.key,
    required CantinaProvider provider,
    required Widget child,
  }) : super(notifier: provider, child: child);

  static CantinaProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CantinaScope>();
    assert(scope != null, 'Falta un CantinaScope arriba en el árbol de widgets');
    return scope!.notifier!;
  }

  static CantinaProvider read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<CantinaScope>();
    assert(scope != null, 'Falta un CantinaScope arriba en el árbol de widgets');
    return scope!.notifier!;
  }
}
