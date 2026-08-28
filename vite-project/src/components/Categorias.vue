<script setup>
defineProps({
  categorias: Array,
  categoriaActiva: Number
})

defineEmits(['seleccionar-categoria'])
</script>

<template>
  <section class="py-6 bg-white border-b border-gray-100 shadow-sm sticky top-[69px] z-30">
    <div class="max-w-6xl mx-auto px-6">
      <div class="flex items-center gap-4 sm:gap-8 overflow-x-auto pb-2 scrollbar-none">
        <button
          v-for="cat in categorias"
          :key="cat.id"
          @click="$emit('seleccionar-categoria', cat.id)"
          class="flex flex-col items-center min-w-[80px] group focus:outline-none transition-transform active:scale-95"
        >
          <div 
            :class="[
              'w-14 h-14 sm:w-16 sm:h-16 rounded-2xl flex items-center justify-center text-2xl transition-all mb-1.5 shadow-sm',
              categoriaActiva === cat.id 
                ? 'bg-mcd-yellow text-black scale-105 ring-2 ring-mcd-yellow ring-offset-2' 
                : 'bg-gray-100 group-hover:bg-gray-200 text-gray-700'
            ]"
          >
            {{ cat.icon }}
          </div>
          <span 
            :class="[
              'text-xs font-bold text-center transition-colors whitespace-nowrap',
              categoriaActiva === cat.id ? 'text-black' : 'text-gray-500 group-hover:text-black'
            ]"
          >
            {{ cat.nombre }}
          </span>
        </button>
      </div>
    </div>
  </section>
</template>