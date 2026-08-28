<script setup>
import { ref } from 'vue'

const modoEntrega = ref('retira')
</script>

<template>
  <div class="relative w-full h-[420px] bg-slate-900 text-white flex items-center overflow-hidden">
    <!-- Imagen de fondo -->
    <img 
      src="https://images.unsplash.com/photo-1561758033-d89a9ad46330?q=80&w=1600&auto=format&fit=crop" 
      alt="Cantina Hero" 
      class="absolute inset-0 w-full h-full object-cover opacity-30"
    />

    <div class="absolute inset-0 bg-gradient-to-r from-black via-black/60 to-transparent"></div>

    <div class="relative max-w-6xl mx-auto px-6 w-full z-10">
      <span class="bg-mcd-red text-white text-xs font-bold px-3 py-1 rounded-full uppercase tracking-wider mb-3 inline-block">
        Sin Filas · Sin Esperas
      </span>
      <h1 class="text-4xl sm:text-5xl md:text-6xl font-black mb-4 tracking-tight leading-tight">
        ¿Cómo querés hoy <br /><span class="text-mcd-yellow">tu pedido?</span>
      </h1>
      <p class="text-gray-300 text-sm sm:text-base max-w-md mb-6">
        Hacé tu pedido desde la celda o el aula, pagá al retirar y evitá los cuellos de botella en el recreo.
      </p>

      <!-- Botones de modo -->
      <div class="flex flex-wrap gap-3">
        <button 
          @click="modoEntrega = 'retira'"
          :class="[
            'flex items-center gap-3 px-6 py-3 rounded-2xl font-bold text-sm transition-all shadow-lg',
            modoEntrega === 'retira' ? 'bg-white text-black scale-105 shadow-white/10' : 'bg-white/15 text-white backdrop-blur-md hover:bg-white/25'
          ]"
        >
          <span class="text-xl">🏃</span>
          Pedí y Retirá Express
        </button>

        <button 
          @click="modoEntrega = 'reserva'"
          :class="[
            'flex items-center gap-3 px-6 py-3 rounded-2xl font-bold text-sm transition-all shadow-lg',
            modoEntrega === 'reserva' ? 'bg-white text-black scale-105 shadow-white/10' : 'bg-white/15 text-white backdrop-blur-md hover:bg-white/25'
          ]"
        >
          <span class="text-lg">⏰</span>
          Reservar para el Recreo
        </button>
      </div>
    </div>
  </div>
</template>