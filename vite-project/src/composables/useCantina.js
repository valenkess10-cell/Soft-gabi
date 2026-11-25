// Composable central de la web: hace lo mismo que cantina_provider.dart en
// la app de Flutter, para que ambas plataformas compartan en tiempo real el
// mismo catálogo, los mismos pedidos y los mismos usuarios en Firestore.
//
// Es un "singleton" simple: el estado se declara fuera de la función, así
// que todos los componentes que llaman a useCantina() reciben la misma
// instancia reactiva (sin necesidad de Pinia).

import { ref, computed } from 'vue'
import {
  signInAnonymously,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signOut,
} from 'firebase/auth'
import {
  collection,
  doc,
  setDoc,
  updateDoc,
  deleteDoc,
  getDoc,
  onSnapshot,
  query,
  orderBy,
  runTransaction,
  writeBatch,
  serverTimestamp,
  Timestamp,
  addDoc,
} from 'firebase/firestore'
import { httpsCallable } from 'firebase/functions'
import { auth, db, functions } from '../firebase.js'
import { categorias, categoriasDeKiosco, productosSemilla } from '../data/catalogo.js'
import {
  normalizarMetodoPago,
  etiquetaMetodoPago,
  claveDeLinea,
  precioUnitarioDeLinea,
  lineaAItemDePedido,
} from '../data/pedidos.js'

// Cuentas fijas de personal, iguales a las de cantina_provider.dart.
const EMAIL_VENDEDORA = 'vendedora@micantina.com'
const CLAVE_VENDEDORA = 'Vendedora2026'
const EMAIL_MASTER = 'master@micantina.com'
const CLAVE_MASTER = 'Cantina2026'

// ============ ESTADO COMPARTIDO ============
const listo = ref(false)
const usuario = ref(null) // { uid, nombre, email, rol }
const productos = ref([])
const combos = ref([]) // combos armados por la vendedora (colección `combos`)
const notas = ref([]) // anotador de la vendedora (colección `notas`)
const pedidos = ref([])
const usuariosRegistrados = ref([])
const carrito = ref([])
const categoriaActiva = ref('todos')

let desuscribirProductos = null
let desuscribirCombos = null
let desuscribirPedidos = null
let desuscribirUsuarios = null
let desuscribirNotas = null
let sembradoIntentado = false

// ============ RELOJ / CORTE DE ALMUERZO ============
// Las categorías que no son "de kiosco" (platos, pizzas, empanadas, pastas,
// tartas) son el almuerzo: se dejan de pedir a partir de las 11:30 de cada
// día, hora del navegador de quien mira la página.
const HORA_CORTE_ALMUERZO = { horas: 11, minutos: 30 }
const ahora = ref(new Date())
let intervaloReloj = null
function _iniciarReloj() {
  if (intervaloReloj) return
  intervaloReloj = setInterval(() => { ahora.value = new Date() }, 30000)
}

const almuerzoCerrado = computed(() => {
  const h = ahora.value.getHours()
  const m = ahora.value.getMinutes()
  return h > HORA_CORTE_ALMUERZO.horas || (h === HORA_CORTE_ALMUERZO.horas && m >= HORA_CORTE_ALMUERZO.minutos)
})

function esAlmuerzo(categoriaId) {
  return !categoriasDeKiosco.has(categoriaId)
}

// ============ CATÁLOGO ============
const categoriasMenu = computed(() => ([
  { id: 'todos', nombre: 'Todos', icono: '⭐', bg: 'bg-slate-100', border: 'border-slate-300', ring: 'ring-slate-400' },
  ...categorias,
]))

const todosLosProductos = computed(() => (productos.value.length ? productos.value : productosSemilla))

// stock null/undefined = sin límite (siempre disponible); stock 0 = agotado,
// se oculta de las vistas de cliente sin que la vendedora tenga que borrarlo.
function tieneStock(p) {
  return p.stock === null || p.stock === undefined || p.stock > 0
}

// Lo que ve cualquier cliente: sin los productos agotados.
const productosVisibles = computed(() => todosLosProductos.value.filter(tieneStock))

