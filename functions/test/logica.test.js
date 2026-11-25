const test = require('node:test')
const assert = require('node:assert/strict')
const { calcularTotal, ErrorDePedido } = require('../lib/total')
const { crearPreferencia, idDePagoDeNotificacion, estadoSegunPago } = require('../lib/mercadopago')

const productos = {
  pizza: { nombre: 'Pizza', precio: 3500, opciones: [{ id: 'q', nombre: 'Extra queso', precio: 500 }, { id: 'c', nombre: 'Sin cebolla', precio: 0 }] },
  coca: { nombre: 'Coca-Cola', precio: 1800 },
}
const combos = {
  c1: { nombre: 'Pizza + Coca', precio: 4800, activo: true },
  pausado: { nombre: 'Pausado', precio: 100, activo: false },
}
const leerP = async (id) => productos[id] ?? null
const leerC = async (id) => combos[id] ?? null

test('suma productos con opciones y combos con los precios del servidor', async () => {
  const { total, lineas } = await calcularTotal([
    { tipo: 'producto', id: 'pizza', cantidad: 2, opciones: [{ id: 'q' }, { id: 'c' }] },
    { tipo: 'producto', id: 'coca', cantidad: 1, opciones: [] },
    { tipo: 'combo', id: 'c1', cantidad: 1 },
  ], leerP, leerC)
  assert.equal(total, (3500 + 500) * 2 + 1800 + 4800)
  assert.equal(lineas.length, 3)
})

test('ignora el precio que manda el cliente', async () => {
  const { total } = await calcularTotal([
    { tipo: 'producto', id: 'coca', cantidad: 1, precioUnitario: 1, opciones: [] },
  ], leerP, leerC)
  assert.equal(total, 1800)
})

test('rechaza opciones inventadas, combos pausados, productos borrados y cantidades raras', async () => {
  await assert.rejects(calcularTotal([{ tipo: 'producto', id: 'pizza', cantidad: 1, opciones: [{ id: 'gratis' }] }], leerP, leerC), ErrorDePedido)
  await assert.rejects(calcularTotal([{ tipo: 'combo', id: 'pausado', cantidad: 1 }], leerP, leerC), ErrorDePedido)
  await assert.rejects(calcularTotal([{ tipo: 'producto', id: 'nada', cantidad: 1 }], leerP, leerC), ErrorDePedido)
  await assert.rejects(calcularTotal([{ tipo: 'producto', id: 'coca', cantidad: 0 }], leerP, leerC), ErrorDePedido)
  await assert.rejects(calcularTotal([{ tipo: 'producto', id: 'coca', cantidad: -3 }], leerP, leerC), ErrorDePedido)
  await assert.rejects(calcularTotal([{ nombre: 'viejo', cantidad: 1 }], leerP, leerC), ErrorDePedido)
  await assert.rejects(calcularTotal([], leerP, leerC), ErrorDePedido)
})

test('lee el id de pago en los dos formatos de notificación de MP', () => {
  assert.equal(idDePagoDeNotificacion({ type: 'payment', 'data.id': '123' }, {}), '123')
  assert.equal(idDePagoDeNotificacion({}, { type: 'payment', data: { id: 456 } }), '456')
  assert.equal(idDePagoDeNotificacion({ topic: 'payment', id: '789' }, {}), '789')
  assert.equal(idDePagoDeNotificacion({ topic: 'merchant_order', id: '1' }, {}), null)
})

test('solo da por pagado si MP aprobó el monto completo en pesos', () => {
  const pedido = { total: 5000, estadoPago: 'pendiente' }
  assert.equal(estadoSegunPago({ status: 'approved', transaction_amount: 5000, currency_id: 'ARS' }, pedido), 'aprobado')
  assert.equal(estadoSegunPago({ status: 'approved', transaction_amount: 4999, currency_id: 'ARS' }, pedido), null)
  assert.equal(estadoSegunPago({ status: 'approved', transaction_amount: 5000, currency_id: 'USD' }, pedido), null)
  assert.equal(estadoSegunPago({ status: 'rejected' }, pedido), 'rechazado')
  assert.equal(estadoSegunPago({ status: 'in_process' }, pedido), null)
  // Un rechazo posterior no pisa un pago ya aprobado.
  assert.equal(estadoSegunPago({ status: 'rejected' }, { total: 5000, estadoPago: 'aprobado' }), null)
  // Después de un rechazo se puede reintentar y aprobar.
  assert.equal(estadoSegunPago({ status: 'approved', transaction_amount: 5000, currency_id: 'ARS' }, { total: 5000, estadoPago: 'rechazado' }), 'aprobado')
})

test('crea la preferencia con el total, la referencia al pedido y las URLs', async () => {
  let enviado
  const fetchFalso = async (url, opciones) => {
    enviado = { url, opciones, cuerpo: JSON.parse(opciones.body) }
    return { ok: true, status: 201, text: async () => JSON.stringify({ id: 'pref-1', init_point: 'https://mp/checkout' }) }
  }
  const r = await crearPreferencia({
    fetchFn: fetchFalso,
    accessToken: 'TOKEN',
    pedidoId: 'abc',
    numero: 7,
    total: 6600,
    lineas: [{ titulo: 'Pizza', cantidad: 1, precioUnitario: 4800 }, { titulo: 'Coca-Cola', cantidad: 1, precioUnitario: 1800 }],
    urlRetorno: 'https://web/?pedido=abc',
    urlNotificacion: 'https://fn/webhook',
  })
  assert.deepEqual(r, { id: 'pref-1', initPoint: 'https://mp/checkout' })
  assert.equal(enviado.url, 'https://api.mercadopago.com/checkout/preferences')
  assert.equal(enviado.opciones.headers.Authorization, 'Bearer TOKEN')
  assert.equal(enviado.cuerpo.items[0].unit_price, 6600)
  assert.equal(enviado.cuerpo.items[0].title, 'Pedido MiCantina #007')
  assert.equal(enviado.cuerpo.external_reference, 'abc')
  assert.equal(enviado.cuerpo.notification_url, 'https://fn/webhook')
  assert.equal(enviado.cuerpo.back_urls.success, 'https://web/?pedido=abc')
})

test('un error de MP se informa con el mensaje que devolvió', async () => {
  const fetchFalso = async () => ({ ok: false, status: 401, text: async () => JSON.stringify({ message: 'invalid access token' }) })
  await assert.rejects(
    crearPreferencia({ fetchFn: fetchFalso, accessToken: 'x', pedidoId: 'a', numero: 1, total: 1, lineas: [], urlRetorno: 'u', urlNotificacion: 'n' }),
    /401: invalid access token/,
  )
})
