// Cloud Functions de MiCantina: cobro real con Mercado Pago (Checkout Pro).
//
// Por qué hace falta un servidor: para crear un link de pago hay que usar el
// "Access Token" de la cuenta de Mercado Pago, que es secreto (con él se puede
// operar la cuenta). Si estuviera en la web o en la app, cualquiera podría
// sacarlo. Acá queda guardado como secreto de Firebase y nunca sale del servidor.
//
// Flujo:
//  1. La web/app crea el pedido en Firestore con estadoPago: 'pendiente'.
//  2. Llama a crearPagoMercadoPago({ pedidoId }): acá se recalcula el total
//     con los precios de Firestore y se crea el link de pago.
//  3. El cliente paga en Mercado Pago.
//  4. Mercado Pago avisa a webhookMercadoPago. Acá se consulta el pago a la
//     API de MP (no se confía en lo que dice la notificación) y, si está
//     aprobado y el monto coincide, el pedido pasa a estadoPago: 'aprobado'.
//     La vendedora lo ve al instante en su Panel de Ventas.
//
// Configuración (una sola vez, ver functions/README.md):
//   firebase functions:secrets:set MP_ACCESS_TOKEN

const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https')
const { defineSecret, defineString } = require('firebase-functions/params')
const logger = require('firebase-functions/logger')
const { initializeApp } = require('firebase-admin/app')
const { getFirestore, FieldValue } = require('firebase-admin/firestore')

const { calcularTotal, ErrorDePedido } = require('./lib/total')
const { crearPreferencia, obtenerPago, idDePagoDeNotificacion, estadoSegunPago } = require('./lib/mercadopago')

initializeApp()
const db = getFirestore()

const MP_ACCESS_TOKEN = defineSecret('MP_ACCESS_TOKEN')
// Dirección de la página web, para volver después de pagar.
const URL_WEB = defineString('URL_WEB', { default: 'https://micantina-ef6be.web.app' })

const REGION = 'us-central1'

async function _leerDoc(coleccion, id) {
  if (!id || typeof id !== 'string') return null
  const snap = await db.collection(coleccion).doc(id).get()
  return snap.exists ? snap.data() : null
}

exports.crearPagoMercadoPago = onCall(
  { region: REGION, secrets: [MP_ACCESS_TOKEN], invoker: 'public' },
  async (request) => {
    const uid = request.auth?.uid
    if (!uid) throw new HttpsError('unauthenticated', 'Tenés que tener una sesión abierta')

    const pedidoId = request.data?.pedidoId
    if (typeof pedidoId !== 'string' || !pedidoId) throw new HttpsError('invalid-argument', 'Falta el pedido')

    const ref = db.collection('pedidos').doc(pedidoId)
    const snap = await ref.get()
    if (!snap.exists) throw new HttpsError('not-found', 'No existe ese pedido')
    const pedido = snap.data()

    if (pedido.uid !== uid) throw new HttpsError('permission-denied', 'Ese pedido no es tuyo')
    if (pedido.metodoPago !== 'mercadopago') throw new HttpsError('failed-precondition', 'El pedido no es con Mercado Pago')
    if (pedido.estadoPago === 'aprobado') throw new HttpsError('already-exists', 'Este pedido ya está pagado')

    let calculo
    try {
      calculo = await calcularTotal(
        pedido.items,
        (id) => _leerDoc('productos', id),
        (id) => _leerDoc('combos', id),
      )
    } catch (err) {
      if (err instanceof ErrorDePedido) throw new HttpsError('failed-precondition', err.message)
      throw err
    }
    if (calculo.total <= 0) throw new HttpsError('failed-precondition', 'El total del pedido es inválido')

    const urlNotificacion = `https://${REGION}-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/webhookMercadoPago`
    const urlRetorno = `${URL_WEB.value()}/?pedido=${encodeURIComponent(pedidoId)}`

    let preferencia
    try {
      preferencia = await crearPreferencia({
        accessToken: MP_ACCESS_TOKEN.value(),
        pedidoId,
        numero: pedido.numero,
        total: calculo.total,
        lineas: calculo.lineas,
        urlRetorno,
        urlNotificacion,
      })
    } catch (err) {
      logger.error('No se pudo crear la preferencia de MP', { pedidoId, error: err.message })
      throw new HttpsError('unavailable', 'Mercado Pago no respondió. Probá de nuevo en un rato.')
    }

    // El total "oficial" es el que calculó el servidor.
    await ref.update({
      total: calculo.total,
      estadoPago: 'pendiente',
      mpPreferenciaId: preferencia.id,
    })

    return { initPoint: preferencia.initPoint, total: calculo.total }
  },
)

exports.webhookMercadoPago = onRequest(
  { region: REGION, secrets: [MP_ACCESS_TOKEN], invoker: 'public' },
  async (req, res) => {
    try {
      const pagoId = idDePagoDeNotificacion(req.query, req.body)
      if (!pagoId) {
        res.status(200).send('ignorado')
        return
      }

      // Nunca confiamos en la notificación: le preguntamos el pago a MP.
      const pago = await obtenerPago({ accessToken: MP_ACCESS_TOKEN.value(), pagoId })
      const pedidoId = pago.external_reference
      if (!pedidoId) {
        res.status(200).send('sin pedido')
        return
      }

      const ref = db.collection('pedidos').doc(String(pedidoId))
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref)
        if (!snap.exists) return
        const nuevoEstado = estadoSegunPago(pago, snap.data())
        if (!nuevoEstado) return
        tx.update(ref, {
          estadoPago: nuevoEstado,
          mpPagoId: String(pago.id),
          mpEstado: pago.status,
          pagadoEn: nuevoEstado === 'aprobado' ? FieldValue.serverTimestamp() : null,
        })
      })
      res.status(200).send('ok')
    } catch (err) {
      logger.error('Error procesando notificación de MP', { error: err.message })
      // 500 => Mercado Pago reintenta la notificación más tarde.
      res.status(500).send('error')
    }
  },
)