const productosFiltrados = computed(() => {
  if (categoriaActiva.value === 'todos') return productosVisibles.value
  if (categoriaActiva.value === 'sin-tacc') return productosVisibles.value.filter((p) => p.esSinTacc)
  return productosVisibles.value.filter((p) => p.categoria === categoriaActiva.value)
})

function productosDeCategoria(catId) {
  return productosVisibles.value.filter((p) => p.categoria === catId)
}

const destacados = computed(() => productosVisibles.value.filter((p) => p.destacado))

// ============ COMBOS ============
// Cada combo guarda qué productos lleva ({ productoId, nombre, cantidad }) y
// su precio especial. El resto (precio normal, ahorro, calorías, si está
// disponible) se calcula con los datos actuales de cada producto.
function detalleDeCombo(combo) {
  const lista = todosLosProductos.value
  const partes = (combo.items ?? []).map((it) => ({
    ...it,
    producto: lista.find((p) => p.id === it.productoId) ?? null,
  }))
  const completos = partes.every((pt) => pt.producto)
  const precioNormal = partes.reduce((acc, pt) => acc + (pt.producto?.precio ?? 0) * pt.cantidad, 0)
  const conCalorias = partes.every((pt) => typeof pt.producto?.calorias === 'number')
  const calorias = conCalorias
    ? partes.reduce((acc, pt) => acc + pt.producto.calorias * pt.cantidad, 0)
    : null
  return {
    partes,
    precioNormal,
    ahorro: completos ? Math.max(0, precioNormal - combo.precio) : 0,
    calorias,
    // Un combo se ofrece si está activo, si todos sus productos existen y
    // si ninguno está agotado.
    disponible: combo.activo !== false && partes.length > 0 && completos && partes.every((pt) => tieneStock(pt.producto)),
    esAlmuerzo: partes.some((pt) => pt.producto && esAlmuerzo(pt.producto.categoria)),
    descripcionItems: partes.map((pt) => `${pt.cantidad}x ${pt.producto?.nombre ?? pt.nombre}`),
  }
}

const combosVisibles = computed(() =>
  combos.value
    .map((c) => ({ ...c, ...detalleDeCombo(c) }))
    .filter((c) => c.disponible),
)

const esVendedora = computed(() => usuario.value?.rol === 'vendedora')
const esMaster = computed(() => usuario.value?.rol === 'master')
const esVendedoraOMaster = computed(() => esVendedora.value || esMaster.value)

const etiquetaRol = computed(() => {
  if (esMaster.value) return 'Administrador'
  if (esVendedora.value) return 'Vendedora'
  return usuario.value?.nombre || ''
})

// ============ CARGA / LISTENERS ============
function cargar() {
  if (listo.value) return
  _iniciarReloj()
  onAuthStateChanged(auth, async (fbUser) => {
    if (!fbUser) {
      // Sin nadie logueado: iniciamos sesión anónima para poder leer el
      // catálogo (las reglas de Firestore exigen estar autenticado), sin
      // que eso cuente como "estar logueado" de cara a la interfaz.
      try {
        await signInAnonymously(auth)
      } catch {
        listo.value = true
      }
      return
    }
    // Recién acá hay una sesión (anónima o real): si escucháramos el
    // catálogo antes, Firestore rechazaría la lectura por falta de permisos.
    _escucharCatalogo()
    if (fbUser.isAnonymous) {
      usuario.value = null
      pararEscuchasDeRol()
      listo.value = true
      return
    }
    await _aplicarUsuario(fbUser)
    listo.value = true
  })
}

function _escucharCatalogo() {
  if (!desuscribirProductos) {
    desuscribirProductos = onSnapshot(collection(db, 'productos'), (snap) => {
      productos.value = snap.docs.map((d) => _productoDeDocumento(d.id, d.data()))
    })
  }
  if (!desuscribirCombos) {
    desuscribirCombos = onSnapshot(collection(db, 'combos'), (snap) => {
      combos.value = snap.docs.map((d) => _comboDeDocumento(d.id, d.data()))
    }, (err) => console.error('No se pudieron leer los combos:', err))
  }
}

