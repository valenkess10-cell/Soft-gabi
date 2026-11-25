import 'package:flutter/material.dart';

import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';

/// Anotador de la vendedora: notas y pendientes guardados en Firestore
/// (colección `notas`), así se ven igual en la app y en la web.
class AnotadorScreen extends StatefulWidget {
  const AnotadorScreen({super.key});

  @override
  State<AnotadorScreen> createState() => _AnotadorScreenState();
}

class _AnotadorScreenState extends State<AnotadorScreen> {
  final _texto = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _agregar() async {
    if (_texto.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    final error = await CantinaScope.read(context).agregarNota(_texto.text);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      _texto.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);
    if (!cantina.puedeVerVentas) {
      return const Scaffold(body: Center(child: Text('🔒 Acceso exclusivo para la vendedora')));
    }
    final notas = [
      ...cantina.notas.where((n) => !n.hecha),
      ...cantina.notas.where((n) => n.hecha),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('📝 Anotador')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _texto,
                    maxLength: 300,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ej: comprar pan, avisar que faltan Coca-Cola…',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _agregar(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _guardando ? null : _agregar,
                  child: const Text('Anotar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: notas.isEmpty
                ? const Center(
                    child: Text('Sin notas por ahora.',
                        style: TextStyle(color: AppColors.gris, fontWeight: FontWeight.w700)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    itemCount: notas.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = notas[i];
                      return ListTile(
                        key: ValueKey(n.id),
                        leading: Checkbox(
                          value: n.hecha,
                          onChanged: (v) => cantina.marcarNota(n, v ?? false),
                        ),
                        title: Text(
                          n.texto,
                          style: TextStyle(
                            decoration: n.hecha ? TextDecoration.lineThrough : null,
                            color: n.hecha ? AppColors.gris : AppColors.texto,
                          ),
                        ),
                        subtitle: Text('${n.autor} · ${fechaHora(n.fecha)}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          tooltip: 'Borrar nota',
                          icon: const Icon(Icons.delete_outline, color: AppColors.rojo),
                          onPressed: () => cantina.eliminarNota(n),
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
