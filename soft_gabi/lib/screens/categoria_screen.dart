import 'package:flutter/material.dart';

import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../widgets/producto_card.dart';

/// Pantalla simple para una sección fija del menú (Desayuno, Bebidas, etc.):
/// lista directamente los productos de esa categoría, sin depender del
/// filtro de la pestaña Menú.
class CategoriaScreen extends StatelessWidget {
  final String categoriaId;
  final String titulo;
  final String subtitulo;
  final String icono;

  const CategoriaScreen({
    super.key,
    required this.categoriaId,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);
    final lista = cantina.todosLosProductos.where((p) => p.categoria == categoriaId).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            children: [
              Text(
                '$icono $titulo',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: const TextStyle(fontSize: 12, color: AppColors.gris),
              ),
            ],
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icono, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      const Text(
                        'No hay productos en esta categoría todavía.',
                        style: TextStyle(color: AppColors.gris, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: lista.length,
                  itemBuilder: (context, i) => ProductoCard(producto: lista[i]),
                ),
        ),
      ],
    );
  }
}
