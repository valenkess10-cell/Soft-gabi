<script setup>
import { ref, computed, onMounted, watch } from 'vue'

import Navbar from './components/Navbar.vue'
import HeroBanner from './components/HeroBanner.vue'
import Categorias from './components/Categorias.vue'
import ProductoCard from './components/ProductoCard.vue'
import CarritoModal from './components/CarritoModal.vue'
import AuthModal from './components/AuthModal.vue'
import PasarelaPagoModal from './components/PasarelaPagoModal.vue'
import TicketModal from './components/TicketModal.vue'
import NutricionSection from './components/NutricionSection.vue'
import VentasSection from './components/VentasSection.vue'

// ============ ESTADOS GENERALES ============
const seccionActiva = ref('inicio')
const categoriaActiva = ref('todos')

const mostrarCarrito = ref(false)
const mostrarAuth = ref(false)
const mostrarPago = ref(false)
const mostrarTicket = ref(false)

const usuario = ref(null)
const numeroTurno = ref(42)
const ultimoTotal = ref(0)

// Historial de pedidos (solo visible para la vendedora)
const pedidos = ref([])

// Solo la cuenta registrada con este rol ve el Panel de Ventas
const esVendedora = computed(() => usuario.value?.rol === 'vendedora')

onMounted(() => {
  const guardado = localStorage.getItem('schoolbite_user')
  if (guardado) usuario.value = JSON.parse(guardado)

  const pedidosGuardados = localStorage.getItem('schoolbite_pedidos')
  if (pedidosGuardados) pedidos.value = JSON.parse(pedidosGuardados)
})

// Si por algún motivo se pierde el rol de vendedora estando en esa sección, volvemos a inicio
watch(esVendedora, (val) => {
  if (!val && seccionActiva.value === 'ventas') {
    seccionActiva.value = 'inicio'
  }
})

// ============ CATEGORÍAS ============
const categorias = ref([
  { id: 'platos', nombre: 'Platos', icon: '🍽️', bg: 'bg-amber-50', border: 'border-amber-200', ring: 'ring-amber-400' },
  { id: 'pizzas', nombre: 'Pizzas', icon: '🍕', bg: 'bg-red-50', border: 'border-red-200', ring: 'ring-red-400' },
  { id: 'empanadas', nombre: 'Empanadas', icon: '🥟', bg: 'bg-orange-50', border: 'border-orange-200', ring: 'ring-orange-400' },
  { id: 'pastas', nombre: 'Pastas', icon: '🍝', bg: 'bg-blue-50', border: 'border-blue-200', ring: 'ring-blue-400' },
  { id: 'tartas', nombre: 'Tartas', icon: '🥧', bg: 'bg-pink-50', border: 'border-pink-200', ring: 'ring-pink-400' },
  { id: 'sin-tacc', nombre: 'Sin TACC', icon: '🌾', bg: 'bg-emerald-50', border: 'border-emerald-200', ring: 'ring-emerald-400' },
])

// Incluye "Todos" para la vista de Menú completo
const categoriasMenu = computed(() => ([
  { id: 'todos', nombre: 'Todos', icon: '⭐', bg: 'bg-slate-100', border: 'border-slate-300', ring: 'ring-slate-400' },
  ...categorias.value
]))

// ============ PRODUCTOS ============
const productos = ref([
  {
    id: 1,
    nombre: 'Pizza Muzzarella',
    descripcion: 'Pizza artesanal a la piedra con abundante muzzarella y aceitunas.',
    precio: 3500,
    img: '/pizza.jpg',
    tag: 'Popular',
    tiempo: 15,
    categoria: 'pizzas',
    categoriaLabel: 'Pizzas',
    destacado: true,
    celiaco: false
  },
  {
    id: 2,
    nombre: 'Empanadas de Jamón y Queso',
    descripcion: 'Empanadas horneadas con queso derretido y jamón.',
    precio: 1200,
    img: '/empanadas.jpg',
    tag: 'Clásico',
    tiempo: 5,
    categoria: 'empanadas',
    categoriaLabel: 'Empanadas',
    destacado: true,
    celiaco: false
  },
  {
    id: 3,
    nombre: 'Spaghetti a la Boloñesa',
    descripcion: 'Pasta casera acompañada de una exquisita salsa boloñesa.',
    precio: 2800,
    img: '/fideos.jpg',
    tag: 'Plato del día',
    tiempo: 10,
    categoria: 'pastas',
    categoriaLabel: 'Pastas',
    destacado: true,
    celiaco: false
  },
  {
    id: 4,
    nombre: 'Milanesa con Ensalada',
    descripcion: 'Milanesa dorada y crujiente acompañada de ensalada fresca.',
    precio: 3200,
    img: '/milanesa.jpg',
    tag: 'Recomendado',
    tiempo: 12,
    categoria: 'platos',
    categoriaLabel: 'Platos',
    destacado: false,
    celiaco: false
  },
  {
    id: 5,
    nombre: 'Pechuga de Pollo a la Plancha',
    descripcion: 'Suprema de pollo condimentada con hierbas finas.',
    precio: 3000,
    img: '/pollo.jpg',
    tag: 'Saludable',
    tiempo: 10,
    categoria: 'platos',
    categoriaLabel: 'Platos',
    destacado: true,
    celiaco: true
  },
  {
    id: 6,
    nombre: 'Medallones Rebozados',
    descripcion: 'Medallones súper crujientes con guarnición.',
    precio: 2500,
    img: '/medallon.jpg',
    tag: 'Rápido',
    tiempo: 8,
    categoria: 'platos',
    categoriaLabel: 'Platos',
    destacado: false,
    celiaco: false
  },
  {
    id: 7,
    nombre: 'Tarta de Jamón y Queso',
    descripcion: 'Porción de tarta casera dorada al horno.',
    precio: 2200,
    img: '/tarta.jpg',
    tag: 'Casero',
    tiempo: 5,
    categoria: 'tartas',
    categoriaLabel: 'Tartas',
    destacado: false,
    celiaco: false
  }
])

