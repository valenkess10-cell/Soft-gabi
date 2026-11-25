// Reglas compartidas sobre pedidos: métodos de pago, horarios de retiro y
// cómo se calcula el precio de cada línea del carrito. La app de Flutter
// (lib/utils/pedidos_util.dart) y las Cloud Functions (functions/lib/total.js)
// usan exactamente la misma lógica, así los totales siempre coinciden.

// ============ MÉTODOS DE PAGO ============
// En Firestore se guarda el id. Los pedidos viejos de la web guardaban la
// etiqueta ("Efectivo en caja", etc.), por eso existe normalizarMetodoPago.
export const metodosPago = [
  { id: 'transferencia', nombre: 'Transferencia', etiqueta: 'Transferencia bancaria' },
  { id: 'mercadopago', nombre: 'Mercado Pago', etiqueta: 'Mercado Pago' },
  { id: 'tarjeta', nombre: 'Tarjeta', etiqueta: 'Tarjeta en caja' },
  { id: 'efectivo', nombre: 'Efectivo', etiqueta: 'Efectivo en caja' },
]

export function normalizarMetodoPago(valor) {
  const v = String(valor ?? '').toLowerCase()
  if (v.includes('mercado')) return 'mercadopago'
  if (v.includes('transf')) return 'transferencia'
  if (v.includes('tarjeta')) return 'tarjeta'
  return 'efectivo'
}

export function etiquetaMetodoPago(valor) {
  const id = normalizarMetodoPago(valor)
  return metodosPago.find((m) => m.id === id)?.etiqueta ?? 'Efectivo en caja'
}

// ============ HORARIO DE RETIRO ============
// Franja en la que se pueden programar retiros. Cambiá estos valores si la
// cantina abre o cierra a otra hora (y los de pedidos_util.dart en la app).
export const HORARIO_RETIRO = { desde: '07:30', hasta: '18:00', intervaloMin: 15, anticipacionMin: 20 }

function _aMinutos(hhmm) {
  const [h, m] = hhmm.split(':').map(Number)
  return h * 60 + m
}

function _aTexto(min) {
  return `${String(Math.floor(min / 60)).padStart(2, '0')}:${String(min % 60).padStart(2, '0')}`
}

// Horarios de hoy que todavía se pueden elegir, de 15 en 15 minutos, dejando
// al menos 20 minutos para preparar el pedido.
export function horariosDeRetiro(ahora = new Date()) {
  const { desde, hasta, intervaloMin, anticipacionMin } = HORARIO_RETIRO
  const minimo = Math.max(_aMinutos(desde), ahora.getHours() * 60 + ahora.getMinutes() + anticipacionMin)
  const primero = Math.ceil(minimo / intervaloMin) * intervaloMin
  const lista = []
  for (let m = primero; m <= _aMinutos(hasta); m += intervaloMin) lista.push(_aTexto(m))
  return lista
}

// ============ LÍNEAS DEL CARRITO ============
// Dos líneas se juntan en una sola (sumando cantidad) solo si son el mismo
// producto/combo con exactamente las mismas opciones elegidas.
export function claveDeLinea(tipo, id, opciones = []) {
  const ids = opciones.map((o) => o.id).sort().join(',')
  return `${tipo}:${id}:${ids}`
}

export function precioUnitarioDeLinea(precioBase, opciones = []) {
  return precioBase + opciones.reduce((acc, o) => acc + (Number(o.precio) || 0), 0)
}

// Convierte una línea del carrito al formato que se guarda en el pedido.
export function lineaAItemDePedido(linea) {
  return {
    tipo: linea.tipo,
    id: linea.refId,
    nombre: linea.nombre,
    cantidad: linea.cantidad,
    precioUnitario: linea.precioUnitario,
    opciones: (linea.opciones ?? []).map((o) => ({ id: o.id, nombre: o.nombre, precio: Number(o.precio) || 0 })),
    nota: linea.nota?.trim() || null,
    detalle: linea.detalle ?? [],
  }
}

// Genera un id corto para las opciones que arma la vendedora.
export function nuevoIdCorto() {
  return Math.random().toString(36).slice(2, 10)
}
