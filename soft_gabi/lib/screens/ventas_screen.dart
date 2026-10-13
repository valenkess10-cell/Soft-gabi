import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';
import 'productos_admin_screen.dart';

/// Panel de Ventas: lo ve la vendedora y la cuenta master.
class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  Widget _estadistica(String titulo, String valor, {Color? color}) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gris)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(valor,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);

    // Doble control: aunque alguien llegue acá por error, no se muestran datos.
    if (!cantina.puedeVerVentas) {
      return const Center(child: Text('🔒 Acceso exclusivo para la vendedora'));
    }

    final pedidos = cantina.pedidos;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        cantina.esMaster ? '🔒 Acceso exclusivo · Administración' : '🔒 Acceso exclusivo · Vendedora',
                        style: const TextStyle(
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w800,
                            fontSize: 11)),
                    const SizedBox(height: 6),
                    const Text('Panel de Ventas',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Todos los pedidos con el detalle para prepararlos y entregarlos.',
                        style: TextStyle(fontSize: 12, color: AppColors.gris)),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Text('📋', style: TextStyle(fontSize: 40)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: AppColors.amarillo.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.amarillo.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductosAdminScreen()),
            ),
            leading: const Icon(Icons.inventory_2_outlined, color: AppColors.texto),
            title: const Text('Mis productos', style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: const Text('Agregá, editá o eliminá productos del catálogo',
                style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _estadistica('Pedidos totales', '${pedidos.length}'),
            const SizedBox(width: 8),
            _estadistica('Pedidos de hoy', '${cantina.pedidosHoy}'),
            const SizedBox(width: 8),
            _estadistica('Recaudado', pesos(cantina.totalRecaudado), color: AppColors.rojo),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Pedidos recibidos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const Text('Los más recientes primero',
            style: TextStyle(fontSize: 11, color: AppColors.gris)),
        const SizedBox(height: 10),
        if (pedidos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Text('🧺', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text('Todavía no recibiste ningún pedido.',
                      style: TextStyle(color: AppColors.gris, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          )
        else
          for (final p in pedidos) _PedidoTile(pedido: p),
        if (cantina.esMaster) ...[
          const SizedBox(height: 24),
          const Text('Usuarios registrados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const Text('Solo la cuenta master ve esta lista',
              style: TextStyle(fontSize: 11, color: AppColors.gris)),
          const SizedBox(height: 10),
          _ListaUsuarios(usuarios: cantina.usuariosRegistrados),
        ],
      ],
    );
  }
}

class _ListaUsuarios extends StatelessWidget {
  final List<Usuario> usuarios;

  const _ListaUsuarios({required this.usuarios});

  @override
  Widget build(BuildContext context) {
    if (usuarios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          'Todavía nadie se registró en la app.',
          style: TextStyle(color: AppColors.gris, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          for (var i = 0; i < usuarios.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _UsuarioTile(usuario: usuarios[i]),
          ],
        ],
      ),
    );
  }
}

class _UsuarioTile extends StatelessWidget {
  final Usuario usuario;

  const _UsuarioTile({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final esVendedora = usuario.esVendedora;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: esVendedora
            ? AppColors.amarillo.withValues(alpha: 0.25)
            : AppColors.rojo.withValues(alpha: 0.10),
        child: Text(
          usuario.nombre.isEmpty ? '?' : usuario.nombre[0].toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      title: Text(usuario.nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(usuario.email, style: const TextStyle(fontSize: 12)),
      trailing: esVendedora
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.amarillo.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Vendedora',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
            )
          : null,
    );
  }
}

class _PedidoTile extends StatelessWidget {
  final Pedido pedido;

  const _PedidoTile({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.texto,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text('TURNO',
                      style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w700)),
                  Text(turno(pedido.numero),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pedido.cliente,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  Text(fechaHora(pedido.fecha),
                      style: const TextStyle(fontSize: 11, color: AppColors.gris)),
                  const SizedBox(height: 6),
                  for (final it in pedido.items)
                    Text('${it.cantidad}x ${it.nombre}', style: const TextStyle(fontSize: 12)),
                  if (pedido.calificacion != null) ...[
                    const SizedBox(height: 6),
                    Text('⭐' * pedido.calificacion!, style: const TextStyle(fontSize: 12)),
                    if (pedido.comentario != null)
                      Text('“${pedido.comentario}”',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(pesos(pedido.total),
                    style: const TextStyle(
                        color: AppColors.rojo, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.fondo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    switch (pedido.metodoPago) {
                      'transferencia' => '🏦 Transf.',
                      'mercadopago' => '💙 MP',
                      'tarjeta' => '💳 Tarjeta',
                      _ => '💵 Efectivo',
                    },
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
