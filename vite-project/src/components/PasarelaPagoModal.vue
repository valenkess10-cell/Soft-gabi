<script setup>
import { ref, computed, watch } from 'vue'
import { CreditCard, X, Smartphone, Wallet, Banknote, Store, Loader2 } from 'lucide-vue-next'

const props = defineProps({
  mostrar: Boolean,
  total: Number
})

const emit = defineEmits(['cerrar', 'pago-exitoso'])

// 4 métodos de pago, igual que en la app (metodoPagoLabel de cantina_provider.dart).
const metodos = [
  { id: 'transferencia', icono: Smartphone, nombre: 'Transferencia', etiqueta: 'Transferencia bancaria' },
  { id: 'mercadopago', icono: Wallet, nombre: 'Mercado Pago', etiqueta: 'Mercado Pago' },
  { id: 'tarjeta', icono: CreditCard, nombre: 'Tarjeta', etiqueta: 'Tarjeta en caja' },
  { id: 'efectivo', icono: Banknote, nombre: 'Efectivo', etiqueta: 'Efectivo en caja' },
]

const tipoPago = ref('transferencia')
const copiado = ref(false)
const procesando = ref(false)
const pagaCon = ref('')
const errorEfectivo = ref('')

const alias = 'lata.isae'

watch(tipoPago, () => { errorEfectivo.value = '' })
watch(() => props.mostrar, (abierto) => {
  if (abierto) { pagaCon.value = ''; errorEfectivo.value = '' }
})

const copiarAlias = () => {
  navigator.clipboard.writeText(alias)
  copiado.value = true
  setTimeout(() => (copiado.value = false), 2000)
}

const vuelto = computed(() => {
  const valor = Number(pagaCon.value)
  if (!pagaCon.value || Number.isNaN(valor)) return null
  return valor - props.total
})

const confirmarPago = () => {
  errorEfectivo.value = ''

  if (tipoPago.value === 'efectivo') {
    const valor = Number(pagaCon.value)
    if (!pagaCon.value || Number.isNaN(valor) || valor < props.total) {
      errorEfectivo.value = `Poné con cuánto efectivo pagás (mínimo $${props.total.toLocaleString('es-AR')})`
      return
    }
  }

  procesando.value = true
  setTimeout(() => {
    procesando.value = false
    const metodo = metodos.find((m) => m.id === tipoPago.value)
    if (tipoPago.value === 'efectivo') {
      const valor = Number(pagaCon.value)
      emit('pago-exitoso', metodo.etiqueta, { pagaCon: valor, vuelto: valor - props.total })
      pagaCon.value = ''
    } else {
      emit('pago-exitoso', metodo.etiqueta, null)
    }
  }, 900)
}
</script>

