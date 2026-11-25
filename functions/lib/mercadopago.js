// Llamadas a la API de Mercado Pago (Checkout Pro). Se separa de index.js
// para poder probarlo sin internet, pasando un `fetch` falso.
const API = 'https://api.mercadopago.com'

async function _pedirJson(fetchFn, url, opciones) {
  const resp = await fetchFn(url, opciones)
  const texto = await resp.text()
  let cuerpo = null
  try { cuerpo = texto ? JSON.parse(texto) : null } catch { cuerpo = texto }
  if (!resp.ok) {
    const detalle = typeof cuerpo === 'object' && cuerpo ? (cuerpo.message || cuerpo.error) : texto
    throw new Error(`Mercado Pago respondió ${resp.status}: ${detalle}`)
  }
  return cuerpo
}

/**
 * Crea la "preferencia" de pago: el link al que se manda al cliente.
 * Un solo ítem con el total recalculado (así lo que cobra MP siempre es
 * exactamente lo que dice el pedido).
 */
async function crearPreferencia({ fetchFn = fetch, accessToken, pedidoId, numero, total, lineas, urlRetorno, urlNotificacion }) {
  const descripcion = lineas.map((l) => `${l.cantidad}x ${l.titulo}`).join(', ').slice(0, 250)
  const cuerpo = {
    items: [{
      id: pedidoId,
      title: `Pedido MiCantina #${String(numero).padStart(3, '0')}`,
      description: descripcion,
      quantity: 1,
      currency_id: 'ARS',
      unit_price: total,
    }],
    external_reference: pedidoId,
    notification_url: urlNotificacion,
    back_urls: {
      success: urlRetorno,
      pending: urlRetorno,
      failure: urlRetorno,
    },
    auto_return: 'approved',
    statement_descriptor: 'MICANTINA',
    // El link vence en 2 horas: un pedido de cantina no tiene sentido pagarlo al otro día.
    expires: true,
    expiration_date_to: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
  }
  const datos = await _pedirJson(fetchFn, `${API}/checkout/preferences`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(cuerpo),
  })
  return { id: datos.id, initPoint: datos.init_point }
}

async function obtenerPago({ fetchFn = fetch, accessToken, pagoId }) {
  return _pedirJson(fetchFn, `${API}/v1/payments/${encodeURIComponent(pagoId)}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
}

/**
 * Saca el id de pago de una notificación de MP. Llegan en dos formatos:
 *  - Webhooks:  ?type=payment&data.id=123   o  body { type: 'payment', data: { id } }
 *  - IPN viejo: ?topic=payment&id=123
 * Devuelve null si la notificación no es de un pago (ej: merchant_order).
 */
function idDePagoDeNotificacion(query = {}, body = {}) {
  const tipo = query.type || query.topic || body.type || body.topic
  if (tipo !== 'payment') return null
  const id = query['data.id'] || body?.data?.id || query.id || body.id
  return id ? String(id) : null
}

/**
 * Decide en qué estado queda el pedido según el pago que informa MP.
 * Devuelve null si no hay que cambiar nada.
 */
function estadoSegunPago(pago, pedido) {
  if (!pago || !pedido) return null
  if (pedido.estadoPago === 'aprobado') return null // ya está pagado: no se toca
  if (pago.status === 'approved') {
    const pagado = Number(pago.transaction_amount)
    if (pago.currency_id && pago.currency_id !== 'ARS') return null
    // Si por algún motivo se pagó menos que el total, no lo damos por pagado.
    if (!(pagado + 0.01 >= Number(pedido.total))) return null
    return 'aprobado'
  }
  if (['rejected', 'cancelled', 'refunded', 'charged_back'].includes(pago.status)) return 'rechazado'
  return null // pending / in_process: sigue "pendiente"
}

module.exports = { crearPreferencia, obtenerPago, idDePagoDeNotificacion, estadoSegunPago }
