import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';

/// Tarjeta de un combo armado por la vendedora.
class ComboCard extends StatelessWidget {
  final DetalleCombo detalle;

  const ComboCard({super.key, required this.detalle});

  void _agregar(BuildContext context) {
    CantinaScope.read(context).agregarComboAlCarrito(detalle);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${detalle.combo.nombre} agregado al pedido'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final combo = detalle.combo;
    final foto = combo.bytesFoto;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.amarillo.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100,
                height: 100,
                child: foto != null
                    ? Image.memory(foto, fit: BoxFit.cover)
                    : ColoredBox(
                        color: AppColors.amarillo.withValues(alpha: 0.15),
                        child: const Center(child: Text('🍱', style: TextStyle(fontSize: 40))),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Chip(texto: 'COMBO', fondo: AppColors.amarillo),
                      if (detalle.ahorro > 0)
                        _Chip(
                          texto: 'Ahorrás ${pesos(detalle.ahorro)}',
                          fondo: AppColors.verde,
                          colorTexto: Colors.white,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(combo.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    detalle.descripcionItems.join(' + '),
                    style: const TextStyle(fontSize: 12, color: AppColors.gris),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (detalle.ahorro > 0)
                              Text(
                                pesos(detalle.precioNormal),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gris,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              pesos(combo.precio),
                              style: const TextStyle(
                                color: AppColors.rojo,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            if (detalle.calorias != null)
                              Text(
                                '🔥 ${detalle.calorias} kcal',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFC2410C),
                                    fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Agregar combo',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.amarillo,
                          foregroundColor: AppColors.texto,
                        ),
                        onPressed: () => _agregar(context),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color colorTexto;

  const _Chip({required this.texto, required this.fondo, this.colorTexto = AppColors.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(20)),
      child: Text(texto,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: colorTexto)),
    );
  }
}
