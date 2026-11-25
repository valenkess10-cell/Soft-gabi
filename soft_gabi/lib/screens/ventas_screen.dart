import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../providers/cantina_scope.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../utils/pedidos_util.dart';
import 'anotador_screen.dart';
import 'combos_admin_screen.dart';
import 'productos_admin_screen.dart';

/// Panel de Ventas: lo ve la vendedora y la cuenta master.
class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

enum _FiltroFecha { hoy, ayer, semana, todo, rango }

class _VentasScreenState extends State<VentasScreen> {
  _FiltroFecha _fecha = _FiltroFecha.hoy;
  DateTimeRange? _rango;
  String _metodo = 'todos';
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  static DateTime _inicioDelDia(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [desde, hasta) del filtro de fecha; null = sin límite.
  (DateTime?, DateTime?) get _limites {
    final hoy = _inicioDelDia(DateTime.now());
    return switch (_fecha) {
      _FiltroFecha.hoy => (hoy, hoy.add(const Duration(days: 1))),
      _FiltroFecha.ayer => (hoy.subtract(const Duration(days: 1)), hoy),
      _FiltroFecha.semana => (hoy.subtract(const Duration(days: 6)), hoy.add(const Duration(days: 1))),
      _FiltroFecha.rango => (
          _rango == null ? null : _inicioDelDia(_rango!.start),
          _rango == null ? null : _inicioDelDia(_rango!.end).add(const Duration(days: 1)),
        ),
      _FiltroFecha.todo => (null, null),
    };
  }

  List<Pedido> _filtrar(List<Pedido> pedidos) {
    final (desde, hasta) = _limites;
    final q = _busqueda.text.trim().toLowerCase().replaceFirst('#', '');
    final numeroBuscado = int.tryParse(q);
    return pedidos.where((p) {
      if (desde != null && p.fecha.isBefore(desde)) return false;
      if (hasta != null && !p.fecha.isBefore(hasta)) return false;
      if (_metodo != 'todos' && p.metodoPago != _metodo) return false;
      if (q.isNotEmpty) {
        final porNumero = numeroBuscado != null && p.numero == numeroBuscado;
        final porNombre = p.cliente.toLowerCase().contains(q);
        if (!porNumero && !porNombre) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _elegirRango() async {
    final ahora = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ahora.year - 2),
      lastDate: ahora,
      initialDateRange: _rango,
    );
    if (rango == null) return;
    setState(() {
      _rango = rango;
      _fecha = _FiltroFecha.rango;
    });
  }

  String _nombreFiltro(_FiltroFecha f) => switch (f) {
        _FiltroFecha.hoy => 'Hoy',
        _FiltroFecha.ayer => 'Ayer',
        _FiltroFecha.semana => 'Últimos 7 días',
        _FiltroFecha.todo => 'Todo',
        _FiltroFecha.rango => _rango == null
            ? 'Elegir fechas'
            : '${_dm(_rango!.start)} – ${_dm(_rango!.end)}',
      };

  static String _dm(DateTime d) => '${d.day}/${d.month}';

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

  Widget _accesoPanel({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required Widget destino,
    Widget? trailing,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: AppColors.amarillo.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.amarillo.withValues(alpha: 0.5)),
        ),
        child: ListTile(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino)),
          leading: Icon(icono, color: AppColors.texto),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12)),
          trailing: trailing ?? const Icon(Icons.chevron_right),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cantina = CantinaScope.of(context);

    // Doble control: aunque alguien llegue acá por error, no se muestran datos.
    if (!cantina.puedeVerVentas) {
      return const Center(child: Text('🔒 Acceso exclusivo para la vendedora'));
    }

