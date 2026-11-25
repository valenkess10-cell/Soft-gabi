<script setup>
import { ref, computed } from 'vue'
import { Package, X, Plus, Minus, Trash2 } from 'lucide-vue-next'
import { useCantina } from '../composables/useCantina.js'

// La vendedora arma combos eligiendo 2 o más productos que ya existen y les
// pone un precio especial. Se muestran a los clientes en Inicio y en el Menú.
defineProps({
  mostrar: Boolean,
})
defineEmits(['cerrar'])

const { combos, todosLosProductos, detalleDeCombo, guardarCombo, cambiarComboActivo, eliminarCombo } = useCantina()

const editandoId = ref(null)
const nombre = ref('')
const descripcion = ref('')
const precio = ref('')
const items = ref([]) // [{ productoId, nombre, cantidad }]
const productoAAgregar = ref('')
const guardando = ref(false)
const mensajeError = ref('')
const formularioEl = ref(null)

const productosOrdenados = computed(() =>
  [...todosLosProductos.value].sort((a, b) => a.nombre.localeCompare(b.nombre)),
)

const precioNormal = computed(() =>
  items.value.reduce((acc, it) => {
    const p = todosLosProductos.value.find((x) => x.id === it.productoId)
    return acc + (p?.precio ?? 0) * it.cantidad
  }, 0),
)

const combosConDetalle = computed(() => combos.value.map((c) => ({ ...c, ...detalleDeCombo(c) })))

function limpiar() {
  editandoId.value = null
  nombre.value = ''
  descripcion.value = ''
  precio.value = ''
  items.value = []
  productoAAgregar.value = ''
  mensajeError.value = ''
}

