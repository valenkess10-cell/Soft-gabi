<script setup>
import { computed } from 'vue'
import { Package, Plus, Clock, Flame } from 'lucide-vue-next'
import { useCantina } from '../composables/useCantina.js'

// Recibe un combo ya "enriquecido" por combosVisibles (con descripcionItems,
// precioNormal, ahorro, calorias y esAlmuerzo).
const props = defineProps({
  combo: Object,
})
defineEmits(['agregar'])

const { almuerzoCerrado } = useCantina()
const cerradoPorHorario = computed(() => props.combo.esAlmuerzo && almuerzoCerrado.value)
const urlImagen = computed(() => (props.combo.imagenBase64 ? `data:image/jpeg;base64,${props.combo.imagenBase64}` : null))
</script>

<template>
  <div
    class="bg-white rounded-2xl overflow-hidden border-2 border-amber-200 shadow-sm hover:shadow-lg transition-all duration-300 flex flex-col"
    :class="cerradoPorHorario ? 'opacity-70' : ''"
  >
    <div class="relative">
      <img v-if="urlImagen" :src="urlImagen" :alt="combo.nombre" class="w-full h-36 object-cover" />
      <div v-else class="w-full h-36 flex items-center justify-center bg-amber-50 text-amber-500">
        <Package :size="40" />
      </div>
      <span class="absolute top-2.5 left-2.5 bg-amber-400 text-slate-900 text-[10px] font-black px-2.5 py-1 rounded-full">COMBO</span>
      <span v-if="combo.ahorro > 0" class="absolute top-2.5 right-2.5 bg-emerald-600 text-white text-[10px] font-black px-2.5 py-1 rounded-full">
        Ahorrás ${{ combo.ahorro.toLocaleString('es-AR') }}
      </span>
    </div>

    <div class="p-4 flex flex-col flex-1">
      <h3 class="font-black text-sm text-slate-900 leading-snug">{{ combo.nombre }}</h3>
      <p v-if="combo.descripcion" class="text-xs text-slate-500 mt-1">{{ combo.descripcion }}</p>
      <ul class="mt-2 mb-3 space-y-0.5 flex-1">
        <li v-for="(linea, i) in combo.descripcionItems" :key="i" class="text-xs font-bold text-slate-600">{{ linea }}</li>
      </ul>

      <div class="flex items-end justify-between gap-2 mb-3">
        <div>
          <span v-if="combo.ahorro > 0" class="block text-[11px] font-bold text-slate-400 line-through">
            ${{ combo.precioNormal.toLocaleString('es-AR') }}
          </span>
          <span class="text-lg font-black text-sb-red">${{ combo.precio.toLocaleString('es-AR') }}</span>
        </div>
        <span
          v-if="typeof combo.calorias === 'number'"
          class="text-[11px] font-bold text-orange-700 bg-orange-50 border border-orange-200 px-2 py-0.5 rounded-full flex items-center gap-1"
        >
          <Flame :size="12" /> {{ combo.calorias }} kcal
        </span>
      </div>

      <button
        v-if="cerradoPorHorario"
        disabled
        class="w-full bg-slate-100 text-slate-400 font-black py-2.5 rounded-xl text-xs flex items-center justify-center gap-1.5 cursor-not-allowed"
      >
        <Clock :size="14" /> Cerrado hasta mañana (11:30)
      </button>
      <button
        v-else
        @click="$emit('agregar', combo)"
        class="w-full bg-sb-yellow hover:bg-sb-yellow-hover active:scale-95 text-slate-900 font-black py-2.5 rounded-xl transition-all text-xs flex items-center justify-center gap-1.5 cursor-pointer"
      >
        <Plus :size="14" /> Agregar combo
      </button>
    </div>
  </div>
</template>
