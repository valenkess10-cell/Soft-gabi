<script setup>
import { ref, computed } from 'vue'
import { FolderOpen, X, UtensilsCrossed } from 'lucide-vue-next'
import { useCantina } from '../composables/useCantina.js'
import { resolverImagenUrl } from '../data/catalogo.js'
import { iconoDeEmoji, iconoDeCategoria } from '../data/iconos.js'

defineProps({
  mostrar: Boolean
})
defineEmits(['cerrar'])

const { todosLosProductos, categorias, agregarProducto, editarProducto, eliminarProducto, categoriasDeKiosco } = useCantina()

const editandoId = ref(null) // null = formulario de "nuevo"
const nombre = ref('')
const descripcion = ref('')
const precio = ref('')
const stock = ref('') // vacío = sin límite (stock: null en Firestore)
const categoria = ref('platos')
const previewImagen = ref(null) // data URL para mostrar
const imagenBase64 = ref(null) // string sin el prefijo data:, lo que se guarda en Firestore
const guardando = ref(false)
const mensajeError = ref('')
const filtroCategoria = ref('todos')

const productosFiltrados = computed(() => {
  if (filtroCategoria.value === 'todos') return todosLosProductos.value
  return todosLosProductos.value.filter((p) => p.categoria === filtroCategoria.value)
})

function limpiarFormulario() {
  editandoId.value = null
  nombre.value = ''
  descripcion.value = ''
  precio.value = ''
  stock.value = ''
  categoria.value = 'platos'
  previewImagen.value = null
  imagenBase64.value = null
  mensajeError.value = ''
}

function editar(producto) {
  editandoId.value = producto.id
  nombre.value = producto.nombre
  descripcion.value = producto.descripcion
  precio.value = producto.precio
  stock.value = producto.stock === null || producto.stock === undefined ? '' : producto.stock
  categoria.value = producto.categoria
  previewImagen.value = resolverImagenUrl(producto)
  imagenBase64.value = producto.imagenBase64 || null
  mensajeError.value = ''
}

// Ajustes rápidos de stock directo desde el listado, sin abrir el formulario.
async function cambiarStock(producto, delta) {
  const actual = producto.stock ?? 0
  const nuevo = Math.max(0, actual + delta)
  try {
    await editarProducto(producto.id, { stock: nuevo })
  } catch (err) {
    console.error('Error al actualizar stock:', err)
  }
}

async function fijarStockDesdeInput(producto, evento) {
  const valor = evento.target.value
  const nuevo = valor === '' ? null : Math.max(0, Math.trunc(Number(valor)))
  try {
    await editarProducto(producto.id, { stock: nuevo })
  } catch (err) {
    console.error('Error al actualizar stock:', err)
  }
}

// Comprime la foto elegida con un <canvas> y la convierte a base64, para
// guardarla directo en el documento de Firestore (sin usar Storage).
function elegirImagen(evento) {
  const archivo = evento.target.files?.[0]
  if (!archivo) return

  const lector = new FileReader()
  lector.onload = (e) => {
    const img = new Image()
    img.onload = () => {
      const maxLado = 640
      let { width, height } = img
      if (width > height && width > maxLado) {
        height = Math.round((height * maxLado) / width)
        width = maxLado
      } else if (height > maxLado) {
        width = Math.round((width * maxLado) / height)
        height = maxLado
      }

      const canvas = document.createElement('canvas')
      canvas.width = width
      canvas.height = height
      const ctx = canvas.getContext('2d')
      ctx.drawImage(img, 0, 0, width, height)

      const dataUrl = canvas.toDataURL('image/jpeg', 0.7)
      previewImagen.value = dataUrl
      imagenBase64.value = dataUrl.split(',')[1]
    }
    img.src = e.target.result
  }
  lector.readAsDataURL(archivo)
}

function quitarImagen() {
  previewImagen.value = null
  imagenBase64.value = null
}

