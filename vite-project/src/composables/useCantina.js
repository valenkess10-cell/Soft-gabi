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
} from 'firebase/firestore'
import { auth, db } from '../firebase.js'
import { categorias, categoriasDeKiosco, productosSemilla } from '../data/catalogo.js'

// Cuentas fijas de personal, iguales a las de cantina_provider.dart.
const EMAIL_VENDEDORA = 'vendedora@micantina.com'
const CLAVE_VENDEDORA = 'Vendedora2026'
const EMAIL_MASTER = 'master@micantina.com'
const CLAVE_MASTER = 'Cantina2026'

// ============ ESTADO COMPARTIDO ============
const listo = ref(false)
const usuario = ref(null) // { uid, nombre, email, rol }
const productos = ref([])
const pedidos = ref([])
const usuariosRegistrados = ref([])
const carrito = ref([])
const categoriaActiva = ref('todos')

let desuscribirProductos = null
let desuscribirPedidos = null
let desuscribirUsuarios = null
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
    if (fbUser.isAnonymous) {
      usuario.value = null
      pararEscuchasDeRol()
      listo.value = true
      return
    }
    await _aplicarUsuario(fbUser)
    listo.value = true
  })

  _escucharProductos()
}

function _escucharProductos() {
  const refProductos = collection(db, 'productos')
  desuscribirProductos = onSnapshot(refProductos, (snap) => {
    productos.value = snap.docs.map((d) => _productoDeDocumento(d.id, d.data()))
  })
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
  }
}

function pararEscuchasDeRol() {
  if (desuscribirPedidos) { desuscribirPedidos(); desuscribirPedidos = null }
  if (desuscribirUsuarios) { desuscribirUsuarios(); desuscribirUsuarios = null }
  pedidos.value = []
  usuariosRegistrados.value = []
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
      return { id: d.id, ...data, fecha }
    })
  })
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
const totalCarrito = computed(() => carrito.value.reduce((acc, i) => acc + i.precio * i.cantidad, 0))

function agregarAlCarrito(prod) {
  const existente = carrito.value.find((i) => i.id === prod.id)
  if (existente) existente.cantidad++
  else carrito.value.push({ ...prod, cantidad: 1 })
}

function decrementarCantidad(id) {
  const existente = carrito.value.find((i) => i.id === id)
  if (!existente) return
  if (existente.cantidad > 1) existente.cantidad--
  else quitarDelCarrito(id)
}

function quitarDelCarrito(id) {
  carrito.value = carrito.value.filter((i) => i.id !== id)
}

function vaciarCarrito() {
  carrito.value = []
}

// ============ PEDIDOS / PAGO ============
// Usa una transacción para que el número de turno diario sea atómico y
// correlativo, igual que confirmarPago() en cantina_provider.dart.
async function confirmarPago(metodoPago, detallePago) {
  const hoy = new Date()
  const fechaStr = `${hoy.getFullYear()}-${String(hoy.getMonth() + 1).padStart(2, '0')}-${String(hoy.getDate()).padStart(2, '0')}`

  const numero = await runTransaction(db, async (tx) => {
    const refContador = doc(db, 'contadores', 'turnos')
    const snap = await tx.get(refContador)
    let siguiente = 1
    if (snap.exists() && snap.data().fecha === fechaStr) {
      siguiente = (snap.data().ultimo ?? 0) + 1
    }
    tx.set(refContador, { fecha: fechaStr, ultimo: siguiente })

    const refPedido = doc(collection(db, 'pedidos'))
    tx.set(refPedido, {
      numero: siguiente,
      fecha: serverTimestamp(),
      cliente: usuario.value?.nombre || 'Invitado',
      uid: auth.currentUser?.uid || null,
      items: carrito.value.map((i) => ({ nombre: i.nombre, cantidad: i.cantidad })),
      total: totalCarrito.value,
      metodoPago,
      pagaCon: detallePago?.pagaCon ?? null,
      vuelto: detallePago?.vuelto ?? null,
      calificacion: null,
      comentario: null,
    })

    return siguiente
  })

  vaciarCarrito()
  return numero
}

async function calificarPedido(pedidoId, calificacion, comentario) {
  await updateDoc(doc(db, 'pedidos', pedidoId), { calificacion, comentario })
}

// ============ CRUD DE PRODUCTOS (vendedora / master) ============
// Sentinela para distinguir "no me pasaron este campo, dejalo como estaba"
// de "me pasaron explícitamente null", igual que en producto.dart.
export const sinCambioImagen = Symbol('sinCambioImagen')

async function agregarProducto({ nombre, descripcion, precio, categoria, categoriaLabel, imagenBase64, emoji, tiempo, esSinTacc, stock }) {
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

// ============ COMPOSABLE ============
export function useCantina() {
  return {
    // estado
    listo,
    usuario,
    productos,
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
    decrementarCantidad,
    quitarDelCarrito,
    vaciarCarrito,
    confirmarPago,
    calificarPedido,
    agregarProducto,
    editarProducto,
    eliminarProducto,
  }
}