<template>
  <div
    v-if="mostrar"
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs transition-opacity"
  >
    <div class="bg-white rounded-3xl max-w-md w-full p-6 border border-slate-200 shadow-2xl animate-in fade-in zoom-in-95 duration-200">

      <!-- Header -->
      <div class="flex justify-between items-center pb-4 border-b border-slate-100">
        <div class="flex items-center gap-2">
          <CreditCard :size="20" class="text-slate-700" />
          <h3 class="text-lg font-black text-slate-900">Abonar Pedido</h3>
        </div>
        <button
          @click="$emit('cerrar')"
          class="w-7 h-7 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 font-black text-xs flex items-center justify-center transition-colors cursor-pointer"
        >
          <X :size="14" />
        </button>
      </div>

      <!-- Selector de modalidad (4 métodos) -->
      <div class="grid grid-cols-2 gap-2 my-4 bg-slate-100 p-1.5 rounded-2xl border border-slate-200">
        <button
          v-for="m in metodos"
          :key="m.id"
          @click="tipoPago = m.id"
          class="py-2 rounded-xl text-xs font-black transition-all cursor-pointer flex items-center justify-center gap-1.5"
          :class="tipoPago === m.id ? 'bg-sb-red text-white shadow-sm' : 'text-slate-600 hover:text-slate-900'"
        >
          <component :is="m.icono" :size="14" /> {{ m.nombre }}
        </button>
      </div>

      <!-- Total -->
      <div class="bg-slate-50 p-4 rounded-2xl border border-slate-200 text-center mb-4">
        <span class="text-xs font-bold text-slate-500 block">Total a pagar</span>
        <span class="text-3xl font-black text-sb-red">${{ total.toLocaleString('es-AR') }}</span>
      </div>

      <!-- DETALLE: TRANSFERENCIA -->
      <div v-if="tipoPago === 'transferencia'" class="space-y-4">
        <div class="flex flex-col items-center justify-center bg-slate-50 p-4 rounded-2xl border border-slate-200">
          <img
            :src="`https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=Alias:${alias}_Monto:${total}`"
            alt="Código QR de Pago"
            class="w-40 h-40 rounded-xl border border-slate-200 shadow-sm"
          />
          <p class="text-[11px] font-bold text-slate-500 mt-2">Escaneá desde tu banco o app de pagos</p>
        </div>

        <div class="bg-slate-100 p-3.5 rounded-2xl border border-slate-200 flex items-center justify-between">
          <div>
            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Alias / CBU</span>
            <span class="text-base font-black text-slate-900">{{ alias }}</span>
          </div>
          <button
            @click="copiarAlias"
            class="bg-slate-900 hover:bg-slate-800 active:scale-95 text-white text-xs font-black px-3.5 py-2 rounded-xl transition-all cursor-pointer"
          >
            {{ copiado ? '¡Copiado!' : 'Copiar' }}
          </button>
        </div>
      </div>

      <!-- DETALLE: MERCADO PAGO -->
      <div v-else-if="tipoPago === 'mercadopago'" class="space-y-4">
        <div class="flex flex-col items-center justify-center bg-sky-50 p-4 rounded-2xl border border-sky-200">
          <img
            :src="`https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=MercadoPago:${alias}_Monto:${total}`"
            alt="Código QR de Mercado Pago"
            class="w-40 h-40 rounded-xl border border-sky-200 shadow-sm"
          />
          <p class="text-[11px] font-bold text-sky-700 mt-2">Escaneá desde la app de Mercado Pago</p>
        </div>
        <div class="bg-sky-100 p-3.5 rounded-2xl border border-sky-200 flex items-center justify-between">
          <div>
            <span class="text-[10px] font-bold text-sky-500 uppercase tracking-wider block">Alias Mercado Pago</span>
            <span class="text-base font-black text-sky-950">{{ alias }}</span>
          </div>
          <button
            @click="copiarAlias"
            class="bg-sky-600 hover:bg-sky-700 active:scale-95 text-white text-xs font-black px-3.5 py-2 rounded-xl transition-all cursor-pointer"
          >
            {{ copiado ? '¡Copiado!' : 'Copiar' }}
          </button>
        </div>
      </div>

      <!-- DETALLE: TARJETA -->
      <div v-else-if="tipoPago === 'tarjeta'" class="bg-indigo-50 border border-indigo-200 rounded-2xl p-5 text-center space-y-2">
        <CreditCard :size="32" class="text-indigo-600 mx-auto" />
        <h4 class="text-sm font-black text-indigo-900">Pago con Tarjeta</h4>
        <p class="text-xs text-indigo-800 font-medium">
          Pagás con débito o crédito en la caja al retirar tu pedido, por
          <strong class="font-black text-indigo-950">${{ total.toLocaleString('es-AR') }}</strong>.
        </p>
      </div>

      <!-- DETALLE: EFECTIVO -->
      <div v-else class="bg-amber-50 border border-amber-200 rounded-2xl p-5 text-center space-y-3">
        <Store :size="32" class="text-amber-600 mx-auto" />
        <h4 class="text-sm font-black text-amber-900">Pago en Mostrador</h4>
        <p class="text-xs text-amber-800 font-medium">
          Abonás los <strong class="font-black text-amber-950">${{ total.toLocaleString('es-AR') }}</strong> en efectivo al retirar tu pedido.
        </p>

        <div class="text-left pt-1">
          <label class="block text-xs font-bold text-amber-900 mb-1">¿Con cuánto efectivo pagás?</label>
          <input
            v-model="pagaCon"
            type="number"
            min="0"
            :placeholder="`Ej: ${total.toLocaleString('es-AR')}`"
            class="w-full px-3.5 py-2.5 rounded-xl border border-amber-300 bg-white text-sm font-bold focus:outline-none focus:ring-2 focus:ring-sb-red"
          />
          <p v-if="vuelto !== null && vuelto >= 0" class="text-xs font-bold text-amber-800 mt-1.5">
            Te llevás <strong class="font-black text-amber-950">${{ vuelto.toLocaleString('es-AR') }}</strong> de vuelto
          </p>
          <p v-if="errorEfectivo" class="text-xs font-bold text-sb-red mt-1.5">{{ errorEfectivo }}</p>
        </div>
      </div>

      <!-- Botón de Confirmación -->
      <button
        @click="confirmarPago"
        :disabled="procesando"
        class="w-full mt-5 bg-sb-red hover:bg-red-700 active:scale-95 text-white font-black py-3.5 rounded-2xl text-xs shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
      >
        <Loader2 v-if="procesando" :size="16" class="animate-spin" />
        <span>{{ procesando ? 'Registrando Pedido...' : 'Confirmar Pedido' }}</span>
      </button>

    </div>
  </div>
</template>
