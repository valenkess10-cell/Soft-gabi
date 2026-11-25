# Cobro con Mercado Pago (Cloud Functions)

Estas funciones crean el link de pago de Mercado Pago y marcan el pedido como
pagado cuando Mercado Pago confirma el cobro. Se configuran una sola vez.

## 1. Pasar el proyecto de Firebase al plan Blaze
Firebase Console → proyecto `micantina-ef6be` → abajo a la izquierda, **Actualizar** → plan **Blaze**.
Pide una tarjeta, pero con el uso de una cantina el costo suele ser $0 (hay una cuota gratis mensual).
Conviene poner una alerta de presupuesto (por ejemplo, USD 1) en Google Cloud → Facturación → Presupuestos.

## 2. Sacar el Access Token de Mercado Pago
1. Entrá a https://www.mercadopago.com.ar/developers/panel con la cuenta que va a cobrar.
2. **Crear aplicación** → tipo "Pagos online" → "CheckoutPro".
3. En la aplicación: **Credenciales de producción** → copiá el **Access Token** (empieza con `APP_USR-`).
   Para probar sin plata real, usá las **Credenciales de prueba** y las cuentas de prueba que da ese panel.

## 3. Guardar el token y publicar las funciones
Desde la carpeta raíz del repo (donde está `firebase.json`):

```bash
npm install -g firebase-tools      # una sola vez
firebase login
cd functions && npm install && cd ..
firebase functions:secrets:set MP_ACCESS_TOKEN   # pegá el Access Token cuando lo pida
firebase deploy --only functions,firestore:rules
```

El token queda guardado como secreto en Google Cloud: nunca está en la web ni en la app.

## 4. Probar
Hacé un pedido eligiendo Mercado Pago. Al pagar, en el Panel de Ventas el pedido pasa de
"Pago pendiente" a "Pagado ✓". Si algo falla: `firebase functions:log`.

## Cómo funciona
- `crearPagoMercadoPago` (la llaman la web y la app): recalcula el total con los precios de
  Firestore (no confía en el que manda el cliente) y crea la preferencia de pago.
- `webhookMercadoPago` (la llama Mercado Pago): consulta el pago a la API de Mercado Pago y,
  si está aprobado por el monto completo, marca `estadoPago: 'aprobado'` en el pedido.
- Si la web no está en `https://micantina-ef6be.web.app`, cambiá `URL_WEB` al desplegar.
