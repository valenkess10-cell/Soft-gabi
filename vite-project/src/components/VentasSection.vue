<script setup>
import { computed } from 'vue'

const props = defineProps({
  pedidos: {
    type: Array,
    default: () => []
  }
})

const cantidadPedidos = computed(() => props.pedidos.length)

const totalRecaudado = computed(() =>
  props.pedidos.reduce((acc, p) => acc + p.total, 0)
)

const pedidosHoy = computed(() => {
  const hoy = new Date().toLocaleDateString('es-AR')
  return props.pedidos.filter(p => p.fecha.startsWith(hoy)).length
})
</script>

<template>
  <div class="max-w-6xl mx-auto px-6 py-10 space-y-8">

    <!-- Encabezado -->
    <div class="bg-white p-8 rounded-3xl border border-slate-200 shadow-xs flex flex-col md:flex-row items-center justify-between gap-6">
      <div class="space-y-2">
        <span class="bg-amber-100 text-amber-800 text-xs font-black px-3 py-1 rounded-full border border-amber-200">
          🔒 Acceso exclusivo · Vendedora
        </span>
        <h1 class="text-3xl font-black text-slate-900">Panel de Ventas</h1>
        <p class="text-xs text-slate-500 font-bold max-w-xl">
          Acá vas a ver todos los pedidos que te van haciendo en tiempo real, con el detalle de cada uno para prepararlos y entregarlos.
        </p>
      </div>
      <div class="text-5xl">📋</div>
    </div>

    <!-- Estadísticas rápidas -->
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-5">
      <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
        <span class="text-xs font-bold text-slate-500 block mb-1">Pedidos totales</span>
        <span class="text-2xl font-black text-slate-900">{{ cantidadPedidos }}</span>
      </div>
      <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
        <span class="text-xs font-bold text-slate-500 block mb-1">Pedidos de hoy</span>
        <span class="text-2xl font-black text-slate-900">{{ pedidosHoy }}</span>
      </div>
      <div class="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
        <span class="text-xs font-bold text-slate-500 block mb-1">Total recaudado</span>
        <span class="text-2xl font-black text-sb-red">${{ totalRecaudado.toLocaleString('es-AR') }}</span>
      </div>
    </div>

    <!-- Listado de pedidos -->
    <div class="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
      <div class="p-6 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
        <h2 class="text-lg font-black text-slate-900">Pedidos Recibidos</h2>
        <span class="text-xs font-bold text-slate-500">Los más recientes primero</span>
      </div>

      <div v-if="pedidos.length === 0" class="py-16 text-center">
        <span class="text-4xl block mb-2">🧺</span>
        <p class="text-slate-400 font-bold text-sm">Todavía no recibiste ningún pedido.</p>
      </div>

      <div v-else class="divide-y divide-slate-100">
        <div
          v-for="pedido in pedidos"
          :key="pedido.numero + pedido.fecha"
          class="p-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 hover:bg-slate-50/60 transition-colors"
        >
          <div class="flex items-start gap-4">
            <div class="bg-slate-900 text-white rounded-2xl w-14 h-14 flex flex-col items-center justify-center shrink-0">
              <span class="text-[9px] font-bold text-slate-400 uppercase leading-none">Turno</span>
              <span class="text-lg font-black leading-none">#{{ pedido.numero }}</span>
            </div>
            <div>
              <p class="font-black text-sm text-slate-900">{{ pedido.cliente }}</p>
              <p class="text-[11px] text-slate-500 font-bold">{{ pedido.fecha }}</p>
              <ul class="mt-2 space-y-0.5">
                <li
                  v-for="(item, idx) in pedido.items"
                  :key="idx"
                  class="text-xs text-slate-600 font-medium"
                >
                  {{ item.cantidad }}x {{ item.nombre }}
                </li>
              </ul>
            </div>
          </div>

          <div class="flex sm:flex-col items-center sm:items-end justify-between sm:justify-center gap-1 sm:gap-0 sm:text-right">
            <span class="bg-slate-100 text-slate-700 border border-slate-200 text-[10px] font-bold px-2.5 py-1 rounded-lg">
              {{ pedido.metodoPago }}
            </span>
            <span class="text-lg font-black text-sb-red">${{ pedido.total.toLocaleString('es-AR') }}</span>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>
