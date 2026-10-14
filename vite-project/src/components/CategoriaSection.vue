<script setup>
import { UtensilsCrossed } from 'lucide-vue-next'
import ProductoCard from './ProductoCard.vue'
import { iconoDeCategoria } from '../data/iconos.js'

const props = defineProps({
  titulo: String,
  categoriaId: String,
  productos: Array
})

defineEmits(['agregar'])
</script>

<template>
  <section class="pt-10 pb-16">
    <div class="max-w-6xl mx-auto px-6">
      <div class="text-center mb-8">
        <component :is="iconoDeCategoria(categoriaId)" :size="36" class="text-slate-700 mx-auto mb-2" />
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
        <UtensilsCrossed :size="40" class="text-slate-300 mx-auto mb-2" />
        <p class="text-slate-400 font-bold text-sm">No hay productos en esta categoría todavía.</p>
      </div>
    </div>
  </section>
</template>
