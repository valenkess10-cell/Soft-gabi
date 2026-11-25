<script setup>
import { ref, reactive, computed, watch, onBeforeUnmount } from 'vue'
import { UtensilsCrossed, Star, ArrowRight, Package } from 'lucide-vue-next'

import Navbar from './components/Navbar.vue'
import HeroBanner from './components/HeroBanner.vue'
import Categorias from './components/Categorias.vue'
import ProductoCard from './components/ProductoCard.vue'
import CategoriaSection from './components/CategoriaSection.vue'
import CarritoModal from './components/CarritoModal.vue'
import AuthModal from './components/AuthModal.vue'
import PasarelaPagoModal from './components/PasarelaPagoModal.vue'
import TicketModal from './components/TicketModal.vue'
import VentasSection from './components/VentasSection.vue'
import ProductosAdminModal from './components/ProductosAdminModal.vue'
import CombosAdminModal from './components/CombosAdminModal.vue'
import PersonalizarModal from './components/PersonalizarModal.vue'
import ComboCard from './components/ComboCard.vue'
import { useCantina } from './composables/useCantina.js'

const {
  listo,
  usuario,
  pedidos,
  usuariosRegistrados,
  carrito,
  categoriaActiva,
  categoriasMenu,
  destacados,
  combosVisibles,
  productosFiltrados,
  productosDeCategoria,
  esVendedoraOMaster,
  esMaster,
  etiquetaRol,
  cantidadTotal,
  totalCarrito,
  cargar,
  cerrarSesion,
  agregarAlCarrito,
  agregarComboAlCarrito,
  quitarDelCarrito,
  confirmarPago,
  crearPagoMercadoPago,
  escucharPedido,
} = useCantina()

cargar()

// ============ ESTADOS DE NAVEGACIÓN / UI ============
const seccionActiva = ref('inicio')

const mostrarCarrito = ref(false)
const mostrarAuth = ref(false)
const mostrarPago = ref(false)
const mostrarTicket = ref(false)
const mostrarProductosAdmin = ref(false)
const mostrarCombosAdmin = ref(false)
const productoParaPersonalizar = ref(null)

const ultimoTotal = ref(0)
const procesandoPago = ref(false)
const errorPago = ref('')

// Datos del ticket que se muestra al terminar (o al volver de Mercado Pago).
const ticket = reactive({
  pedidoId: null,
  numero: 0,
  total: 0,
  horaRetiro: null,
  metodoPago: '',
  estadoPago: null,
  errorPago: '',
  reintentando: false,
})
let dejarDeEscucharPedido = null
onBeforeUnmount(() => dejarDeEscucharPedido?.())

// Si por algún motivo se pierde el rol de personal estando en esa sección, volvemos a inicio
watch(esVendedoraOMaster, (val) => {
  if (!val && seccionActiva.value === 'ventas') {
    seccionActiva.value = 'inicio'
  }
})

// Categorías para la grilla de Inicio (sin el "Todos" que sí usa el Menú)
const categoriasInicio = computed(() => categoriasMenu.value.filter((c) => c.id !== 'todos'))

const productosDesayuno = computed(() => productosDeCategoria('desayuno'))
const productosBebidas = computed(() => productosDeCategoria('bebidas'))

// Los combos se muestran en Inicio y en el Menú cuando está en "Todos".
const mostrarCombosEnMenu = computed(() => categoriaActiva.value === 'todos' && combosVisibles.value.length > 0)

// ============ AGREGAR AL CARRITO ============
// Si el producto tiene opciones, primero se abre el modal para elegirlas.
const alAgregarProducto = (producto) => {
  if (producto.opciones?.length) productoParaPersonalizar.value = producto
  else agregarAlCarrito(producto)
}

const confirmarPersonalizacion = (producto, opciones, nota) => {
  agregarAlCarrito(producto, opciones, nota)
  productoParaPersonalizar.value = null
}

// ============ NAVEGACIÓN ============
const irArriba = () => window.scrollTo({ top: 0, behavior: 'smooth' })

const cambiarSeccion = (s) => {
  seccionActiva.value = s
  irArriba()
}

const irAMenuConCategoria = (catId) => {
  categoriaActiva.value = catId
  seccionActiva.value = 'menu'
  irArriba()
}

const seleccionarCategoriaMenu = (catId) => {
  categoriaActiva.value = catId
}

// ============ AUTENTICACIÓN ============
const loginExitoso = () => {
  mostrarAuth.value = false
}

const logout = async () => {
  await cerrarSesion()
  if (seccionActiva.value === 'ventas') seccionActiva.value = 'inicio'
}

// ============ CHECKOUT ============
const irAPagar = () => {
  mostrarCarrito.value = false
  ultimoTotal.value = totalCarrito.value
  mostrarPago.value = true
}