function _comboDeDocumento(id, data) {
  return {
    id,
    nombre: data.nombre ?? '',
    descripcion: data.descripcion ?? '',
    precio: Number(data.precio) || 0,
    items: (data.items ?? []).map((it) => ({
      productoId: it.productoId,
      nombre: it.nombre ?? '',
      cantidad: Number(it.cantidad) || 1,
    })),
    activo: data.activo !== false,
    imagenBase64: data.imagenBase64 ?? null,
  }
}

function _productoDeDocumento(id, data) {
  return {
    id,
    nombre: data.nombre ?? '',
    descripcion: data.descripcion ?? '',
    precio: data.precio ?? 0,
    imagen: data.imagen ?? null,
    imagenBase64: data.imagenBase64 ?? null,
    emoji: data.emoji ?? '🍽️',
    tag: data.tag ?? '',
    tiempo: data.tiempo ?? 1,
    categoria: data.categoria ?? 'platos',
    categoriaLabel: data.categoriaLabel ?? '',
    destacado: data.destacado ?? false,
    esSinTacc: data.esSinTacc ?? false,
    stock: data.stock === undefined ? null : data.stock,
    calorias: typeof data.calorias === 'number' ? data.calorias : null,
    // Extras/opciones que el cliente puede tildar: { id, nombre, precio }.
    // Precio 0 sirve para cosas como "sin cebolla".
    opciones: (data.opciones ?? []).map((o) => ({ id: o.id, nombre: o.nombre ?? '', precio: Number(o.precio) || 0 })),
  }
}

function pararEscuchasDeRol() {
  if (desuscribirPedidos) { desuscribirPedidos(); desuscribirPedidos = null }
  if (desuscribirUsuarios) { desuscribirUsuarios(); desuscribirUsuarios = null }
  if (desuscribirNotas) { desuscribirNotas(); desuscribirNotas = null }
  pedidos.value = []
  usuariosRegistrados.value = []
  notas.value = []
}

async function _aplicarUsuario(fbUser) {
  const refUsuario = doc(db, 'usuarios', fbUser.uid)
  const snap = await getDoc(refUsuario)
  let datos
  if (snap.exists()) {
    datos = snap.data()
  } else {
    // Primer inicio de sesión: creamos el perfil con rol "cliente" por defecto,
    // salvo que sea una de las dos cuentas fijas de personal.
    const rol = fbUser.email === EMAIL_VENDEDORA ? 'vendedora' : fbUser.email === EMAIL_MASTER ? 'master' : 'cliente'
    datos = { nombre: fbUser.displayName || fbUser.email || 'Invitado', email: fbUser.email ?? '', rol }
    await setDoc(refUsuario, datos)
  }

  usuario.value = { uid: fbUser.uid, nombre: datos.nombre, email: datos.email, rol: datos.rol }

  pararEscuchasDeRol()

  if (datos.rol === 'vendedora' || datos.rol === 'master') {
    _escucharPedidos()
    _escucharNotas()
    if (!sembradoIntentado) {
      sembradoIntentado = true
      _sembrarProductosSiHaceFalta()
    }
  }
  if (datos.rol === 'master') {
    _escucharUsuarios()
  }
}

function _escucharPedidos() {
  const refPedidos = query(collection(db, 'pedidos'), orderBy('fecha', 'desc'))
  desuscribirPedidos = onSnapshot(refPedidos, (snap) => {
    pedidos.value = snap.docs.map((d) => {
      const data = d.data()
      const fecha = data.fecha instanceof Timestamp ? data.fecha.toDate() : new Date()
      const metodoPago = normalizarMetodoPago(data.metodoPago)
      return {
        id: d.id,
        ...data,
        fecha,
        metodoPago,
        metodoPagoEtiqueta: etiquetaMetodoPago(metodoPago),
        horaRetiro: data.horaRetiro ?? null,
        estadoPago: data.estadoPago ?? null,
        items: (data.items ?? []).map((it) => ({ opciones: [], nota: null, detalle: [], ...it })),
      }
    })
  })
}

