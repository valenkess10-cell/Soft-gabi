<script setup>
defineProps({
  stats: {
    type: Object,
    default: () => ({ pedidos: '200+', tiempo: '15 min', valoracion: '4.8' })
  }
})

defineEmits(['ver-menu', 'crear-cuenta'])
</script>

<template>
  <div class="relative w-full min-h-[560px] bg-slate-950 text-white overflow-hidden flex items-center">
    <!-- Imagen de fondo -->
    <img
      src="/pollo.jpg"
      alt="Cantina"
      class="absolute inset-0 w-full h-full object-cover opacity-25"
    />
    <div class="absolute inset-0 bg-gradient-to-r from-slate-950 via-slate-950/85 to-slate-950/40"></div>

    <div class="relative max-w-6xl mx-auto px-6 w-full z-10 py-16">
      <div class="max-w-xl">
        <span class="inline-flex items-center gap-1.5 bg-amber-400/10 text-amber-300 border border-amber-400/30 text-xs font-bold px-3.5 py-1.5 rounded-full mb-5">
          ✨ Menú del día disponible
        </span>

        <h1 class="text-4xl sm:text-5xl md:text-6xl font-black mb-5 tracking-tight leading-[1.05]">
          Comida rica,<br />
          <span class="text-sb-yellow">siempre fresca.</span>
        </h1>

        <p class="text-slate-300 text-base max-w-md mb-7 leading-relaxed">
          En MICANTINA preparamos cada plato con ingredientes frescos. Pedí desde acá y retirá sin filas.
        </p>

        <div class="flex flex-wrap gap-3 mb-10">
          <button
            @click="$emit('ver-menu')"
            class="bg-sb-red hover:bg-sb-red-dark active:scale-95 text-white px-6 py-3.5 rounded-xl font-black text-sm transition-all shadow-lg cursor-pointer flex items-center gap-2"
          >
            Ver Menú Completo →
          </button>
          <button
            @click="$emit('crear-cuenta')"
            class="bg-slate-800/80 hover:bg-slate-700 active:scale-95 text-white px-6 py-3.5 rounded-xl font-black text-sm transition-all cursor-pointer border border-slate-700"
          >
            Crear Cuenta Gratis
          </button>
        </div>

        <div class="flex items-center gap-8 pt-6 border-t border-slate-700/60">
          <div>
            <p class="text-2xl font-black">{{ stats.pedidos }}</p>
            <p class="text-xs text-slate-400 font-semibold">Pedidos hoy</p>
          </div>
          <div>
            <p class="text-2xl font-black">{{ stats.tiempo }}</p>
            <p class="text-xs text-slate-400 font-semibold">Tiempo promedio</p>
          </div>
          <div>
            <p class="text-2xl font-black flex items-center gap-1">{{ stats.valoracion }} <span class="text-amber-400">⭐</span></p>
            <p class="text-xs text-slate-400 font-semibold">Valoración</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Tarjetas flotantes -->
    <div class="hidden lg:flex flex-col gap-3 absolute right-8 top-1/2 -translate-y-1/2 z-10">
      <div class="bg-amber-50/95 text-slate-900 rounded-2xl px-5 py-3.5 shadow-xl flex items-center gap-3 w-64">
        <span class="text-xl">🥪</span>
        <span class="text-sm font-bold">Sandwiches frescos</span>
      </div>
      <div class="bg-emerald-50/95 text-slate-900 rounded-2xl px-5 py-3.5 shadow-xl flex items-center gap-3 w-64">
        <span class="text-xl">🍎</span>
        <span class="text-sm font-bold">Frutas naturales</span>
      </div>
      <div class="bg-orange-50/95 text-slate-900 rounded-2xl px-5 py-3.5 shadow-xl flex items-center gap-3 w-64">
        <span class="text-xl">🥟</span>
        <span class="text-sm font-bold">Empanadas del día</span>
      </div>
    </div>
  </div>
</template>
