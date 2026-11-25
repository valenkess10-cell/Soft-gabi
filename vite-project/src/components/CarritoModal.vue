<script setup>
import { ShoppingCart, X, ShoppingBasket, ArrowRight, Minus, Plus, Trash2, Package } from 'lucide-vue-next'
import { resolverImagenUrl } from '../data/catalogo.js'
import { iconoDeEmoji } from '../data/iconos.js'
import { useCantina } from '../composables/useCantina.js'

const { sumarCantidad, decrementarCantidad, cambiarNota } = useCantina()

defineProps({
  mostrar: Boolean,
  items: Array,
  total: Number
})

defineEmits(['cerrar', 'eliminar', 'finalizar'])
</script>

<template>
  <aside
    class="fixed top-0 right-0 z-40 h-full w-80 md:w-96 bg-white border-l border-slate-200 shadow-2xl transition-transform duration-300 ease-in-out flex flex-col justify-between"
    :class="mostrar ? 'translate-x-0' : 'translate-x-full'"
  >
    <!-- Header -->
    <div class="p-5 border-b border-slate-100 flex items-center justify-between bg-slate-50">
      <div class="flex items-center gap-2">
        <ShoppingCart :size="20" class="text-slate-700" />
        <h3 class="text-lg font-black text-slate-900">Tu Pedido</h3>
      </div>
      <button
        @click="$emit('cerrar')"
        class="w-7 h-7 rounded-full bg-slate-200 hover:bg-slate-300 text-slate-700 font-black text-xs flex items-center justify-center transition-colors cursor-pointer"
      >
        <X :size="14" />
      </button>
    </div>

    <!-- Lista de Productos -->
    <div v-if="items.length > 0" class="flex-1 overflow-y-auto p-4 space-y-3">
      <div
        v-for="item in items"
        :key="item.clave"
        class="p-3 bg-slate-50 rounded-2xl border border-slate-200 shadow-xs space-y-2"
      >
        <div class="flex items-start gap-2.5">
          <img
            v-if="resolverImagenUrl(item)"
            :src="resolverImagenUrl(item)"
            :alt="item.nombre"
            class="w-12 h-12 rounded-xl object-cover shrink-0"
          />
          <div v-else class="w-12 h-12 rounded-xl bg-slate-100 flex items-center justify-center text-slate-400 shrink-0">
            <Package v-if="item.tipo === 'combo'" :size="20" />
            <component :is="iconoDeEmoji(item.emoji)" v-else :size="20" />
          </div>
          <div class="flex-1 min-w-0">
            <h4 class="font-black text-xs text-slate-900 leading-tight">
              <span v-if="item.tipo === 'combo'" class="text-[9px] font-black bg-amber-300 text-slate-900 px-1.5 py-0.5 rounded mr-1">COMBO</span>{{ item.nombre }}
            </h4>
            <p v-if="item.detalle?.length" class="text-[11px] text-slate-500 font-medium mt-0.5">{{ item.detalle.join(' · ') }}</p>
            <p v-for="o in item.opciones" :key="o.id" class="text-[11px] text-slate-600 font-bold mt-0.5">
              + {{ o.nombre }}<span v-if="o.precio > 0"> (${{ o.precio.toLocaleString('es-AR') }})</span>
            </p>
            <p class="text-xs font-black text-sb-red mt-1">${{ (item.precioUnitario * item.cantidad).toLocaleString('es-AR') }}</p>
          </div>
          <div class="flex items-center gap-1 shrink-0">
            <button
              @click="decrementarCantidad(item.clave)"
              class="w-7 h-7 rounded-lg bg-white border border-slate-200 hover:bg-slate-100 text-slate-600 flex items-center justify-center cursor-pointer"
              :aria-label="item.cantidad === 1 ? 'Quitar' : 'Restar uno'"
            >
              <Trash2 v-if="item.cantidad === 1" :size="13" class="text-sb-red" />
              <Minus v-else :size="13" />
            </button>
            <span class="w-5 text-center text-xs font-black">{{ item.cantidad }}</span>
            <button
              @click="sumarCantidad(item.clave)"
              class="w-7 h-7 rounded-lg bg-white border border-slate-200 hover:bg-slate-100 text-slate-600 flex items-center justify-center cursor-pointer"
              aria-label="Sumar uno"
            >
              <Plus :size="13" />
            </button>
          </div>
        </div>
        <input
          v-if="item.tipo === 'producto'"
          :value="item.nota"
          @input="cambiarNota(item.clave, $event.target.value)"
          maxlength="140"
          placeholder="Aclaración (ej: sin mayonesa)"
          class="w-full px-3 py-1.5 rounded-lg border border-slate-200 bg-white text-[11px] font-medium focus:outline-none focus:ring-2 focus:ring-sb-red"
        />
      </div>
    </div>

    <div v-else class="flex-1 flex flex-col items-center justify-center p-6 text-center">
      <ShoppingBasket :size="40" class="text-slate-300 mb-2" />
      <p class="text-slate-800 font-black text-sm">El carrito está vacío</p>
      <p class="text-slate-400 text-xs mt-1">Elegí productos del menú para ir sumándolos.</p>
    </div>

    <!-- Footer / Checkout -->
    <div v-if="items.length > 0" class="p-5 border-t border-slate-200 bg-slate-50">
      <div class="flex justify-between items-center mb-3">
        <span class="font-bold text-slate-600 text-xs">Total acumulado:</span>
        <span class="text-xl font-black text-sb-red">${{ total.toLocaleString('es-AR') }}</span>
      </div>

      <button
        @click="$emit('finalizar')"
        class="w-full bg-sb-red hover:bg-red-700 active:scale-95 text-white font-black py-3 rounded-xl text-xs shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer"
      >
        <span>Confirmar Pedido</span>
        <ArrowRight :size="14" />
      </button>
    </div>
  </aside>
</template>