function _escucharNotas() {
  desuscribirNotas = onSnapshot(query(collection(db, 'notas'), orderBy('fecha', 'desc')), (snap) => {
    notas.value = snap.docs.map((d) => {
      const data = d.data()
      return {
        id: d.id,
        texto: data.texto ?? '',
        hecha: data.hecha === true,
        autor: data.autor ?? '',
        fecha: data.fecha instanceof Timestamp ? data.fecha.toDate() : new Date(),
      }
    })
  }, (err) => console.error('No se pudo leer el anotador:', err))
}

function _escucharUsuarios() {
  desuscribirUsuarios = onSnapshot(collection(db, 'usuarios'), (snap) => {
    usuariosRegistrados.value = snap.docs.map((d) => ({ uid: d.id, ...d.data() }))
  })
}

// Siembra el catálogo "de fábrica" en Firestore la primera vez, con IDs
// deterministas para que sea idempotente (no duplica si se llama de nuevo).
async function _sembrarProductosSiHaceFalta() {
  if (productos.value.length > 0) return
  const batch = writeBatch(db)
  for (const p of productosSemilla) {
    const { id, ...resto } = p
    batch.set(doc(db, 'productos', id), resto)
  }
  await batch.commit()
}

// ============ AUTENTICACIÓN ============
async function registrar(nombre, email, password) {
  const cred = await createUserWithEmailAndPassword(auth, email, password)
  const rol = email.trim().toLowerCase() === EMAIL_VENDEDORA ? 'vendedora'
    : email.trim().toLowerCase() === EMAIL_MASTER ? 'master' : 'cliente'
  await setDoc(doc(db, 'usuarios', cred.user.uid), { nombre, email, rol })
  await _aplicarUsuario(cred.user)
}

async function iniciarSesion(email, password) {
  const correo = email.trim().toLowerCase()
  try {
    const cred = await signInWithEmailAndPassword(auth, correo, password)
    await _aplicarUsuario(cred.user)
    return
  } catch (err) {
    // Primera vez que alguien entra con alguna de las dos cuentas fijas de
    // personal: todavía no existen en Firebase Auth, así que las creamos.
    const esCuentaDeStaff = (correo === EMAIL_VENDEDORA && password === CLAVE_VENDEDORA) ||
      (correo === EMAIL_MASTER && password === CLAVE_MASTER)
    if (esCuentaDeStaff && (err.code === 'auth/user-not-found' || err.code === 'auth/invalid-credential')) {
      await _crearCuentaDeStaff(correo, password)
      return
    }
    throw err
  }
}

async function _crearCuentaDeStaff(email, password) {
  const cred = await createUserWithEmailAndPassword(auth, email, password)
  const rol = email === EMAIL_VENDEDORA ? 'vendedora' : 'master'
  const nombre = rol === 'vendedora' ? 'Vendedora' : 'Administrador'
  await setDoc(doc(db, 'usuarios', cred.user.uid), { nombre, email, rol })
  await _aplicarUsuario(cred.user)
}

async function cerrarSesion() {
  await signOut(auth)
  usuario.value = null
  pararEscuchasDeRol()
}

// ============ CARRITO ============
const cantidadTotal = computed(() => carrito.value.reduce((acc, i) => acc + i.cantidad, 0))
const totalCarrito = computed(() => carrito.value.reduce((acc, i) => acc + i.precioUnitario * i.cantidad, 0))

// Cada línea del carrito tiene una `clave` única: mismo producto con las
// mismas opciones suma cantidad; con opciones distintas va en otra línea.
function _sumarLinea(linea) {
  const existente = carrito.value.find((i) => i.clave === linea.clave)
  if (existente) {
    existente.cantidad++
    if (linea.nota) existente.nota = linea.nota
  } else {
    carrito.value.push({ ...linea, cantidad: 1 })
  }
}

function agregarAlCarrito(prod, opciones = [], nota = '') {
  _sumarLinea({
    clave: claveDeLinea('producto', prod.id, opciones),
    tipo: 'producto',
    refId: prod.id,
    nombre: prod.nombre,
    precioUnitario: precioUnitarioDeLinea(prod.precio, opciones),
    opciones,
    nota: nota?.trim() || '',
    detalle: [],
    emoji: prod.emoji,
    imagen: prod.imagen,
    imagenBase64: prod.imagenBase64,
  })
}