    final pedidos = _filtrar(cantina.pedidos);
    final recaudado =
        pedidos.where((p) => p.cuentaComoCobrado).fold<int>(0, (s, p) => s + p.total);
    final notasPendientes = cantina.notas.where((n) => !n.hecha).length;

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
              const SizedBox(width: 12),
              const Text('📋', style: TextStyle(fontSize: 40)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _accesoPanel(
          icono: Icons.inventory_2_outlined,
          titulo: 'Mis productos',
          subtitulo: 'Agregá, editá o eliminá productos del catálogo',
          destino: const ProductosAdminScreen(),
        ),
        _accesoPanel(
          icono: Icons.lunch_dining_outlined,
          titulo: 'Mis combos',
          subtitulo: 'Armá combos con precio especial',
          destino: const CombosAdminScreen(),
        ),
        _accesoPanel(
          icono: Icons.edit_note,
          titulo: 'Anotador',
          subtitulo: 'Tus notas y pendientes',
          destino: const AnotadorScreen(),
          trailing: notasPendientes > 0
              ? Badge(label: Text('$notasPendientes'), child: const Icon(Icons.chevron_right))
              : null,
        ),
        const SizedBox(height: 8),

        // --------------------------------------------------------- filtros
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in _FiltroFecha.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_nombreFiltro(f)),
                    selected: _fecha == f,
                    showCheckmark: false,
                    onSelected: (_) {
                      if (f == _FiltroFecha.rango) {
                        _elegirRango();
                      } else {
                        setState(() => _fecha = f);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _busqueda,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Cliente o nº de turno',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _busqueda.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(_busqueda.clear),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _metodo,
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(value: 'todos', child: Text('Todos los pagos')),
                for (final id in metodosPagoIds)
                  DropdownMenuItem(value: id, child: Text(nombreMetodoPago(id))),
              ],
              onChanged: (v) => setState(() => _metodo = v ?? 'todos'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _estadistica('Pedidos', '${pedidos.length}'),
            const SizedBox(width: 8),
            _estadistica('Recaudado', pesos(recaudado), color: AppColors.rojo),
            const SizedBox(width: 8),
            _estadistica(
              'MP sin acreditar',
              '${pedidos.where((p) => p.esMercadoPago && p.estadoPago == 'pendiente').length}',
              color: const Color(0xFF0369A1),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Pedidos recibidos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const Text('Los más recientes primero',
            style: TextStyle(fontSize: 11, color: AppColors.gris)),
        const SizedBox(height: 10),
        if (pedidos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  const Text('🧺', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                      cantina.pedidos.isEmpty
                          ? 'Todavía no recibiste ningún pedido.'
                          : 'No hay pedidos con estos filtros.',
                      style: const TextStyle(color: AppColors.gris, fontWeight: FontWeight.w700)),
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

  Widget _etiqueta(String texto, Color fondo, Color color) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
        child: Text(texto, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      );

  @override
  Widget build(BuildContext context) {
    final estado = pedido.esMercadoPago ? pedido.estadoPago : null;
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
                  pedido.horaRetiro != null
                      ? _etiqueta('🕒 Retira ${pedido.horaRetiro}', const Color(0xFFFEF3C7),
                          const Color(0xFF92400E))
                      : _etiqueta('🕒 Lo antes posible', AppColors.fondo, AppColors.gris),
                  const SizedBox(height: 6),
                  for (final it in pedido.items) ...[
                    Text('${it.cantidad}x ${it.esCombo ? '🍱 ' : ''}${it.nombre}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    if (it.detalle.isNotEmpty)
                      Text('   ${it.detalle.join(' · ')}',
                          style: const TextStyle(fontSize: 11, color: AppColors.gris)),
                    for (final o in it.opciones)
                      Text('   + ${o.nombre}',
                          style: const TextStyle(fontSize: 11, color: AppColors.gris)),
                    if (it.nota != null)
                      Text('   “${it.nota}”',
                          style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w700)),
                  ],
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
                _etiqueta(
                  switch (pedido.metodoPago) {
                    'transferencia' => '🏦 Transf.',
                    'mercadopago' => '💙 MP',
                    'tarjeta' => '💳 Tarjeta',
                    _ => '💵 Efectivo',
                  },
                  AppColors.fondo,
                  AppColors.texto,
                ),
                if (estado == 'aprobado')
                  _etiqueta('Pagado ✓', AppColors.verdeClaro, AppColors.verde)
                else if (estado == 'rechazado')
                  _etiqueta('Rechazado', const Color(0xFFFEE2E2), AppColors.rojo)
                else if (estado == 'pendiente')
                  _etiqueta('Pago pendiente', const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
                if (pedido.pagaCon != null && pedido.vuelto != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Paga ${pesos(pedido.pagaCon!)}\nVuelto ${pesos(pedido.vuelto!)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
