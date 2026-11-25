<script setup>
import { ref, computed, watch } from 'vue'
import { X, Flame, Check, Plus } from 'lucide-vue-next'
import { resolverImagenUrl } from '../data/catalogo.js'
import { precioUnitarioDeLinea } from '../data/pedidos.js'

// Se abre al tocar "Elegir y agregar" en un producto con opciones: el cliente
// tilda extras ("extra queso +$500", "sin cebolla") y puede escribir una
// aclaración libre que le llega a la vendedora.
const props = defineProps({
  producto: { type: Object, default: null },
})
const emit = defineEmits(['cerrar', 'confirmar'])

const elegidas = ref([])
const nota = ref('')

watch(() => props.producto, () => {
  elegidas.value = []
  nota.value = ''
})

const opcionesElegidas = computed(() =>
  (props.producto?.opciones ?? []).filter((o) => elegidas.value.includes(o.id)),
)
const precio = computed(() => precioUnitarioDeLinea(props.producto?.precio ?? 0, opcionesElegidas.value))

function alternar(id) {
  elegidas.value = elegidas.value.includes(id)
    ? elegidas.value.filter((x) => x !== id)
    : [...elegidas.value, id]
}

function confirmar() {
  emit('confirmar', props.producto, opcionesElegidas.value, nota.value)
}
</script>

<template>
  <div v-if="producto" class="fixed inset-0 z-50 flex items-end sm:items-center justify-center sm:p-4 bg-slate-900/60 backdrop-blur-xs">
    <div class="bg-white w-full sm:max-w-md rounded-t-3xl sm:rounded-3xl max-h-[92vh] flex flex-col border border-slate-200 shadow-2xl">
      <div class="relative shrink-0">
        <img v-if="resolverImagenUrl(producto)" :src="resolverImagenUrl(producto)" :alt="producto.nombre" class="w-full h-36 object-cover rounded-t-3xl" />
        <button
          @click="$emit('cerrar')"
          class="absolute top-3 right-3 w-8 h-8 rounded-full bg-white/90 hover:bg-white text-slate-700 flex items-center justify-center shadow cursor-pointer"
          aria-label="Cerrar"
        >
          <X :size="16" />
        </button>
      </div>

      <div class="p-5 overflow-y-auto space-y-4">
        <div>
          <h3 class="text-lg font-black text-slate-900 leading-tight">{{ producto.nombre }}</h3>
          <p class="text-xs text-slate-500 mt-1">{{ producto.descripcion }}</p>
          <p v-if="typeof producto.calorias === 'number'" class="text-[11px] font-bold text-orange-700 mt-2 flex items-center gap-1">
            <Flame :size="12" /> {{ producto.calorias }} kcal
          </p>
        </div>

        <div v-if="producto.opciones?.length">
          <h4 class="text-xs font-black text-slate-700 uppercase tracking-wide mb-2">Personalizalo</h4>
          <div class="space-y-2">
            <button
              v-for="o in producto.opciones"
              :key="o.id"
              type="button"
              @click="alternar(o.id)"
              class="w-full flex items-center justify-between gap-3 p-3 rounded-xl border text-left transition-colors cursor-pointer"
              :class="elegidas.includes(o.id) ? 'border-sb-red bg-red-50' : 'border-slate-200 hover:bg-slate-50'"
            >
              <span class="flex items-center gap-2.5">
                <span
                  class="w-5 h-5 rounded-md border flex items-center justify-center shrink-0"
                  :class="elegidas.includes(o.id) ? 'bg-sb-red border-sb-red text-white' : 'border-slate-300'"
                >
                  <Check v-if="elegidas.includes(o.id)" :size="13" />
                </span>
                <span class="text-sm font-bold text-slate-800">{{ o.nombre }}</span>
              </span>
              <span class="text-xs font-black" :class="o.precio > 0 ? 'text-slate-700' : 'text-slate-400'">
                {{ o.precio > 0 ? `+$${o.precio.toLocaleString('es-AR')}` : 'Gratis' }}
              </span>
            </button>
          </div>
        </div>

        <div>
          <label class="block text-xs font-black text-slate-700 uppercase tracking-wide mb-2">Aclaración para la cocina</label>
          <textarea
            v-model="nota"
            rows="2"
            maxlength="140"
            placeholder="Ej: sin mayonesa, bien cocida…"
            class="w-full px-3 py-2 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red resize-none"
          ></textarea>
        </div>
      </div>

      <div class="p-5 border-t border-slate-100 shrink-0">
        <button
          @click="confirmar"
          class="w-full bg-sb-red hover:bg-red-700 active:scale-95 text-white font-black py-3.5 rounded-2xl text-sm shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer"
        >
          <Plus :size="16" /> Agregar · ${{ precio.toLocaleString('es-AR') }}
        </button>
      </div>
    </div>
  </div>
</template>
