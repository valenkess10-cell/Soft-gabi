// Reglas compartidas sobre pedidos. Son las mismas que usa la web
// (vite-project/src/data/pedidos.js) y el servidor (functions/lib/total.js),
// así el total y los horarios coinciden en todas las plataformas.

import 'dart:math';

/// Los pedidos viejos de la web guardaban la etiqueta ("Efectivo en caja")
/// en vez del id ('efectivo'): esto los lleva siempre al id.
String normalizarMetodoPago(Object? valor) {
  final v = (valor ?? '').toString().toLowerCase();
  if (v.contains('mercado')) return 'mercadopago';
  if (v.contains('transf')) return 'transferencia';
  if (v.contains('tarjeta')) return 'tarjeta';
  return 'efectivo';
}

const metodosPagoIds = ['transferencia', 'mercadopago', 'tarjeta', 'efectivo'];

String nombreMetodoPago(String id) => switch (id) {
      'transferencia' => 'Transferencia',
      'mercadopago' => 'Mercado Pago',
      'tarjeta' => 'Tarjeta',
      _ => 'Efectivo',
    };

// ------------------------------------------------------- horario de retiro
/// Franja en la que se pueden programar retiros. Si la cantina abre o cierra
/// a otra hora, cambiá estos valores (y los de HORARIO_RETIRO en la web).
const horaRetiroDesde = '07:30';
const horaRetiroHasta = '18:00';
const _intervaloMin = 15;
const _anticipacionMin = 20;

int _aMinutos(String hhmm) {
  final partes = hhmm.split(':');
  return int.parse(partes[0]) * 60 + int.parse(partes[1]);
}

String _aTexto(int min) =>
    '${(min ~/ 60).toString().padLeft(2, '0')}:${(min % 60).toString().padLeft(2, '0')}';

/// Horarios de hoy que todavía se pueden elegir, de 15 en 15 minutos,
/// dejando al menos 20 minutos para preparar el pedido.
List<String> horariosDeRetiro(DateTime ahora) {
  final minimo = max(_aMinutos(horaRetiroDesde), ahora.hour * 60 + ahora.minute + _anticipacionMin);
  final primero = (minimo / _intervaloMin).ceil() * _intervaloMin;
  return [
    for (var m = primero; m <= _aMinutos(horaRetiroHasta); m += _intervaloMin) _aTexto(m),
  ];
}

/// Id corto para las opciones que arma la vendedora.
String nuevoIdCorto() {
  const letras = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final r = Random();
  return List.generate(8, (_) => letras[r.nextInt(letras.length)]).join();
}