function agregarComboAlCarrito(combo) {
  _sumarLinea({
    clave: claveDeLinea('combo', combo.id),
    tipo: 'combo',
    refId: combo.id,
    nombre: combo.nombre,
    precioUnitario: combo.precio,
    opciones: [],
    nota: '',
    detalle: combo.descripcionItems ?? [],
    emoji: '🍱',
    imagen: null,
    imagenBase64: combo.imagenBase64,
  })
}

function decrementarCantidad(clave) {
  const existente = carrito.value.find((i) => i.clave === clave)
  if (!existente) return
  if (existente.cantidad > 1) existente.cantidad--
  else quitarDelCarrito(clave)
}

function sumarCantidad(clave) {
  const existente = carrito.value.find((i) => i.clave === clave)
  if (existente) existente.cantidad++
}

function cambiarNota(clave, nota) {
  const existente = carrito.value.find((i) => i.clave === clave)
  if (existente) existente.nota = nota
}

function quitarDelCarrito(clave) {
  carrito.value = carrito.value.filter((i) => i.clave !== clave)
}

function vaciarCarrito() {
  carrito.value = []
}

// ============ PEDIDOS / PAGO ============
// Usa una transacción para que el número de turno diario sea atómico y
// correlativo, igual que confirmarPago() en cantina_provider.dart.
// detalle: { pagaCon, vuelto, horaRetiro } (todos opcionales). Devuelve
// { id, numero } del pedido creado.
async function confirmarPago(metodoPago, detalle) {
  const metodo = normalizarMetodoPago(metodoPago)
  const hoy = new Date()
  const fechaStr = `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-${String(hoy.getDate()).padStart(2, '0')}`

  const refPedido = doc(collection(db, 'pedidos'))
  const numero = await runTransaction(db, async (tx) => {
    const refContador = doc(db, 'contadores', 'turnos')
    const snap = await tx.get(refContador)
    let siguiente = 1
    if (snap.exists() && snap.data().fecha === fechaStr) {
      siguiente = (snap.data().ultimo ?? 0) + 1
    }
    tx.set(refContador, { fecha: fechaStr, ultimo: siguiente })

    tx.set(refPedido, {
      numero: siguiente,
      fecha: serverTimestamp(),
      cliente: usuario.value?.nombre || 'Invitado',
      uid: auth.currentUser?.uid || null,
      items: carrito.value.map(lineaAItemDePedido),
      total: totalCarrito.value,
      metodoPago: metodo,
      pagaCon: detalle?.pagaCon ?? null,
      vuelto: detalle?.vuelto ?? null,
      // null = "lo antes posible"; si no, "HH:MM" de hoy.
      horaRetiro: detalle?.horaRetiro ?? null,
      // Solo Mercado Pago se cobra online: queda "pendiente" hasta que el
      // servidor (functions/index.js) recibe la confirmación del pago.
      estadoPago: metodo === 'mercadopago' ? 'pendiente' : null,
      calificacion: null,
      comentario: null,
    })

    return siguiente
  })

  vaciarCarrito()
  return { id: refPedido.id, numero }
}

// Le pide al servidor el link de pago de Mercado Pago para un pedido ya
// creado. El servidor recalcula el total con los precios de Firestore.
async function crearPagoMercadoPago(pedidoId) {
  const crear = httpsCallable(functions, 'crearPagoMercadoPago')
  const { data } = await crear({ pedidoId, origen: 'web' })
  return data // { initPoint, total }
}

// Escucha en vivo un pedido puntual (para ver cuándo se acredita el pago).
function escucharPedido(pedidoId, alCambiar) {
  return onSnapshot(doc(db, 'pedidos', pedidoId), (snap) => {
    if (!snap.exists()) return alCambiar(null)
    const data = snap.data()
    alCambiar({ id: snap.id, ...data, metodoPago: normalizarMetodoPago(data.metodoPago) })
  }, () => alCambiar(null))
}

async function calificarPedido(pedidoId, calificacion, comentario) {
  await updateDoc(doc(db, 'pedidos', pedidoId), { calificacion, comentario })
}

