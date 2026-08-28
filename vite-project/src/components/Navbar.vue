<script setup>
defineProps({
  cantidadCarrito: Number,
  seccionActiva: String,
  usuario: Object
})

defineEmits(['cambiar-seccion', 'abrir-carrito', 'abrir-auth', 'logout'])
</script>

<template>
  <nav class="sticky top-0 z-30 bg-white/90 backdrop-blur-md border-b border-slate-200 px-6 py-3 flex items-center justify-between transition-all">
    
    <!-- Logo -->
    <div 
      @click="$emit('cambiar-seccion', 'inicio')" 
      class="flex items-center gap-2 cursor-pointer select-none"
    >
      <span class="bg-sb-red text-white p-2 rounded-xl text-lg font-black shadow-sm">🍿</span>
      <span class="text-xl font-black tracking-tight text-slate-900">
        MI<span class="text-sb-red">CANTINA</span>
      </span>
    </div>

    <!-- Navegación tipo Pill Switcher -->
    <div class="bg-slate-100 p-1.5 rounded-full border border-slate-200/80 flex items-center gap-1 shadow-inner overflow-x-auto">
      <button 
        @click="$emit('cambiar-seccion', 'inicio')"
        class="px-4 py-1.5 rounded-full text-xs font-black transition-all duration-200 cursor-pointer whitespace-nowrap"
        :class="seccionActiva === 'inicio' 
          ? 'bg-sb-red text-white border-2 border-slate-900 shadow-md scale-105' 
          : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/60'"
      >
        Inicio
      </button>

      <button 
        @click="$emit('cambiar-seccion', 'menu')"
        class="px-4 py-1.5 rounded-full text-xs font-black transition-all duration-200 cursor-pointer whitespace-nowrap"
        :class="seccionActiva === 'menu' 
          ? 'bg-sb-red text-white border-2 border-slate-900 shadow-md scale-105' 
          : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/60'"
      >
        Menú
      </button>

      <button 
        @click="$emit('cambiar-seccion', 'nutricion')"
        class="px-4 py-1.5 rounded-full text-xs font-black transition-all duration-200 cursor-pointer whitespace-nowrap"
        :class="seccionActiva === 'nutricion' 
          ? 'bg-sb-red text-white border-2 border-slate-900 shadow-md scale-105' 
          : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/60'"
      >
        Nutrición
      </button>

      <!-- Nueva Sección Celíacos -->
      <button 
        @click="$emit('cambiar-seccion', 'celiacos')"
        class="px-4 py-1.5 rounded-full text-xs font-black transition-all duration-200 cursor-pointer whitespace-nowrap"
        :class="seccionActiva === 'celiacos' 
          ? 'bg-sb-red text-white border-2 border-slate-900 shadow-md scale-105' 
          : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/60'"
      >
        🌾 Sin TACC / Celíacos
      </button>
    </div>

    <!-- Usuario & Carrito -->
    <div class="flex items-center gap-3">
      <div v-if="usuario" class="flex items-center gap-2 bg-slate-100 px-3 py-1.5 rounded-full border border-slate-200">
        <span class="text-xs font-black text-slate-800">👤 {{ usuario.nombre }}</span>
        <button 
          @click="$emit('logout')" 
          class="text-[10px] bg-red-100 hover:bg-red-200 text-sb-red font-bold px-2 py-0.5 rounded-full transition-colors cursor-pointer"
        >
          Salir
        </button>
      </div>

      <button 
        v-else 
        @click="$emit('abrir-auth')" 
        class="text-xs font-black bg-slate-900 hover:bg-slate-800 text-white px-4 py-2 rounded-full transition-all cursor-pointer shadow-sm"
      >
        Ingresar
      </button>

      <button 
        @click="$emit('abrir-carrito')" 
        class="relative bg-slate-900 hover:bg-slate-800 text-white p-2.5 rounded-full transition-transform active:scale-95 cursor-pointer shadow-md"
      >
        🛒
        <span 
          v-if="cantidadCarrito > 0" 
          class="absolute -top-1 -right-1 bg-sb-red text-white text-[10px] font-black w-5 h-5 rounded-full flex items-center justify-center border-2 border-white"
        >
          {{ cantidadCarrito }}
        </span>
      </button>
    </div>
  </nav>
</template>