<script setup>
import { computed } from 'vue'
import { resolverImagenUrl } from '../data/catalogo.js'
import { useCantina } from '../composables/useCantina.js'

const props = defineProps({
  producto: Object
})

defineEmits(['agregar'])

const { categoriasDeKiosco } = useCantina()

const urlImagen = computed(() => resolverImagenUrl(props.producto))
const esDeKiosco = computed(() => categoriasDeKiosco.has(props.producto.categoria))
</script>

<template>
  <div class="bg-white rounded-2xl overflow-hidden border border-slate-200 shadow-sm hover:shadow-lg transition-all duration-300 flex flex-col group">
    <div class="relative">
      <img
        v-if="urlImagen"
        :src="urlImagen"
        :alt="producto.nombre"
        class="w-full h-40 object-cover group-hover:scale-105 transition-transform duration-500"
      />
      <div
        v-else
        class="w-full h-40 flex items-center justify-center bg-slate-100 text-5xl group-hover:scale-105 transition-transform duration-500"
      >
        {{ producto.emoji || '🍽️' }}
      </div>

      <span
        v-if="!esDeKiosco"
        class="absolute top-2.5 left-2.5 bg-slate-900/80 backdrop-blur-md text-white text-[10px] font-bold px-2.5 py-1 rounded-full flex items-center gap-1"
      >
        ⏱ {{ producto.tiempo }} min
      </span>
      <span v-if="producto.tag" class="absolute top-2.5 right-2.5 bg-white/95 text-slate-900 text-[10px] font-black px-2.5 py-1 rounded-full shadow-sm">
        {{ producto.tag }}
      </span>
    </div>

    <div class="p-4 flex flex-col flex-1">
      <span class="text-[10px] font-bold uppercase text-slate-400 tracking-wide mb-1">
        {{ producto.categoriaLabel }}
      </span>
      <h3 class="font-black text-sm text-slate-900 leading-snug mb-1">{{ producto.nombre }}</h3>
      <p class="text-xs text-slate-500 mb-4 line-clamp-2 flex-1">{{ producto.descripcion }}</p>

      <div class="flex items-center justify-between mb-3">
        <span class="text-lg font-black text-sb-red">${{ producto.precio.toLocaleString('es-AR') }}</span>
      </div>

      <button
        @click="$emit('agregar', producto)"
        class="w-full bg-sb-yellow hover:bg-sb-yellow-hover active:scale-95 text-slate-900 font-black py-2.5 rounded-xl transition-all text-xs flex items-center justify-center gap-1.5 cursor-pointer"
      >
        <span class="text-sm">+</span>
        <span>Agregar al Carrito</span>
      </button>
    </div>
  </div>
</template>
