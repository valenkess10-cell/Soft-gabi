<script setup>
import { ref, computed, onMounted } from 'vue'
import Navbar from './components/Navbar.vue'
import HeroBanner from './components/HeroBanner.vue'
import Categorias from './components/Categorias.vue'
import ProductoCard from './components/ProductoCard.vue'
import NutricionSection from './components/NutricionSection.vue'
import CarritoModal from './components/CarritoModal.vue'
import TicketModal from './components/TicketModal.vue'
import AuthModal from './components/AuthModal.vue'
import PasarelaPagoModal from './components/PasarelaPagoModal.vue'

const seccionActiva = ref('inicio')

const categorias = ref([
  { id: 0, nombre: 'Todos', icon: '✨' },
  { id: 6, nombre: 'Frutas', icon: '🍎' },
  { id: 1, nombre: 'Sándwiches', icon: '🥪' },
  { id: 2, nombre: 'Empanadas', icon: '🥟' },
  { id: 3, nombre: 'Bebidas', icon: '🥤' },
  { id: 4, nombre: 'Snacks/Papas', icon: '🍟' },
  { id: 5, nombre: 'Postres', icon: '🍦' }
])

const categoriaSeleccionada = ref(0)

const productos = ref([
  { id: 101, categoriaId: 6, nombre: 'Ensalada de Frutas Fresca', descripcion: 'Combinación fresca de frutilla, kiwi, banana, manzana y jugo natural.', precio: 1500, tiempo: 2, img: 'https://images.unsplash.com/photo-1519996529931-28324d5a630e?q=80&w=500&auto=format&fit=crop', tag: 'Sin TACC', celiaco: true },
  { id: 102, categoriaId: 6, nombre: 'Manzana / Banana Fresca', descripcion: 'Fruta de estación seleccionada y desinfectada.', precio: 600, tiempo: 1, img: 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?q=80&w=500&auto=format&fit=crop', tag: 'Sin TACC', celiaco: true },
  { id: 103, categoriaId: 6, nombre: 'Licuado de Frutas Naturales', descripcion: 'Licuado de banana con agua o leche apta sin TACC (500ml).', precio: 1800, tiempo: 3, img: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?q=80&w=500&auto=format&fit=crop', tag: 'Sin TACC', celiaco: true },
  { id: 104, categoriaId: 6, nombre: 'Yogurt con Frutas (Apto)', descripcion: 'Yogurt libre de gluten bañado en trozos de manzana y banana.', precio: 1900, tiempo: 2, img: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?q=80&w=500&auto=format&fit=crop', tag: 'Sin TACC', celiaco: true },
  { id: 201, categoriaId: 1, nombre: 'Sándwich Sin TACC de Jamón y Queso', descripcion: 'Elaborado en pan de fécula de mandioca sellado individualmente.', precio: 2800, tiempo: 5, img: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?q=80&w=500&auto=format&fit=crop', tag: 'Sin TACC', celiaco: true },
  { id: 202, categoriaId: 2, nombre: 'Empanada de Queso Sin TACC', descripcion: 'Masa especial sin gluten con relleno horneado.', precio: 1600, tiempo: 6, img: 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?q=80&w=500&auto=format&fit=crop', tag: 'Sin TACC', celiaco: true },
  { id: 1, categoriaId: 1, nombre: 'Hamburguesa Completa', descripcion: 'Carne, queso, lechuga, tomate y aderezo especial.', precio: 2500, tiempo: 8, img: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=500&auto=format&fit=crop', tag: 'Popular', celiaco: false },
  { id: 4, categoriaId: 1, nombre: 'Sándwich de Milanesa', descripcion: 'Milanesa de carne en pan francés tierno.', precio: 3000, tiempo: 10, img: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?q=80&w=500&auto=format&fit=crop', tag: 'Clásico', celiaco: false },
  { id: 6, categoriaId: 4, nombre: 'Papas Fritas Con Queso', descripcion: 'Porción grande con salsa cheddar de la casa.', precio: 1800, tiempo: 6, img: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?q=80&w=500&auto=format&fit=crop', tag: 'Crujiente', celiaco: false },
  { id: 7, categoriaId: 3, nombre: 'Jugo Natural de Naranja', descripcion: 'Exprimido 100% natural sin azúcar agregada 500ml.', precio: 1200, tiempo: 2, img: 'https://images.unsplash.com/photo-1613478223719-2ab802602423?q=80&w=500&auto=format&fit=crop', tag: 'Sin TACC', celiaco: true },
  { id: 8, categoriaId: 5, nombre: 'Helado Soft Vainilla', descripcion: 'Vaso de helado suave de vainilla.', precio: 900, tiempo: 2, img: 'https://images.unsplash.com/photo-1570197788417-0e82375c9371?q=80&w=500&auto=format&fit=crop', tag: 'Dulce', celiaco: false }
])

const carrito = ref([])
const mostrarCarrito = ref(false)
const mostrarPago = ref(false)
const mostrarTicket = ref(false)
const numeroTurno = ref(42)

const mostrarAuth = ref(false)
const usuarioActual = ref(null)

onMounted(() => {
  const usuarioGuardado = localStorage.getItem('micantina_user')
  if (usuarioGuardado) {
    usuarioActual.value = JSON.parse(usuarioGuardado)
  }
})

const productosFiltrados = computed(() => {
  if (categoriaSeleccionada.value === 0) return productos.value
  return productos.value.filter(p => p.categoriaId === categoriaSeleccionada.value)
})

const productosCeliacos = computed(() => {
  return productos.value.filter(p => p.celiaco)
})

const totalCarrito = computed(() => {
  return carrito.value.reduce((acc, item) => acc + (item.precio * item.cantidad), 0)
})

const cantidadTotalItems = computed(() => {
  return carrito.value.reduce((acc, item) => acc + item.cantidad, 0)
})

const agregarAlCarrito = (prod) => {
  const existe = carrito.value.find(item => item.id === prod.id)
  if (existe) {
    existe.cantidad++
  } else {
    carrito.value.push({ ...prod, cantidad: 1 })
  }
  mostrarCarrito.value = true
}

const eliminarDelCarrito = (id) => {
  carrito.value = carrito.value.filter(item => item.id !== id)
}

const iniciarProcesoPago = () => {
  mostrarCarrito.value = false
  mostrarPago.value = true
}

const handlePagoExitoso = () => {
  mostrarPago.value = false
  numeroTurno.value += 1
  mostrarTicket.value = true
}

const reiniciarApp = () => {
  mostrarTicket.value = false
  carrito.value = []
}

const handleLoginExitoso = (user) => {
  usuarioActual.value = user
  mostrarAuth.value = false
}

const logout = () => {
  localStorage.removeItem('micantina_user')
  usuarioActual.value = null
}
</script>

<template>
  <div class="min-h-screen bg-[#F4F5F7] text-slate-900 font-sans pb-16 flex">
    
    <div 
      class="flex-1 transition-all duration-300 ease-in-out min-w-0 flex flex-col"
      :class="mostrarCarrito ? 'mr-80 md:mr-96' : 'mr-0'"
    >
      <Navbar 
        :cantidadCarrito="cantidadTotalItems" 
        :seccionActiva="seccionActiva"
        :usuario="usuarioActual"
        @cambiar-seccion="(sec) => seccionActiva = sec"
        @abrir-carrito="mostrarCarrito = !mostrarCarrito" 
        @abrir-auth="mostrarAuth = true"
        @logout="logout"
      />

      <Transition name="fade" mode="out-in">
        
        <!-- VISTA: INICIO -->
        <div v-if="seccionActiva === 'inicio'" key="inicio">
          <HeroBanner />
          
          <Categorias 
            :categorias="categorias" 
            :categoriaActiva="categoriaSeleccionada"
            @seleccionar-categoria="(id) => categoriaSeleccionada = id"
          />

          <main class="max-w-6xl mx-auto px-6 py-10">
            <div class="flex items-center justify-between mb-6">
              <div>
                <h2 class="text-2xl font-black text-slate-900">Menú Destacado - MICANTINA</h2>
                <p class="text-xs text-slate-500 font-semibold">Seleccioná y seguí agregando productos</p>
              </div>
              <span class="text-xs text-white font-black bg-sb-red px-3.5 py-1.5 rounded-full shadow-sm">
                {{ productosFiltrados.length }} opciones
              </span>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
              <ProductoCard 
                v-for="prod in productosFiltrados" 
                :key="prod.id" 
                :producto="prod" 
                @agregar="agregarAlCarrito"
              />
            </div>
          </main>
        </div>

        <!-- VISTA: MENÚ COMPLETO -->
        <div v-else-if="seccionActiva === 'menu'" key="menu" class="max-w-6xl mx-auto px-6 py-10 w-full">
          <div class="mb-8 bg-white p-6 rounded-3xl border border-slate-200 shadow-xs">
            <h1 class="text-3xl font-black text-slate-900">Catálogo Completo</h1>
            <p class="text-xs text-slate-500 font-bold mt-1">Explorá todas las opciones disponibles de la cantina</p>
          </div>

          <Categorias 
            :categorias="categorias" 
            :categoriaActiva="categoriaSeleccionada"
            @seleccionar-categoria="(id) => categoriaSeleccionada = id"
          />

          <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6 mt-6">
            <ProductoCard 
              v-for="prod in productosFiltrados" 
              :key="prod.id" 
              :producto="prod" 
              @agregar="agregarAlCarrito"
            />
          </div>
        </div>

        <!-- VISTA: NUTRICIÓN -->
        <div v-else-if="seccionActiva === 'nutricion'" key="nutricion" class="w-full">
          <NutricionSection />
        </div>

        <!-- VISTA NUEVA: CELÍACOS / SIN TACC -->
        <div v-else-if="seccionActiva === 'celiacos'" key="celiacos" class="max-w-6xl mx-auto px-6 py-10 w-full">
          <div class="mb-8 bg-amber-500/10 border border-amber-300 p-6 rounded-3xl flex items-center justify-between">
            <div>
              <span class="bg-amber-500 text-white text-[10px] font-black px-3 py-1 rounded-full uppercase">
                Apto Gluten Free
              </span>
              <h1 class="text-3xl font-black text-amber-950 mt-2">Comida para Celíacos (Sin TACC)</h1>
              <p class="text-xs text-amber-900 font-semibold mt-1">
                Alimentos manipulados bajo protocolos anti contaminación cruzada y empaquetados individualmente.
              </p>
            </div>
            <span class="text-5xl">🌾</span>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
            <ProductoCard 
              v-for="prod in productosCeliacos" 
              :key="prod.id" 
              :producto="prod" 
              @agregar="agregarAlCarrito"
            />
          </div>
        </div>

      </Transition>
    </div>

    <!-- Carrito Lateral -->
    <CarritoModal 
      :mostrar="mostrarCarrito" 
      :items="carrito" 
      :total="totalCarrito"
      @cerrar="mostrarCarrito = false"
      @eliminar="eliminarDelCarrito"
      @finalizar="iniciarProcesoPago"
    />

    <!-- Modal de Pago (lata.isae) -->
    <PasarelaPagoModal
      :mostrar="mostrarPago"
      :total="totalCarrito"
      @cerrar="mostrarPago = false"
      @pago-exitoso="handlePagoExitoso"
    />

    <!-- Ticket Modal -->
    <TicketModal 
      :mostrar="mostrarTicket" 
      :numeroPedido="numeroTurno"
      :total="totalCarrito"
      @cerrar="reiniciarApp"
    />

    <!-- Modal Autenticación -->
    <AuthModal
      :mostrar="mostrarAuth"
      @cerrar="mostrarAuth = false"
      @login-exitoso="handleLoginExitoso"
    />
  </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(6px);
}
</style>