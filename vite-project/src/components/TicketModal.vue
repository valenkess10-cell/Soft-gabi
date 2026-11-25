<script setup>
import { computed } from 'vue'
import { Check, Clock, Loader2, XCircle } from 'lucide-vue-next'

const props = defineProps({
  mostrar: Boolean,
  numeroPedido: Number,
  total: Number,
  horaRetiro: { type: String, default: null },
  metodoPago: { type: String, default: '' },
  // Solo para Mercado Pago: 'pendiente' | 'aprobado' | 'rechazado'
  estadoPago: { type: String, default: null },
  reintentando: Boolean,
  // Error al abrir Mercado Pago (el pedido ya quedó guardado como pendiente).
  errorPago: { type: String, default: '' },
})

defineEmits(['cerrar', 'reintentar-pago'])

const esMercadoPago = computed(() => props.metodoPago === 'mercadopago')
const pendiente = computed(() => esMercadoPago.value && props.estadoPago === 'pendiente')
const rechazado = computed(() =>
  esMercadoPago.value && props.estadoPago !== 'aprobado' && (props.estadoPago === 'rechazado' || !!props.errorPago),
)

const textoTotal = computed(() => {
  if (esMercadoPago.value) {
    if (props.estadoPago === 'aprobado') return 'Pagado con Mercado Pago'
    if (rechazado.value) return 'Pago rechazado o cancelado'
    return 'Esperando la confirmación de Mercado Pago…'
  }
  if (props.metodoPago === 'transferencia') return 'Total transferido'
  return 'Total a pagar en retiro'
})
</script>

<template>
  <div v-if="mostrar" class="fixed inset-0 z-50 flex items-center justify-center p-4">
    <!-- Fondo oscuro -->
    <div @click="$emit('cerrar')" class="absolute inset-0 bg-black/60 backdrop-blur-sm"></div>

    <!-- Ticket Content -->
    <div class="relative bg-white rounded-3xl p-6 sm:p-8 max-w-sm w-full max-h-[92vh] overflow-y-auto shadow-2xl z-10 border border-slate-200 text-center">

      <!-- Icono de estado -->
      <div
        class="w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-4"
        :class="rechazado ? 'bg-red-100 text-sb-red' : pendiente ? 'bg-sky-100 text-sky-600' : 'bg-emerald-100 text-emerald-600'"
      >
        <XCircle v-if="rechazado" :size="28" />
        <Loader2 v-else-if="pendiente" :size="28" class="animate-spin" />
        <Check v-else :size="28" />
      </div>

      <h3 class="text-2xl font-black text-slate-900 leading-tight">
        {{ rechazado ? 'Pago no completado' : pendiente ? 'Pedido recibido' : '¡Pedido Confirmado!' }}
      </h3>
      <p class="text-xs text-slate-500 font-semibold mt-1 mb-6">
        {{ rechazado ? (errorPago || 'Podés volver a intentar el pago con Mercado Pago') : 'Mostrá este ticket en la caja de retiro de la cantina' }}
      </p>

      <!-- Número de Turno -->
      <div class="bg-slate-900 text-white p-5 rounded-2xl mb-4 shadow-inner">
        <span class="text-[10px] font-bold tracking-widest text-slate-400 block uppercase">Tu número de turno</span>
        <span class="text-4xl font-black tracking-tight text-white">#{{ String(numeroPedido ?? 0).padStart(3, '0') }}</span>
      </div>

      <div class="bg-amber-50 border border-amber-200 text-amber-900 rounded-2xl p-3 mb-6 text-sm font-black flex items-center justify-center gap-2">
        <Clock :size="16" />
        {{ horaRetiro ? `Retirás hoy a las ${horaRetiro}` : 'Lo preparamos lo antes posible' }}
      </div>

      <!-- QR del pedido -->
      <div v-if="!rechazado" class="bg-slate-50 p-4 rounded-2xl border border-slate-200 mb-6 flex flex-col items-center">
        <img
          :src="`https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=MICANTINA-${numeroPedido}`"
          alt="Código QR del pedido"
          class="w-32 h-32"
        />
        <span class="text-[10px] font-mono text-slate-400 mt-2">ID: CT-2026-{{ numeroPedido }}</span>
      </div>

      <p class="text-sm font-bold text-slate-700 mb-6">
        {{ textoTotal }}: <span class="text-sb-red font-black">${{ total ? total.toLocaleString('es-AR') : '0' }}</span>
      </p>

      <button
        v-if="rechazado"
        @click="$emit('reintentar-pago')"
        :disabled="reintentando"
        class="w-full mb-3 bg-sky-600 hover:bg-sky-700 active:scale-95 text-white font-black py-3.5 rounded-2xl text-xs shadow-lg transition-all disabled:opacity-50 flex items-center justify-center gap-2"
      >
        <Loader2 v-if="reintentando" :size="14" class="animate-spin" />
        Reintentar con Mercado Pago
      </button>

      <button
        @click="$emit('cerrar')"
        class="w-full bg-slate-900 hover:bg-sb-red active:scale-95 text-white font-black py-3.5 rounded-2xl text-xs shadow-lg transition-all border border-slate-800"
      >
        Entendido / Hacer otro pedido
      </button>
    </div>
  </div>
</template>
