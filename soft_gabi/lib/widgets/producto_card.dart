import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;

  const ProductoCard({super.key, required this.producto});

  void _agregar(BuildContext context) {
    CantinaScope.read(context).agregarAlCarrito(producto);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${producto.nombre} agregado al pedido'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    producto.imagenBase64 != null
                        ? Image.memory(base64Decode(producto.imagenBase64!), fit: BoxFit.cover)
                        : producto.imagen != null
                            ? Image.asset(producto.imagen!, fit: BoxFit.cover, cacheWidth: 300)
                            : ColoredBox(
                                color: Colors.grey.shade100,
                                child: Center(
                                  child:
                                      Text(producto.emoji, style: const TextStyle(fontSize: 40)),
                                ),
                              ),
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          producto.tag,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.esSinTacc
                        ? '${producto.categoriaLabel.toUpperCase()}  ·  🌾 SIN TACC'
                        : producto.categoriaLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gris,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    producto.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.gris),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pesos(producto.precio),
                              style: const TextStyle(
                                color: AppColors.rojo,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            // El tiempo de preparación solo tiene sentido para la
                            // comida del almuerzo (se cocina al pedido). Para los
                            // productos de kiosco (desayuno/merienda y bebidas) no
                            // se muestra: es instantáneo, no tiene "preparación".
                            if (producto.esComidaDeAlmuerzo)
                              Text(
                                '⏱ ${producto.tiempo} min',
                                style: const TextStyle(fontSize: 11, color: AppColors.gris),
                              ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Agregar al pedido',
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
