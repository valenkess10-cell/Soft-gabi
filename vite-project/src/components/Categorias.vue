<script setup>
defineProps({
  categorias: Array,
  categoriaActiva: String,
  titulo: {
    type: String,
    default: '¿Qué querés comer hoy?'
  },
  subtitulo: {
    type: String,
    default: 'Elegí tu categoría favorita y hacé tu pedido.'
  },
  mostrarEncabezado: {
    type: Boolean,
    default: true
  }
})

defineEmits(['seleccionar-categoria'])
</script>

<template>
  <section class="py-10 bg-sb-bg">
    <div class="max-w-6xl mx-auto px-6">
      <div v-if="mostrarEncabezado" class="text-center mb-8">
        <h2 class="text-2xl sm:text-3xl font-black text-slate-900">{{ titulo }}</h2>
        <p class="text-sm text-slate-500 font-medium mt-1">{{ subtitulo }}</p>
      </div>

      <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-7 gap-3 sm:gap-4">
        <button
          v-for="cat in categorias"
          :key="cat.id"
          @click="$emit('seleccionar-categoria', cat.id)"
          class="flex flex-col items-center justify-center gap-2 py-5 px-2 rounded-2xl border-2 transition-all cursor-pointer active:scale-95"
          :class="[
            cat.bg, cat.border,
            categoriaActiva === cat.id ? 'ring-2 ring-offset-2 ' + cat.ring + ' scale-[1.03]' : 'hover:-translate-y-0.5'
          ]"
        >
          <span class="text-2xl">{{ cat.icon }}</span>
          <span class="text-xs sm:text-sm font-bold text-slate-800 text-center leading-tight">{{ cat.nombre }}</span>
        </button>
      </div>
    </div>
  </section>
</template>
