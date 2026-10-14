<script setup>
import ProductoCard from './ProductoCard.vue'

defineProps({
  titulo: String,
  icono: String,
  productos: Array
})

defineEmits(['agregar'])
</script>

<template>
  <section class="pt-10 pb-16">
    <div class="max-w-6xl mx-auto px-6">
      <div class="text-center mb-8">
        <span class="text-4xl block mb-2">{{ icono }}</span>
        <h1 class="text-2xl sm:text-3xl font-black text-slate-900">{{ titulo }}</h1>
      </div>

      <div v-if="productos.length" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <ProductoCard
          v-for="p in productos"
          :key="p.id"
          :producto="p"
          @agregar="$emit('agregar', $event)"
        />
      </div>
      <div v-else class="text-center py-20">
        <span class="text-4xl block mb-2">🍽️</span>
        <p class="text-slate-400 font-bold text-sm">No hay productos en esta categoría todavía.</p>
      </div>
    </div>
  </section>
</template>