function _mostrarTicketDe(pedido) {
  ticket.pedidoId = pedido.id
  ticket.numero = pedido.numero
  ticket.total = pedido.total
  ticket.horaRetiro = pedido.horaRetiro ?? null
  ticket.metodoPago = pedido.metodoPago
  ticket.estadoPago = pedido.estadoPago ?? null
  mostrarTicket.value = true

  // Para Mercado Pago seguimos el pedido en vivo: el estado pasa a
  // "aprobado" cuando el servidor recibe la confirmación del pago.
  dejarDeEscucharPedido?.()
  dejarDeEscucharPedido = null
  if (pedido.metodoPago === 'mercadopago' && pedido.id) {
    dejarDeEscucharPedido = escucharPedido(pedido.id, (actual) => {
      if (!actual) return
      ticket.estadoPago = actual.estadoPago ?? null
      ticket.total = actual.total
      if (actual.estadoPago === 'aprobado') ticket.errorPago = ''
    })
  }
}

async function _irAMercadoPago(pedidoId) {
  const { initPoint } = await crearPagoMercadoPago(pedidoId)
  window.location.href = initPoint
}

const pagoExitoso = async (metodoPago, detalle) => {
  procesandoPago.value = true
  errorPago.value = ''
  let pedido
  try {
    const { id, numero } = await confirmarPago(metodoPago, detalle)
    pedido = {
      id,
      numero,
      total: ultimoTotal.value,
      horaRetiro: detalle?.horaRetiro ?? null,
      metodoPago,
      estadoPago: metodoPago === 'mercadopago' ? 'pendiente' : null,
    }
  } catch (err) {
    console.error('Error al guardar el pedido:', err)
    errorPago.value = 'No se pudo enviar el pedido. Revisá tu conexión e intentá de nuevo.'
    procesandoPago.value = false
    return
  }

  ticket.errorPago = ''
  if (metodoPago === 'mercadopago') {
    try {
      await _irAMercadoPago(pedido.id)
      return // el navegador se va a Mercado Pago
    } catch (err) {
      console.error('Error al crear el pago de Mercado Pago:', err)
      ticket.errorPago = 'No se pudo abrir Mercado Pago. Tu pedido quedó guardado: probá de nuevo.'
    }
  }
  procesandoPago.value = false
  mostrarPago.value = false
  _mostrarTicketDe(pedido)
}

const reintentarPago = async () => {
  if (!ticket.pedidoId) return
  ticket.reintentando = true
  ticket.errorPago = ''
  try {
    await _irAMercadoPago(ticket.pedidoId)
  } catch (err) {
    console.error('Error al reintentar Mercado Pago:', err)
    ticket.errorPago = 'No se pudo abrir Mercado Pago. Probá de nuevo en un rato.'
    ticket.reintentando = false
  }
}

const reiniciar = () => {
  mostrarTicket.value = false
  dejarDeEscucharPedido?.()
  dejarDeEscucharPedido = null
}

// Al volver de Mercado Pago, la URL trae ?pedido=ID: mostramos su ticket.
const pedidoDeRetorno = new URLSearchParams(window.location.search).get('pedido')
if (pedidoDeRetorno) {
  window.history.replaceState({}, '', window.location.pathname)
  const parar = watch(listo, (ok) => {
    if (!ok) return
    parar()
    const dejar = escucharPedido(pedidoDeRetorno, (pedido) => {
      dejar()
      if (pedido) _mostrarTicketDe(pedido)
    })
  }, { immediate: true })
}
</script>

