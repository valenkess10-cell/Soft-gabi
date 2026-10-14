<script setup>
import { ShoppingCart, X, ShoppingBasket, ArrowRight } from 'lucide-vue-next'
import { resolverImagenUrl } from '../data/catalogo.js'
import { iconoDeEmoji } from '../data/iconos.js'

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
        :key="item.id"
        class="flex items-center justify-between p-3 bg-slate-50 rounded-2xl border border-slate-200 shadow-xs"
      >
        <div class="flex items-center gap-2.5">
          <img
            v-if="resolverImagenUrl(item)"
            :src="resolverImagenUrl(item)"
            :alt="item.nombre"
            class="w-12 h-12 rounded-xl object-cover"
          />
          <div v-else class="w-12 h-12 rounded-xl bg-slate-100 flex items-center justify-center text-slate-400 shrink-0">
            <component :is="iconoDeEmoji(item.emoji)" :size="20" />
          </div>
          <div>
            <h4 class="font-black text-xs text-slate-900 leading-tight">{{ item.nombre }}</h4>
            <p class="text-[11px] text-slate-500 font-bold mt-0.5">Cant: {{ item.cantidad }}</p>
            <p class="text-xs font-black text-sb-red mt-0.5">${{ (item.precio * item.cantidad).toLocaleString('es-AR') }}</p>
          </div>
        </div>
        <button
          @click="$emit('eliminar', item.id)"
          class="text-[11px] bg-red-100 hover:bg-red-200 text-sb-red font-bold px-2.5 py-1 rounded-lg transition-colors cursor-pointer"
        >
          Quitar
        </button>
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