function editar(combo) {
  editandoId.value = combo.id
  nombre.value = combo.nombre
  descripcion.value = combo.descripcion
  precio.value = combo.precio
  items.value = combo.items.map((it) => ({ ...it }))
  mensajeError.value = ''
  formularioEl.value?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function sumarProducto() {
  const p = todosLosProductos.value.find((x) => x.id === productoAAgregar.value)
  if (!p) return
  const existente = items.value.find((it) => it.productoId === p.id)
  if (existente) existente.cantidad++
  else items.value.push({ productoId: p.id, nombre: p.nombre, cantidad: 1 })
  productoAAgregar.value = ''
}

function cambiarCantidad(it, delta) {
  it.cantidad = Math.max(1, it.cantidad + delta)
}

function quitar(it) {
  items.value = items.value.filter((x) => x !== it)
}

async function guardar() {
  mensajeError.value = ''
  const precioNum = Math.trunc(Number(precio.value))
  const totalUnidades = items.value.reduce((acc, it) => acc + it.cantidad, 0)
  if (!nombre.value.trim()) return (mensajeError.value = 'Ponele un nombre al combo')
  if (totalUnidades < 2) return (mensajeError.value = 'Un combo lleva al menos 2 productos')
  if (!precioNum || precioNum <= 0) return (mensajeError.value = 'Poné un precio válido')

  guardando.value = true
  try {
    const anterior = combos.value.find((c) => c.id === editandoId.value)
    await guardarCombo(editandoId.value, {
      nombre: nombre.value.trim(),
      descripcion: descripcion.value.trim(),
      precio: precioNum,
      items: items.value,
      activo: anterior ? anterior.activo : true,
      imagenBase64: anterior?.imagenBase64 ?? null,
    })
    limpiar()
  } catch (err) {
    console.error('Error al guardar combo:', err)
    mensajeError.value = 'No se pudo guardar. Probá de nuevo.'
  } finally {
    guardando.value = false
  }
}

async function borrar(combo) {
  if (!confirm(`¿Eliminar el combo "${combo.nombre}"?`)) return
  try {
    await eliminarCombo(combo.id)
    if (editandoId.value === combo.id) limpiar()
  } catch (err) {
    console.error('Error al borrar combo:', err)
    mensajeError.value = 'No se pudo borrar. Probá de nuevo.'
  }
}

async function alternarActivo(combo) {
  try {
    await cambiarComboActivo(combo.id, !combo.activo)
  } catch (err) {
    console.error('Error al cambiar combo:', err)
  }
}
</script>

<template>
  <div v-if="mostrar" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs">
    <div class="bg-white rounded-3xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col border border-slate-200 shadow-2xl">

      <div class="flex items-center justify-between p-5 border-b border-slate-100 bg-slate-50 shrink-0">
        <h3 class="text-lg font-black text-slate-900 flex items-center gap-2"><Package :size="18" /> Mis combos</h3>
        <button
          @click="$emit('cerrar')"
          class="w-7 h-7 rounded-full bg-slate-200 hover:bg-slate-300 text-slate-700 flex items-center justify-center transition-colors cursor-pointer"
          aria-label="Cerrar"
        >
          <X :size="14" />
        </button>
      </div>

      <div class="flex-1 overflow-y-auto overflow-x-hidden p-5 grid md:grid-cols-[340px_minmax(0,1fr)] gap-6">

        <!-- Formulario -->
        <div ref="formularioEl" class="space-y-3 bg-slate-50 p-4 rounded-2xl border border-slate-200 h-fit md:sticky md:top-0 scroll-mt-4">
          <h4 class="text-sm font-black text-slate-900">{{ editandoId ? 'Editar combo' : 'Armar combo nuevo' }}</h4>

          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Nombre</label>
            <input v-model="nombre" type="text" placeholder="Ej: Combo Pizza + Gaseosa" class="w-full px-3 py-2 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red" />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Descripción</label>
            <input v-model="descripcion" type="text" placeholder="Opcional" class="w-full px-3 py-2 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red" />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Productos del combo</label>
            <div class="flex gap-1.5">
              <select v-model="productoAAgregar" class="flex-1 min-w-0 px-2.5 py-2 rounded-xl border border-slate-300 text-xs focus:outline-none focus:ring-2 focus:ring-sb-red">
                <option value="" disabled>Elegí un producto…</option>
                <option v-for="p in productosOrdenados" :key="p.id" :value="p.id">
                  {{ p.nombre }} (${{ p.precio.toLocaleString('es-AR') }})
                </option>
              </select>
              <button
                @click="sumarProducto"
                :disabled="!productoAAgregar"
                type="button"
                class="px-3 rounded-xl bg-slate-900 text-white text-xs font-black disabled:opacity-40 cursor-pointer flex items-center gap-1"
              >
                <Plus :size="12" /> Sumar
              </button>
            </div>

            <div v-if="items.length" class="mt-2 space-y-1.5">
              <div v-for="it in items" :key="it.productoId" class="flex items-center gap-2 bg-white border border-slate-200 rounded-xl px-2.5 py-1.5">
                <span class="flex-1 min-w-0 truncate text-xs font-bold text-slate-800">{{ it.nombre }}</span>
                <button @click="cambiarCantidad(it, -1)" type="button" class="w-6 h-6 rounded-md bg-slate-100 hover:bg-slate-200 flex items-center justify-center cursor-pointer" aria-label="Restar"><Minus :size="11" /></button>
                <span class="w-4 text-center text-xs font-black">{{ it.cantidad }}</span>
                <button @click="cambiarCantidad(it, 1)" type="button" class="w-6 h-6 rounded-md bg-slate-100 hover:bg-slate-200 flex items-center justify-center cursor-pointer" aria-label="Sumar"><Plus :size="11" /></button>
                <button @click="quitar(it)" type="button" class="w-6 h-6 rounded-md bg-red-50 hover:bg-red-100 text-sb-red flex items-center justify-center cursor-pointer" aria-label="Quitar"><Trash2 :size="11" /></button>
              </div>
              <p class="text-[11px] text-slate-500 font-bold">Por separado salen ${{ precioNormal.toLocaleString('es-AR') }}</p>
            </div>
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Precio del combo</label>
            <input v-model="precio" type="number" min="0" placeholder="0" class="w-full px-3 py-2 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red" />
            <p v-if="Number(precio) > 0 && precioNormal > Number(precio)" class="text-[11px] text-emerald-700 font-bold mt-1">
              El cliente ahorra ${{ (precioNormal - Number(precio)).toLocaleString('es-AR') }}
            </p>
          </div>

          <p v-if="mensajeError" class="text-xs font-bold text-sb-red">{{ mensajeError }}</p>

          <div class="flex gap-2 pt-1">
            <button
              @click="guardar"
              :disabled="guardando"
              class="flex-1 bg-sb-red hover:bg-red-700 text-white font-black py-2.5 rounded-xl text-xs shadow-md transition-all active:scale-95 disabled:opacity-50 cursor-pointer"
            >
              {{ guardando ? 'Guardando...' : (editandoId ? 'Guardar cambios' : 'Crear combo') }}
            </button>
            <button v-if="editandoId" @click="limpiar" class="px-4 py-2.5 rounded-xl text-xs font-black bg-slate-200 hover:bg-slate-300 text-slate-700 transition-colors cursor-pointer">
              Cancelar
            </button>
          </div>
        </div>

        <!-- Listado -->
        <div class="min-w-0 space-y-2">
          <div v-if="combosConDetalle.length === 0" class="text-center py-10 text-slate-400 text-sm font-bold">
            Todavía no armaste ningún combo.
          </div>
          <div
            v-for="c in combosConDetalle"
            :key="c.id"
            class="flex flex-wrap items-center gap-3 p-3 bg-white border border-slate-200 rounded-2xl"
          >
            <div class="w-12 h-12 rounded-xl bg-amber-50 text-amber-500 flex items-center justify-center shrink-0">
              <Package :size="20" />
            </div>
            <div class="flex-1 min-w-[140px]">
              <p class="font-black text-xs text-slate-900">{{ c.nombre }} · <span class="text-sb-red">${{ c.precio.toLocaleString('es-AR') }}</span></p>
              <p class="text-[11px] text-slate-500 font-bold">{{ c.descripcionItems.join(' + ') }}</p>
              <span v-if="!c.activo" class="inline-block mt-1 text-[10px] font-black text-slate-600 bg-slate-100 border border-slate-200 px-2 py-0.5 rounded-full">Pausado · oculto del menú</span>
              <span v-else-if="!c.disponible" class="inline-block mt-1 text-[10px] font-black text-sb-red bg-red-50 border border-red-200 px-2 py-0.5 rounded-full">Oculto: algún producto está agotado o se borró</span>
            </div>
            <div class="flex items-center gap-2 shrink-0 ml-auto">
              <button @click="alternarActivo(c)" class="text-[11px] font-bold bg-slate-100 hover:bg-slate-200 text-slate-700 px-2.5 py-1.5 rounded-lg cursor-pointer whitespace-nowrap">
                {{ c.activo ? 'Pausar' : 'Activar' }}
              </button>
              <button @click="editar(c)" class="text-[11px] font-bold bg-slate-100 hover:bg-slate-200 text-slate-700 px-2.5 py-1.5 rounded-lg cursor-pointer whitespace-nowrap">
                Editar
              </button>
              <button @click="borrar(c)" class="text-[11px] font-bold bg-red-100 hover:bg-red-200 text-sb-red px-2.5 py-1.5 rounded-lg cursor-pointer whitespace-nowrap">
                Borrar
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