<template>
  <div class="min-h-screen bg-sb-bg font-sans">

    <div v-if="!listo" class="min-h-screen flex items-center justify-center">
      <UtensilsCrossed :size="36" class="text-slate-300 animate-pulse" />
    </div>

    <template v-else>
      <!-- NAVBAR -->
      <Navbar
        :cantidad-carrito="cantidadTotal"
        :seccion-activa="seccionActiva"
        :usuario="usuario"
        :es-vendedora-o-master="esVendedoraOMaster"
        :etiqueta-rol="etiquetaRol"
        @cambiar-seccion="cambiarSeccion"
        @abrir-carrito="mostrarCarrito = true"
        @abrir-auth="mostrarAuth = true"
        @logout="logout"
      />

      <!-- ============ INICIO ============ -->
      <template v-if="seccionActiva === 'inicio'">
        <HeroBanner @ver-menu="cambiarSeccion('menu')" @crear-cuenta="mostrarAuth = true" />

        <section v-if="combosVisibles.length" class="max-w-6xl mx-auto px-6 pt-10">
          <h2 class="text-xl sm:text-2xl font-black text-slate-900 flex items-center gap-2 mb-5">
            <Package :size="20" class="text-amber-500" /> Combos
          </h2>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            <ComboCard v-for="c in combosVisibles" :key="c.id" :combo="c" @agregar="agregarComboAlCarrito" />
          </div>
        </section>

        <Categorias
          :categorias="categoriasInicio"
          :categoria-activa="categoriaActiva === 'todos' ? '' : categoriaActiva"
          @seleccionar-categoria="irAMenuConCategoria"
        />

        <section class="max-w-6xl mx-auto px-6 pb-16">
          <div class="flex items-center justify-between mb-5">
            <h2 class="text-xl sm:text-2xl font-black text-slate-900 flex items-center gap-2">
              <Star :size="20" class="text-amber-400 fill-amber-400" /> Destacados del día
            </h2>
            <button
              @click="cambiarSeccion('menu')"
              class="text-sm font-bold text-sb-red hover:underline cursor-pointer whitespace-nowrap flex items-center gap-1"
            >
              Ver todos <ArrowRight :size="14" />
            </button>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            <ProductoCard
              v-for="p in destacados"
              :key="p.id"
              :producto="p"
              @agregar="alAgregarProducto"
            />
          </div>
        </section>
      </template>

      <!-- ============ MENÚ COMPLETO ============ -->
      <template v-else-if="seccionActiva === 'menu'">
        <section class="pt-10 pb-2">
          <div class="max-w-6xl mx-auto px-6 text-center">
            <h1 class="text-2xl sm:text-3xl font-black text-slate-900">¿Qué querés comer hoy?</h1>
            <p class="text-sm text-slate-500 font-medium mt-1">Elegí tu categoría favorita y hacé tu pedido.</p>
          </div>
        </section>

        <Categorias
          :categorias="categoriasMenu"
          :categoria-activa="categoriaActiva"
          :mostrar-encabezado="false"
          @seleccionar-categoria="seleccionarCategoriaMenu"
        />

        <section class="max-w-6xl mx-auto px-6 pb-16">
          <div v-if="mostrarCombosEnMenu" class="mb-10">
            <h2 class="text-lg font-black text-slate-900 flex items-center gap-2 mb-4">
              <Package :size="18" class="text-amber-500" /> Combos
            </h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
              <ComboCard v-for="c in combosVisibles" :key="c.id" :combo="c" @agregar="agregarComboAlCarrito" />
            </div>
          </div>
          <div v-if="productosFiltrados.length" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
            <ProductoCard
              v-for="p in productosFiltrados"
              :key="p.id"
              :producto="p"
              @agregar="alAgregarProducto"
            />
          </div>
          <div v-else class="text-center py-20">
            <UtensilsCrossed :size="40" class="text-slate-300 mx-auto mb-2" />
            <p class="text-slate-400 font-bold text-sm">No hay productos en esta categoría todavía.</p>
          </div>
        </section>
      </template>

      <!-- ============ DESAYUNO ============ -->
      <template v-else-if="seccionActiva === 'desayuno'">
        <CategoriaSection
          titulo="Desayuno y Merienda"
          categoria-id="desayuno"
          :productos="productosDesayuno"
          @agregar="alAgregarProducto"
        />
      </template>

      <!-- ============ BEBIDAS ============ -->
      <template v-else-if="seccionActiva === 'bebidas'">
        <CategoriaSection
          titulo="Bebidas"
          categoria-id="bebidas"
          :productos="productosBebidas"
          @agregar="alAgregarProducto"
        />
      </template>

      <!-- ============ PANEL DE VENTAS (vendedora / master) ============ -->
      <template v-else-if="seccionActiva === 'ventas' && esVendedoraOMaster">
        <VentasSection
          :pedidos="pedidos"
          :usuarios="usuariosRegistrados"
          :es-master="esMaster"
          @abrir-productos="mostrarProductosAdmin = true"
          @abrir-combos="mostrarCombosAdmin = true"
        />
      </template>

      <!-- ============ CARRITO (DRAWER) ============ -->
      <div
        v-if="mostrarCarrito"
        @click="mostrarCarrito = false"
        class="fixed inset-0 bg-slate-900/40 backdrop-blur-xs z-30"
      ></div>

      <CarritoModal
        :mostrar="mostrarCarrito"
        :items="carrito"
        :total="totalCarrito"
        @cerrar="mostrarCarrito = false"
        @eliminar="quitarDelCarrito"
        @finalizar="irAPagar"
      />

      <!-- ============ MODALES ============ -->
      <AuthModal
        :mostrar="mostrarAuth"
        @cerrar="mostrarAuth = false"
        @login-exitoso="loginExitoso"
      />

      <PasarelaPagoModal
        :mostrar="mostrarPago"
        :total="ultimoTotal"
        :procesando="procesandoPago"
        :error="errorPago"
        @cerrar="mostrarPago = false"
        @pago-exitoso="pagoExitoso"
      />

      <TicketModal
        :mostrar="mostrarTicket"
        :numero-pedido="ticket.numero"
        :total="ticket.total"
        :hora-retiro="ticket.horaRetiro"
        :metodo-pago="ticket.metodoPago"
        :estado-pago="ticket.estadoPago"
        :error-pago="ticket.errorPago"
        :reintentando="ticket.reintentando"
        @cerrar="reiniciar"
        @reintentar-pago="reintentarPago"
      />

      <PersonalizarModal
        :producto="productoParaPersonalizar"
        @cerrar="productoParaPersonalizar = null"
        @confirmar="confirmarPersonalizacion"
      />

      <ProductosAdminModal
        :mostrar="mostrarProductosAdmin"
        @cerrar="mostrarProductosAdmin = false"
      />

      <CombosAdminModal
        :mostrar="mostrarCombosAdmin"
        @cerrar="mostrarCombosAdmin = false"
      />
    </template>

  </div>
</template>
