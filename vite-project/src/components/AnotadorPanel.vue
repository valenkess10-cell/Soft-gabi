<script setup>
import { ref, computed } from 'vue'
import { NotebookPen, Plus, Trash2, Check } from 'lucide-vue-next'
import { useCantina } from '../composables/useCantina.js'

// Anotador de la vendedora: notas y pendientes que se guardan en Firestore
// (colección `notas`), así se ven igual en la web y en la app. Solo lo ven
// la vendedora y la cuenta master.
const { notas, agregarNota, editarNota, eliminarNota } = useCantina()

const texto = ref('')
const guardando = ref(false)
const error = ref('')

const pendientes = computed(() => notas.value.filter((n) => !n.hecha))
const hechas = computed(() => notas.value.filter((n) => n.hecha))

async function agregar() {
  const t = texto.value.trim()
  if (!t) return
  guardando.value = true
  error.value = ''
  try {
    await agregarNota(t)
    texto.value = ''
  } catch (err) {
    console.error('Error al guardar la nota:', err)
    error.value = 'No se pudo guardar la nota.'
  } finally {
    guardando.value = false
  }
}

async function alternar(nota) {
  try { await editarNota(nota.id, { hecha: !nota.hecha }) } catch (err) { console.error(err) }
}

async function borrar(nota) {
  try { await eliminarNota(nota.id) } catch (err) { console.error(err) }
}

async function borrarHechas() {
  if (!confirm(`¿Borrar ${hechas.value.length} nota(s) ya hechas?`)) return
  for (const n of hechas.value) {
    try { await eliminarNota(n.id) } catch (err) { console.error(err) }
  }
}

const formatear = (f) => f.toLocaleString('es-AR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })
</script>

<template>
  <div class="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
    <div class="p-5 border-b border-slate-100 bg-amber-50/60 flex items-center justify-between gap-3">
      <h2 class="text-lg font-black text-slate-900 flex items-center gap-2"><NotebookPen :size="18" class="text-amber-600" /> Anotador</h2>
      <span class="text-xs font-bold text-slate-500">{{ pendientes.length }} pendiente(s)</span>
    </div>

    <form @submit.prevent="agregar" class="p-4 flex gap-2 border-b border-slate-100">
      <input
        v-model="texto"
        maxlength="300"
        placeholder="Ej: comprar pan, avisar que faltan Coca-Cola…"
        class="flex-1 min-w-0 px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red"
      />
      <button
        type="submit"
        :disabled="guardando || !texto.trim()"
        class="px-4 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-black disabled:opacity-40 cursor-pointer flex items-center gap-1"
      >
        <Plus :size="14" /> Anotar
      </button>
    </form>
    <p v-if="error" class="px-4 pt-2 text-xs font-bold text-sb-red">{{ error }}</p>

    <div v-if="notas.length === 0" class="py-8 text-center text-slate-400 text-sm font-bold">Sin notas por ahora.</div>

    <ul v-else class="divide-y divide-slate-100 max-h-80 overflow-y-auto">
      <li v-for="n in [...pendientes, ...hechas]" :key="n.id" class="px-4 py-3 flex items-start gap-3">
        <button
          @click="alternar(n)"
          class="mt-0.5 w-5 h-5 rounded-md border flex items-center justify-center shrink-0 cursor-pointer"
          :class="n.hecha ? 'bg-emerald-600 border-emerald-600 text-white' : 'border-slate-300 hover:border-slate-500'"
          :aria-label="n.hecha ? 'Marcar como pendiente' : 'Marcar como hecha'"
        >
          <Check v-if="n.hecha" :size="13" />
        </button>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium break-words" :class="n.hecha ? 'line-through text-slate-400' : 'text-slate-800'">{{ n.texto }}</p>
          <p class="text-[10px] font-bold text-slate-400 mt-0.5">{{ n.autor }} · {{ formatear(n.fecha) }}</p>
        </div>
        <button @click="borrar(n)" class="text-slate-300 hover:text-sb-red cursor-pointer shrink-0" aria-label="Borrar nota">
          <Trash2 :size="15" />
        </button>
      </li>
    </ul>

    <div v-if="hechas.length" class="p-3 border-t border-slate-100 text-right">
      <button @click="borrarHechas" class="text-[11px] font-bold text-slate-500 hover:text-sb-red cursor-pointer">Borrar las hechas</button>
    </div>
  </div>
</template>