const destacados = computed(() => productos.value.filter(p => p.destacado))

const productosFiltrados = computed(() => {
  if (categoriaActiva.value === 'todos') return productos.value
  if (categoriaActiva.value === 'sin-tacc') return productos.value.filter(p => p.celiaco)
  return productos.value.filter(p => p.categoria === categoriaActiva.value)
})

// ============ CARRITO ============
const carrito = ref([])

const cantidadTotal = computed(() => carrito.value.reduce((acc, item) => acc + item.cantidad, 0))
const totalCarrito = computed(() => carrito.value.reduce((acc, item) => acc + (item.precio * item.cantidad), 0))

const agregarAlCarrito = (prod) => {
  const existe = carrito.value.find(i => i.id === prod.id)
  if (existe) {
    existe.cantidad++
  } else {
    carrito.value.push({ ...prod, cantidad: 1 })
  }
  mostrarCarrito.value = true
}

const eliminarDelCarrito = (id) => {
  carrito.value = carrito.value.filter(i => i.id !== id)
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
const loginExitoso = (u) => {
  usuario.value = u
  mostrarAuth.value = false
}

const logout = () => {
  localStorage.removeItem('schoolbite_user')
  usuario.value = null
  if (seccionActiva.value === 'ventas') seccionActiva.value = 'inicio'
}

// ============ CHECKOUT ============
const irAPagar = () => {
  mostrarCarrito.value = false
  ultimoTotal.value = totalCarrito.value
  mostrarPago.value = true
}

const pagoExitoso = (tipoPago) => {
  // Guardamos el pedido para que la vendedora lo vea en su Panel de Ventas
  const nuevoPedido = {
    numero: numeroTurno.value,
    fecha: new Date().toLocaleString('es-AR'),
    cliente: usuario.value?.nombre || 'Invitado',
    items: carrito.value.map(i => ({ nombre: i.nombre, cantidad: i.cantidad })),
    total: ultimoTotal.value,
    metodoPago: tipoPago === 'transferencia' ? 'Transferencia / QR' : 'Efectivo en caja'
  }
  pedidos.value.unshift(nuevoPedido)
  localStorage.setItem('schoolbite_pedidos', JSON.stringify(pedidos.value))

  mostrarPago.value = false
  numeroTurno.value++
  mostrarTicket.value = true
}

const reiniciar = () => {
  mostrarTicket.value = false
  carrito.value = []
}
</script>

<template>
  <div class="min-h-screen bg-sb-bg font-sans">

    <!-- NAVBAR -->
    <Navbar
      :cantidad-carrito="cantidadTotal"
      :seccion-activa="seccionActiva"
      :usuario="usuario"
      :es-vendedora="esVendedora"
      @cambiar-seccion="cambiarSeccion"
      @abrir-carrito="mostrarCarrito = true"
      @abrir-auth="mostrarAuth = true"
      @logout="logout"
    />

    <!-- ============ INICIO ============ -->
    <template v-if="seccionActiva === 'inicio'">
      <HeroBanner @ver-menu="cambiarSeccion('menu')" @crear-cuenta="mostrarAuth = true" />

      <Categorias
        :categorias="categorias"
        :categoria-activa="categoriaActiva === 'todos' ? '' : categoriaActiva"
        @seleccionar-categoria="irAMenuConCategoria"
      />

      <section class="max-w-6xl mx-auto px-6 pb-16">
        <div class="flex items-center justify-between mb-5">
          <h2 class="text-xl sm:text-2xl font-black text-slate-900 flex items-center gap-2">
            <span class="text-amber-400">⭐</span> Destacados del día
          </h2>
          <button
            @click="cambiarSeccion('menu')"
            class="text-sm font-bold text-sb-red hover:underline cursor-pointer whitespace-nowrap"
          >
            Ver todos →
          </button>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <ProductoCard
            v-for="p in destacados"
            :key="p.id"
            :producto="p"
            @agregar="agregarAlCarrito"
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
        <div v-if="productosFiltrados.length" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <ProductoCard
            v-for="p in productosFiltrados"
            :key="p.id"
            :producto="p"
            @agregar="agregarAlCarrito"
          />
        </div>
        <div v-else class="text-center py-20">
          <span class="text-4xl block mb-2">🍽️</span>
          <p class="text-slate-400 font-bold text-sm">No hay productos en esta categoría todavía.</p>
        </div>
      </section>
    </template>

    <!-- ============ NUTRICIÓN ============ -->
    <template v-else-if="seccionActiva === 'nutricion'">
      <NutricionSection />
    </template>

    <!-- ============ PANEL DE VENTAS (solo vendedora) ============ -->
    <template v-else-if="seccionActiva === 'ventas' && esVendedora">
      <VentasSection :pedidos="pedidos" />
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
      @eliminar="eliminarDelCarrito"
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
      @cerrar="mostrarPago = false"
      @pago-exitoso="pagoExitoso"
    />

    <TicketModal
      :mostrar="mostrarTicket"
      :numero-pedido="numeroTurno"
      :total="ultimoTotal"
      @cerrar="reiniciar"
    />

  </div>
</template>
