<script setup>
import ProductoCard from './ProductoCard.vue'

defineProps({
  productos: Array
})

defineEmits(['agregar', 'ver-todos'])
</script>

<template>
  <section class="py-4 pb-14 bg-sb-bg">
    <div class="max-w-6xl mx-auto px-6">
      <div class="flex items-center justify-between mb-5">
        <h2 class="text-lg sm:text-xl font-black text-slate-900 flex items-center gap-2">
          <span class="text-amber-400">⭐</span> Destacados del día
        </h2>
        <button
          @click="$emit('ver-todos')"
          class="text-sm font-bold text-sb-red hover:text-sb-red-dark transition-colors cursor-pointer"
        >
          Ver todos →
        </button>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <ProductoCard
          v-for="prod in productos"
          :key="prod.id"
          :producto="prod"
          @agregar="$emit('agregar', $event)"
        />
      </div>
    </div>
  </section>
</template>
