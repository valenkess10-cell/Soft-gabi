import 'package:flutter/material.dart';
import '../providers/cantina_provider.dart';

class CatalogoScreen extends StatefulWidget {
  final CantinaProvider provider;
  final VoidCallback alAbrirCarrito;

  const CatalogoScreen({
    super.key,
    required this.provider,
    required this.alAbrirCarrito,
  });

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  int _pestanaActiva = 0;

  @override
  Widget build(BuildContext context) {
    final listaProductos = _pestanaActiva == 0
        ? widget.provider.productos
        : widget.provider.productosSinTacc;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🍿 MICANTINA',
          style: TextStyle(fontWeight: FontWeight.black, color: Color(0xFFDC2626)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black87),
                onPressed: widget.alAbrirCarrito,
              ),
              if (widget.provider.cantidadTotal > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: const Color(0xFFDC2626),
                    child: Text(
                      '${widget.provider.cantidadTotal}',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Menú Completo'),
                  selected: _pestanaActiva == 0,
                  onSelected: (_) => setState(() => _pestanaActiva = 0),
                  selectedColor: const Color(0xFFDC2626).withOpacity(0.15),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('🌾 Sin TACC'),
                  selected: _pestanaActiva == 1,
                  onSelected: (_) => setState(() => _pestanaActiva = 1),
                  selectedColor: const Color(0xFF059669).withOpacity(0.15),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listaProductos.length,
              itemBuilder: (context, index) {
                final prod = listaProductos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prod.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('\$${prod.precio.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.black)),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => widget.provider.agregarAlCarrito(prod),
                          icon: const Icon(Icons.add),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}