async function guardar() {
  mensajeError.value = ''
  const precioNum = Number(precio.value)
  if (!nombre.value.trim() || !precioNum || precioNum <= 0) {
    mensajeError.value = 'Poné un nombre y un precio válido'
    return
  }

  const catInfo = categorias.find((c) => c.id === categoria.value)
  const stockValor = stock.value === '' ? null : Math.max(0, Math.trunc(Number(stock.value)))
  guardando.value = true
  try {
    if (editandoId.value) {
      await editarProducto(editandoId.value, {
        nombre: nombre.value.trim(),
        descripcion: descripcion.value.trim(),
        precio: precioNum,
        categoria: categoria.value,
        categoriaLabel: catInfo?.nombre ?? categoria.value,
        imagenBase64: imagenBase64.value,
        tiempo: categoriasDeKiosco.has(categoria.value) ? 1 : 10,
        stock: stockValor,
      })
    } else {
      await agregarProducto({
        nombre: nombre.value.trim(),
        descripcion: descripcion.value.trim(),
        precio: precioNum,
        categoria: categoria.value,
        categoriaLabel: catInfo?.nombre ?? categoria.value,
        imagenBase64: imagenBase64.value,
        stock: stockValor,
      })
    }
    limpiarFormulario()
  } catch (err) {
    mensajeError.value = 'No se pudo guardar. Probá de nuevo.'
    console.error('Error al guardar producto:', err)
  } finally {
    guardando.value = false
  }
}

async function borrar(producto) {
  if (!confirm(`¿Eliminar "${producto.nombre}"? Esta acción no se puede deshacer.`)) return
  try {
    await eliminarProducto(producto.id)
    if (editandoId.value === producto.id) limpiarFormulario()
  } catch (err) {
    mensajeError.value = 'No se pudo borrar. Probá de nuevo.'
    console.error('Error al borrar producto:', err)
  }
}
</script>

