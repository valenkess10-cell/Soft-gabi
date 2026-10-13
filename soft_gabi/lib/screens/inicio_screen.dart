import 'package:flutter/material.dart';

import '../data/catalogo.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../widgets/producto_card.dart';
import 'auth_screen.dart';

class InicioScreen extends StatelessWidget {
  final VoidCallback onVerMenu;

  const InicioScreen({super.key, required this.onVerMenu});

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---------------------------------------------------------- hero
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/images/pollo.jpg', fit: BoxFit.cover, cacheWidth: 800),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF020617).withValues(alpha: 0.95),
                        const Color(0xFF020617).withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.amarillo.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.amarillo.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✨ Menú del día disponible',
                        style: TextStyle(
                          color: Color(0xFFFCD34D),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Comida rica,',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const Text(
                      'siempre fresca.',
                      style: TextStyle(
                        color: AppColors.amarillo,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pedí desde acá y retirá sin filas.',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          onPressed: () {
                            cantina.seleccionarCategoria('todos');
                            onVerMenu();
                          },
                          child: const Text('Ver Menú Completo →'),
                        ),
                        if (cantina.usuario == null)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => AuthScreen.mostrar(context, registro: true),
                            child: const Text('Crear Cuenta Gratis'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ----------------------------------------------------- categorías
        const Text('Categorías', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categorias.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = categorias[i];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  cantina.seleccionarCategoria(c.id);
                  onVerMenu();
                },
                child: Container(
                  width: 88,
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.10),
                    border: Border.all(color: c.color.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.icono, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        c.nombre,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),

        // ------------------------------------------------------ destacados
        Row(
          children: [
            const Expanded(
              child: Text(
                '⭐ Destacados del día',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            TextButton(
              onPressed: () {
                cantina.seleccionarCategoria('todos');
                onVerMenu();
              },
              child: const Text('Ver todos →'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final p in cantina.destacados) ProductoCard(producto: p),
      ],
    );
  }
}
