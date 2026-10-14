<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { UtensilsCrossed, Star, ArrowRight } from 'lucide-vue-next'

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
  quitarDelCarrito,
  confirmarPago,
} = useCantina()

cargar()

// ============ ESTADOS DE NAVEGACIÓN / UI ============
const seccionActiva = ref('inicio')

const mostrarCarrito = ref(false)
const mostrarAuth = ref(false)
const mostrarPago = ref(false)
const mostrarTicket = ref(false)
const mostrarProductosAdmin = ref(false)

const ultimoTotal = ref(0)
const ultimoNumeroPedido = ref(0)

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

const pagoExitoso = async (metodoPagoLabel) => {
  const numero = await confirmarPago(metodoPagoLabel)
  ultimoNumeroPedido.value = numero
  mostrarPago.value = false
  mostrarTicket.value = true
}

const reiniciar = () => {
  mostrarTicket.value = false
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
          @agregar="agregarAlCarrito"
        />
      </template>

      <!-- ============ BEBIDAS ============ -->
      <template v-else-if="seccionActiva === 'bebidas'">
        <CategoriaSection
          titulo="Bebidas"
          categoria-id="bebidas"
          :productos="productosBebidas"
          @agregar="agregarAlCarrito"
        />
      </template>

      <!-- ============ PANEL DE VENTAS (vendedora / master) ============ -->
      <template v-else-if="seccionActiva === 'ventas' && esVendedoraOMaster">
        <VentasSection
          :pedidos="pedidos"
          :usuarios="usuariosRegistrados"
          :es-master="esMaster"
          @abrir-productos="mostrarProductosAdmin = true"
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
        @cerrar="mostrarPago = false"
        @pago-exitoso="pagoExitoso"
      />

      <TicketModal
        :mostrar="mostrarTicket"
        :numero-pedido="ultimoNumeroPedido"
        :total="ultimoTotal"
        @cerrar="reiniciar"
      />

      <ProductosAdminModal
        :mostrar="mostrarProductosAdmin"
        @cerrar="mostrarProductosAdmin = false"
      />
    </template>

  </div>
</template>