<template>
  <div v-if="mostrar" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs">
    <div class="bg-white rounded-3xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col border border-slate-200 shadow-2xl">

      <div class="flex items-center justify-between p-5 border-b border-slate-100 bg-slate-50 shrink-0">
        <h3 class="text-lg font-black text-slate-900 flex items-center gap-2"><FolderOpen :size="18" /> Mis productos</h3>
        <button
          @click="$emit('cerrar')"
          class="w-7 h-7 rounded-full bg-slate-200 hover:bg-slate-300 text-slate-700 font-black text-xs flex items-center justify-center transition-colors cursor-pointer"
        >
          <X :size="14" />
        </button>
      </div>

      <div class="flex-1 overflow-y-auto overflow-x-hidden p-5 grid md:grid-cols-[320px_minmax(0,1fr)] gap-6">

        <!-- Formulario (alta / edición) -->
        <div class="space-y-3 bg-slate-50 p-4 rounded-2xl border border-slate-200 h-fit">
          <h4 class="text-sm font-black text-slate-900">
            {{ editandoId ? 'Editar producto' : 'Agregar producto nuevo' }}
          </h4>

          <div class="flex items-center gap-3">
            <div class="w-16 h-16 rounded-xl bg-white border border-slate-200 flex items-center justify-center overflow-hidden shrink-0">
              <img v-if="previewImagen" :src="previewImagen" class="w-full h-full object-cover" />
              <UtensilsCrossed v-else :size="24" class="text-slate-400" />
            </div>
            <div class="flex-1 space-y-1">
              <label class="inline-block text-xs font-bold bg-slate-900 text-white px-3 py-1.5 rounded-lg cursor-pointer hover:bg-slate-800">
                Elegir foto
                <input type="file" accept="image/*" class="hidden" @change="elegirImagen" />
              </label>
              <button v-if="previewImagen" @click="quitarImagen" class="block text-[11px] font-bold text-sb-red hover:underline cursor-pointer">
                Quitar foto
              </button>
            </div>
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Nombre</label>
            <input v-model="nombre" type="text" placeholder="Ej: Sandwich de Milanesa" class="w-full px-3 py-2 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red" />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Descripción</label>
            <input v-model="descripcion" type="text" placeholder="Opcional" class="w-full px-3 py-2 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red" />
          </div>

          <div class="grid grid-cols-2 gap-2">
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Precio</label>
              <input v-model="precio" type="number" min="0" placeholder="0" class="w-full px-3 py-2 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red" />
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Categoría</label>
              <select v-model="categoria" class="w-full px-3 py-2 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red">
                <option v-for="c in categorias" :key="c.id" :value="c.id">{{ c.nombre }}</option>
              </select>
            </div>
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-700 mb-1">Stock</label>
            <input v-model="stock" type="number" min="0" placeholder="Sin límite" class="w-full px-3 py-2 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red" />
            <p class="text-[11px] text-slate-400 font-medium mt-1">Dejalo vacío para no controlar el stock. En 0 el producto se oculta del menú solo.</p>
          </div>

          <p v-if="mensajeError" class="text-xs font-bold text-sb-red">{{ mensajeError }}</p>

          <div class="flex gap-2 pt-1">
            <button
              @click="guardar"
              :disabled="guardando"
              class="flex-1 bg-sb-red hover:bg-red-700 text-white font-black py-2.5 rounded-xl text-xs shadow-md transition-all active:scale-95 disabled:opacity-50 cursor-pointer"
            >
              {{ guardando ? 'Guardando...' : (editandoId ? 'Guardar cambios' : 'Agregar producto') }}
            </button>
            <button v-if="editandoId" @click="limpiarFormulario" class="px-4 py-2.5 rounded-xl text-xs font-black bg-slate-200 hover:bg-slate-300 text-slate-700 transition-colors cursor-pointer">
              Cancelar
            </button>
          </div>
        </div>

        <!-- Listado de productos existentes -->
        <div class="min-w-0">
          <div class="flex items-center gap-2 mb-3 overflow-x-auto pb-1">
            <button
              @click="filtroCategoria = 'todos'"
              class="px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap cursor-pointer transition-colors"
              :class="filtroCategoria === 'todos' ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'"
            >
              Todos
            </button>
            <button
              v-for="c in categorias"
              :key="c.id"
              @click="filtroCategoria = c.id"
              class="px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap cursor-pointer transition-colors flex items-center gap-1"
              :class="filtroCategoria === c.id ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'"
            >
              <component :is="iconoDeCategoria(c.id)" :size="12" /> {{ c.nombre }}
            </button>
          </div>

          <div class="space-y-2">
            <div
              v-for="p in productosFiltrados"
              :key="p.id"
              class="flex flex-wrap items-center gap-3 p-3 bg-white border border-slate-200 rounded-2xl"
            >
              <div class="w-12 h-12 rounded-xl bg-slate-100 flex items-center justify-center overflow-hidden shrink-0">
                <img v-if="resolverImagenUrl(p)" :src="resolverImagenUrl(p)" class="w-full h-full object-cover" />
                <component :is="iconoDeEmoji(p.emoji)" v-else :size="20" class="text-slate-400" />
              </div>
              <div class="flex-1 min-w-[120px]">
                <p class="font-black text-xs text-slate-900 truncate">{{ p.nombre }}</p>
                <p class="text-[11px] text-slate-500 font-bold">{{ p.categoriaLabel }} · ${{ p.precio.toLocaleString('es-AR') }}</p>
                <span
                  v-if="p.stock === 0"
                  class="inline-block mt-1 text-[10px] font-black text-sb-red bg-red-50 border border-red-200 px-2 py-0.5 rounded-full"
                >
                  Agotado · oculto del menú
                </span>
                <span
                  v-else-if="typeof p.stock === 'number'"
                  class="inline-block mt-1 text-[10px] font-black text-amber-700 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-full"
                >
                  Stock: {{ p.stock }}
                </span>
              </div>

              <div class="flex items-center gap-1 shrink-0">
                <button
                  @click="cambiarStock(p, -1)"
                  class="w-6 h-6 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-600 flex items-center justify-center text-sm font-black cursor-pointer"
                  title="Restar stock"
                >
                  −
                </button>
                <input
                  type="number"
                  min="0"
                  :value="p.stock"
                  @change="fijarStockDesdeInput(p, $event)"
                  placeholder="∞"
                  title="Stock (vacío = sin límite)"
                  class="w-14 text-center text-xs font-bold border border-slate-200 rounded-lg py-1 focus:outline-none focus:ring-2 focus:ring-sb-red"
                />
                <button
                  @click="cambiarStock(p, 1)"
                  class="w-6 h-6 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-600 flex items-center justify-center text-sm font-black cursor-pointer"
                  title="Sumar stock"
                >
                  +
                </button>
              </div>

              <div class="flex items-center gap-2 shrink-0 ml-auto">
                <button @click="editar(p)" class="text-[11px] font-bold bg-slate-100 hover:bg-slate-200 text-slate-700 px-2.5 py-1.5 rounded-lg cursor-pointer transition-colors whitespace-nowrap">
                  Editar
                </button>
                <button @click="borrar(p)" class="text-[11px] font-bold bg-red-100 hover:bg-red-200 text-sb-red px-2.5 py-1.5 rounded-lg cursor-pointer transition-colors whitespace-nowrap">
                  Borrar
                </button>
              </div>
            </div>

            <div v-if="productosFiltrados.length === 0" class="text-center py-10 text-slate-400 text-sm font-bold">
              No hay productos en esta categoría.
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
