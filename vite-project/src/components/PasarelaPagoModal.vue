<script setup>
import { ref } from 'vue'

const props = defineProps({
  mostrar: Boolean,
  total: Number
})

const emit = defineEmits(['cerrar', 'pago-exitoso'])

const tipoPago = ref('transferencia') // 'transferencia' | 'efectivo'
const copiado = ref(false)
const procesando = ref(false)

const alias = 'lata.isae'

const copiarAlias = () => {
  navigator.clipboard.writeText(alias)
  copiado.value = true
  setTimeout(() => copiado.value = false, 2000)
}

const confirmarPago = () => {
  procesando.value = true
  setTimeout(() => {
    procesando.value = false
    emit('pago-exitoso', tipoPago.value)
  }, 1200)
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
          <span class="text-xl">💳</span>
          <h3 class="text-lg font-black text-slate-900">Abonar Pedido</h3>
        </div>
        <button 
          @click="$emit('cerrar')" 
          class="w-7 h-7 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-600 font-black text-xs flex items-center justify-center transition-colors cursor-pointer"
        >
          ✕
        </button>
      </div>

      <!-- Selector de modalidad (Transferencia o Efectivo) -->
      <div class="grid grid-cols-2 gap-2 my-4 bg-slate-100 p-1.5 rounded-2xl border border-slate-200">
        <button 
          @click="tipoPago = 'transferencia'"
          class="py-2 rounded-xl text-xs font-black transition-all cursor-pointer"
          :class="tipoPago === 'transferencia' ? 'bg-sb-red text-white shadow-sm' : 'text-slate-600 hover:text-slate-900'"
        >
          📱 Transferencia / QR
        </button>
        <button 
          @click="tipoPago = 'efectivo'"
          class="py-2 rounded-xl text-xs font-black transition-all cursor-pointer"
          :class="tipoPago === 'efectivo' ? 'bg-sb-red text-white shadow-sm' : 'text-slate-600 hover:text-slate-900'"
        >
          💵 Efectivo en Caja
        </button>
      </div>

      <!-- Total -->
      <div class="bg-slate-50 p-4 rounded-2xl border border-slate-200 text-center mb-4">
        <span class="text-xs font-bold text-slate-500 block">Total a pagar</span>
        <span class="text-3xl font-black text-sb-red">${{ total.toLocaleString('es-AR') }}</span>
      </div>

      <!-- DETALLE: TRANSFERENCIA / QR -->
      <div v-if="tipoPago === 'transferencia'" class="space-y-4">
        <!-- Código QR generado dinámicamente con el Alias y Monto -->
        <div class="flex flex-col items-center justify-center bg-slate-50 p-4 rounded-2xl border border-slate-200">
          <img 
            :src="`https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=Alias:${alias}_Monto:${total}`" 
            alt="Código QR de Pago" 
            class="w-40 h-40 rounded-xl border border-slate-200 shadow-sm"
          />
          <p class="text-[11px] font-bold text-slate-500 mt-2">Escaneá desde Mercado Pago, Naranja X o tu banco</p>
        </div>

        <!-- Copiar Alias -->
        <div class="bg-slate-100 p-3.5 rounded-2xl border border-slate-200 flex items-center justify-between">
          <div>
            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Alias Mercado Pago / CBU</span>
            <span class="text-base font-black text-slate-900">{{ alias }}</span>
          </div>
          <button 
            @click="copiarAlias"
            class="bg-slate-900 hover:bg-slate-800 active:scale-95 text-white text-xs font-black px-3.5 py-2 rounded-xl transition-all cursor-pointer"
          >
            {{ copiado ? '¡Copiado! ✓' : 'Copiar' }}
          </button>
        </div>
      </div>

      <!-- DETALLE: EFECTIVO -->
      <div v-else class="bg-amber-50 border border-amber-200 rounded-2xl p-5 text-center space-y-2">
        <span class="text-3xl">🏬</span>
        <h4 class="text-sm font-black text-amber-900">Pago en Mostrador</h4>
        <p class="text-xs text-amber-800 font-medium">
          Abonás los <strong class="font-black text-amber-950">${{ total.toLocaleString('es-AR') }}</strong> en efectivo directamente al retirar tu pedido en la cantina.
        </p>
      </div>

      <!-- Botón de Confirmación -->
      <button 
        @click="confirmarPago"
        :disabled="procesando"
        class="w-full mt-5 bg-sb-red hover:bg-red-700 active:scale-95 text-white font-black py-3.5 rounded-2xl text-xs shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
      >
        <span v-if="procesando" class="animate-spin text-sm">🌀</span>
        <span>{{ procesando ? 'Registrando Pedido...' : (tipoPago === 'transferencia' ? 'Ya Transferí / Enviar Pedido' : 'Confirmar Pedido en Efectivo') }}</span>
      </button>

    </div>
  </div>
</template>