<script setup>
defineProps({
  producto: Object
})

defineEmits(['agregar'])
</script>

<template>
  <div class="bg-white rounded-3xl overflow-hidden border border-slate-200 shadow-sm hover:shadow-xl transition-all duration-300 flex flex-col justify-between p-3.5 group">
    <div>
      <div class="relative rounded-2xl overflow-hidden mb-3">
        <img 
          :src="producto.img" 
          :alt="producto.nombre" 
          class="w-full h-44 object-cover group-hover:scale-105 transition-transform duration-500" 
        />
        <span class="absolute top-2.5 left-2.5 bg-sb-red text-white text-[10px] font-black px-2.5 py-1 rounded-full shadow-md">
          {{ producto.tag }}
        </span>
        <span class="absolute top-2.5 right-2.5 bg-slate-900/80 backdrop-blur-md text-amber-300 text-[10px] font-black px-2.5 py-1 rounded-full shadow-md">
          ⚡ {{ producto.tiempo }} min
        </span>
      </div>

      <div class="px-1">
        <div class="flex items-center justify-between gap-2 mb-1">
          <h3 class="font-black text-base text-slate-900 leading-tight">{{ producto.nombre }}</h3>
          <span class="text-sb-red font-black text-base">${{ producto.precio.toLocaleString('es-AR') }}</span>
        </div>
        <p class="text-xs text-slate-500 mb-4 line-clamp-2">{{ producto.descripcion }}</p>
      </div>
    </div>

    <!-- Botón con alto contraste visual -->
    <button 
      @click="$emit('agregar', producto)"
      class="w-full bg-sb-yellow hover:bg-amber-400 active:scale-95 text-slate-900 font-black py-2.5 rounded-2xl transition-all text-xs flex items-center justify-center gap-2 shadow-md"
    >
      <span class="text-base">+</span>
      <span>Agregar al Carrito</span>
    </button>
  </div>
</template>