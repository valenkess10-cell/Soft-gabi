import 'package:flutter/material.dart';

import '../data/catalogo.dart';
import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../widgets/combo_card.dart';
import '../widgets/producto_card.dart';

/// Menú completo con filtro por categoría (incluye "Sin TACC").
class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);
    final lista = cantina.productosFiltrados;
    // En "Todos" los combos van arriba de los productos.
    final combos = cantina.categoriaActiva == 'todos' ? cantina.combosVisibles : const <DetalleCombo>[];
    final opciones = [categoriaTodos, ...categorias];

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            children: [
              Text(
                '¿Qué querés comer hoy?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 2),
              Text(
                'Elegí tu categoría favorita y hacé tu pedido.',
                style: TextStyle(fontSize: 12, color: AppColors.gris),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: opciones.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final c = opciones[i];
              final activa = cantina.categoriaActiva == c.id;
              return ChoiceChip(
                label: Text('${c.icono} ${c.nombre}'),
                selected: activa,
                showCheckmark: false,
                selectedColor: c.id == 'sin-tacc'
                    ? AppColors.verde.withValues(alpha: 0.18)
                    : AppColors.rojo.withValues(alpha: 0.15),
                onSelected: (_) => cantina.seleccionarCategoria(c.id),
              );
            },
          ),
        ),
        Expanded(
          child: lista.isEmpty && combos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🍽️', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text(
                        'No hay productos en esta categoría todavía.',
                        style: TextStyle(color: AppColors.gris, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: combos.length + lista.length,
                  itemBuilder: (context, i) => i < combos.length
                      ? ComboCard(detalle: combos[i])
                      : ProductoCard(producto: lista[i - combos.length]),
                ),
        ),
      ],
    );
  }
}
