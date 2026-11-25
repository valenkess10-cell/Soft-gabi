// Recalcula el total de un pedido con los precios que hay en Firestore, en
// vez de confiar en el total que mandó el celular o el navegador. Es la misma
// cuenta que hacen la web (src/data/pedidos.js) y la app (pedidos_util.dart):
//   producto: (precio del producto + precio de cada opción elegida) × cantidad
//   combo:    precio del combo × cantidad

class ErrorDePedido extends Error {}

/**
 * @param {Array} items  items del pedido ({ tipo, id, cantidad, opciones })
 * @param {(id: string) => Promise<object|null>} leerProducto
 * @param {(id: string) => Promise<object|null>} leerCombo
 * @returns {Promise<{ total: number, lineas: Array<{ titulo: string, cantidad: number, precioUnitario: number }> }>}
 */
async function calcularTotal(items, leerProducto, leerCombo) {
  if (!Array.isArray(items) || items.length === 0) throw new ErrorDePedido('El pedido no tiene productos')

  let total = 0
  const lineas = []
  for (const item of items) {
    const cantidad = Math.trunc(Number(item.cantidad))
    if (!Number.isFinite(cantidad) || cantidad < 1 || cantidad > 50) {
      throw new ErrorDePedido(`Cantidad inválida en "${item.nombre ?? item.id}"`)
    }

    let precioUnitario
    let titulo
    if (item.tipo === 'combo') {
      const combo = await leerCombo(item.id)
      if (!combo || combo.activo === false) throw new ErrorDePedido(`El combo "${item.nombre ?? item.id}" ya no está disponible`)
      precioUnitario = Math.trunc(Number(combo.precio))
      titulo = `Combo ${combo.nombre}`
    } else if (item.tipo === 'producto') {
      const producto = await leerProducto(item.id)
      if (!producto) throw new ErrorDePedido(`El producto "${item.nombre ?? item.id}" ya no existe`)
      precioUnitario = Math.trunc(Number(producto.precio))
      const disponibles = producto.opciones ?? []
      for (const elegida of item.opciones ?? []) {
        const opcion = disponibles.find((o) => o.id === elegida.id)
        if (!opcion) throw new ErrorDePedido(`La opción "${elegida.nombre ?? elegida.id}" ya no está disponible`)
        precioUnitario += Math.trunc(Number(opcion.precio) || 0)
      }
      titulo = producto.nombre
    } else {
      throw new ErrorDePedido('Este pedido es de una versión vieja de la app; hacelo de nuevo')
    }

    if (!Number.isFinite(precioUnitario) || precioUnitario < 0) throw new ErrorDePedido('Precio inválido')
    total += precioUnitario * cantidad
    lineas.push({ titulo, cantidad, precioUnitario })
  }
  return { total, lineas }
}

module.exports = { calcularTotal, ErrorDePedido }