// ============ CRUD DE PRODUCTOS (vendedora / master) ============
// Sentinela para distinguir "no me pasaron este campo, dejalo como estaba"
// de "me pasaron explícitamente null", igual que en producto.dart.
export const sinCambioImagen = Symbol('sinCambioImagen')

async function agregarProducto({ nombre, descripcion, precio, categoria, categoriaLabel, imagenBase64, emoji, tiempo, esSinTacc, stock, calorias, opciones }) {
  const refNuevo = doc(collection(db, 'productos'))
  await setDoc(refNuevo, {
    nombre,
    descripcion: descripcion ?? '',
    precio,
    imagen: null,
    imagenBase64: imagenBase64 ?? null,
    emoji: emoji ?? '🍽️',
    tag: 'Nuevo',
    tiempo: tiempo ?? (categoriasDeKiosco.has(categoria) ? 1 : 10),
    categoria,
    categoriaLabel: categoriaLabel ?? categoria,
    destacado: false,
    esSinTacc: esSinTacc ?? false,
    stock: stock ?? null,
    calorias: calorias ?? null,
    opciones: opciones ?? [],
  })
}

async function editarProducto(id, cambios) {
  const datos = { ...cambios }
  if (datos.imagenBase64 === sinCambioImagen) delete datos.imagenBase64
  await updateDoc(doc(db, 'productos', id), datos)
}

async function eliminarProducto(id) {
  await deleteDoc(doc(db, 'productos', id))
}

// ============ CRUD DE COMBOS (vendedora / master) ============
async function guardarCombo(id, datos) {
  const limpio = {
    nombre: datos.nombre,
    descripcion: datos.descripcion ?? '',
    precio: datos.precio,
    items: datos.items.map((it) => ({ productoId: it.productoId, nombre: it.nombre, cantidad: it.cantidad })),
    activo: datos.activo !== false,
    imagenBase64: datos.imagenBase64 ?? null,
  }
  if (id) await updateDoc(doc(db, 'combos', id), limpio)
  else await setDoc(doc(collection(db, 'combos')), limpio)
}

async function cambiarComboActivo(id, activo) {
  await updateDoc(doc(db, 'combos', id), { activo })
}

async function eliminarCombo(id) {
  await deleteDoc(doc(db, 'combos', id))
}

// ============ ANOTADOR (vendedora / master) ============
async function agregarNota(texto) {
  await addDoc(collection(db, 'notas'), {
    texto,
    hecha: false,
    autor: usuario.value?.nombre ?? '',
    fecha: serverTimestamp(),
  })
}

async function editarNota(id, cambios) {
  await updateDoc(doc(db, 'notas', id), cambios)
}

async function eliminarNota(id) {
  await deleteDoc(doc(db, 'notas', id))
}

// ============ COMPOSABLE ============
export function useCantina() {
  return {
    // estado
    listo,
    usuario,
    productos,
    combos,
    notas,
    pedidos,
    usuariosRegistrados,
    carrito,
    categoriaActiva,
    categorias,
    categoriasMenu,
    categoriasDeKiosco,
    // getters
    todosLosProductos,
    productosVisibles,
    productosFiltrados,
    productosDeCategoria,
    destacados,
    combosVisibles,
    detalleDeCombo,
    esVendedora,
    esMaster,
    esVendedoraOMaster,
    etiquetaRol,
    cantidadTotal,
    totalCarrito,
    ahora,
    almuerzoCerrado,
    esAlmuerzo,
    tieneStock,
    // acciones
    cargar,
    registrar,
    iniciarSesion,
    cerrarSesion,
    agregarAlCarrito,
    agregarComboAlCarrito,
    decrementarCantidad,
    sumarCantidad,
    cambiarNota,
    quitarDelCarrito,
    vaciarCarrito,
    confirmarPago,
    crearPagoMercadoPago,
    escucharPedido,
    calificarPedido,
    agregarProducto,
    editarProducto,
    eliminarProducto,
    guardarCombo,
    cambiarComboActivo,
    eliminarCombo,
    agregarNota,
    editarNota,
    eliminarNota,
  }
}
