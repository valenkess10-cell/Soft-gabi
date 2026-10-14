<script setup>
defineProps({
  cantidadCarrito: Number,
  seccionActiva: String,
  usuario: Object,
  esVendedoraOMaster: Boolean,
  etiquetaRol: String
})

defineEmits(['cambiar-seccion', 'abrir-carrito', 'abrir-auth', 'logout'])
</script>

<template>
  <nav class="sticky top-0 z-30 bg-white border-b border-slate-200 px-6 py-3.5 flex items-center justify-between gap-4">

    <!-- Logo -->
    <div
      @click="$emit('cambiar-seccion', 'inicio')"
      class="flex items-center cursor-pointer select-none shrink-0"
    >
      <img
        src="/logo-micantina.png"
        alt="Mi Cantina"
        class="h-11 sm:h-12 w-auto object-contain"
      />
    </div>

    <!-- Navegación -->
    <div class="flex items-center gap-1 sm:gap-2 overflow-x-auto">
      <button
        @click="$emit('cambiar-seccion', 'inicio')"
        class="px-4 py-2 rounded-full text-sm font-bold transition-all cursor-pointer whitespace-nowrap"
        :class="seccionActiva === 'inicio'
          ? 'bg-sb-red text-white shadow-sm'
          : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'"
      >
        Inicio
      </button>

      <button
        @click="$emit('cambiar-seccion', 'menu')"
        class="px-4 py-2 rounded-full text-sm font-bold transition-all cursor-pointer whitespace-nowrap"
        :class="seccionActiva === 'menu'
          ? 'bg-sb-red text-white shadow-sm'
          : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'"
      >
        Menú
      </button>

      <button
        @click="$emit('cambiar-seccion', 'desayuno')"
        class="px-4 py-2 rounded-full text-sm font-bold transition-all cursor-pointer whitespace-nowrap"
        :class="seccionActiva === 'desayuno'
          ? 'bg-sb-red text-white shadow-sm'
          : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'"
      >
        Desayuno
      </button>

      <button
        @click="$emit('cambiar-seccion', 'bebidas')"
        class="px-4 py-2 rounded-full text-sm font-bold transition-all cursor-pointer whitespace-nowrap"
        :class="seccionActiva === 'bebidas'
          ? 'bg-sb-red text-white shadow-sm'
          : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'"
      >
        Bebidas
      </button>

      <button
        v-if="esVendedoraOMaster"
        @click="$emit('cambiar-seccion', 'ventas')"
        class="px-4 py-2 rounded-full text-sm font-bold transition-all cursor-pointer whitespace-nowrap flex items-center gap-1.5"
        :class="seccionActiva === 'ventas'
          ? 'bg-slate-900 text-white shadow-sm'
          : 'bg-amber-50 text-amber-800 border border-amber-200 hover:bg-amber-100'"
      >
        📋 Panel de Ventas
      </button>
    </div>

    <!-- Usuario & Carrito -->
    <div class="flex items-center gap-3 sm:gap-5 shrink-0">
      <div v-if="usuario" class="hidden sm:flex items-center gap-2">
        <span class="text-sm font-bold text-slate-800">
          👤 {{ usuario.nombre?.split(' ')[0] }}
          <span v-if="esVendedoraOMaster" class="text-[10px] font-black text-amber-600 bg-amber-50 border border-amber-200 px-1.5 py-0.5 rounded-full ml-1">
            {{ etiquetaRol }}
          </span>
        </span>
        <button
          @click="$emit('logout')"
          class="text-xs bg-slate-100 hover:bg-slate-200 text-slate-600 font-bold px-2.5 py-1 rounded-full transition-colors cursor-pointer"
        >
          Salir
        </button>
      </div>

      <button
        v-else
        @click="$emit('abrir-auth')"
        class="text-sm font-semibold text-slate-700 hover:text-sb-red transition-colors cursor-pointer hidden sm:inline"
      >
        Ingresar / Registrarse
      </button>

      <button
        @click="$emit('abrir-carrito')"
        class="relative bg-sb-yellow hover:bg-sb-yellow-hover active:scale-95 text-slate-900 px-4 py-2.5 rounded-full font-black text-sm transition-all cursor-pointer shadow-sm flex items-center gap-2 whitespace-nowrap"
      >
        🛒 <span class="hidden sm:inline">Mi Pedido</span>
        <span
          v-if="cantidadCarrito > 0"
          class="absolute -top-1.5 -right-1.5 bg-sb-red text-white text-[10px] font-black w-5 h-5 rounded-full flex items-center justify-center border-2 border-white"
        >
          {{ cantidadCarrito }}
        </span>
      </button>
    </div>
  </nav>
</template>
