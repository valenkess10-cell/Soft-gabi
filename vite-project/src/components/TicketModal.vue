<script setup>
import { Check } from 'lucide-vue-next'

defineProps({
  mostrar: Boolean,
  numeroPedido: Number,
  total: Number
})

defineEmits(['cerrar'])
</script>

<template>
  <div v-if="mostrar" class="fixed inset-0 z-50 flex items-center justify-center p-4">
    <!-- Fondo oscuro -->
    <div @click="$emit('cerrar')" class="absolute inset-0 bg-black/60 backdrop-blur-sm"></div>

    <!-- Ticket Content -->
    <div class="relative bg-white rounded-3xl p-6 sm:p-8 max-w-sm w-full shadow-2xl z-10 border border-slate-200 text-center">
      
      <!-- Icono de éxito -->
      <div class="w-14 h-14 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4">
        <Check :size="28" />
      </div>

      <h3 class="text-2xl font-black text-slate-900 leading-tight">¡Pedido Confirmado!</h3>
      <p class="text-xs text-slate-500 font-semibold mt-1 mb-6">
        Mostrá este ticket en la caja de retiro de la cantina
      </p>

      <!-- Número de Turno -->
      <div class="bg-slate-900 text-white p-5 rounded-2xl mb-6 shadow-inner">
        <span class="text-[10px] font-bold tracking-widest text-slate-400 block uppercase">Tu número de turno</span>
        <span class="text-4xl font-black tracking-tight text-white">#0{{ numeroPedido }}</span>
      </div>

      <!-- QR Simulado -->
      <div class="bg-slate-50 p-4 rounded-2xl border border-slate-200 mb-6 flex flex-col items-center">
        <img 
          :src="`https://api.qrserver.com/v1/create-qr-code/?size=140x140&data=MICANTINA-${numeroPedido}`" 
          alt="Código QR del pedido" 
          class="w-32 h-32"
        />
        <span class="text-[10px] font-mono text-slate-400 mt-2">ID: CT-2026-{{ numeroPedido }}</span>
      </div>

      <p class="text-sm font-bold text-slate-700 mb-6">
        Total a pagar en retiro: <span class="text-sb-red font-black">${{ total ? total.toLocaleString('es-AR') : '0' }}</span>
      </p>

      <!-- Botón visible -->
      <button 
        @click="$emit('cerrar')" 
        class="w-full bg-slate-900 hover:bg-sb-red active:scale-95 text-white font-black py-3.5 rounded-2xl text-xs shadow-lg transition-all border border-slate-800"
      >
        Entendido / Hacer otro pedido
      </button>
    </div>
  </div>
</template>