<script setup>
const tablaNutricional = [
  { alimento: 'Ensalada de Frutas', porcion: '250g', calorias: '145 kcal', carbohidratos: '34g', proteinas: '2g', grasas: '0.5g', destacado: 'Vitamina C y fibra' },
  { alimento: 'Manzana / Banana Fresca', porcion: '1 unidad (150g)', calorias: '95 kcal', carbohidratos: '22g', proteinas: '1g', grasas: '0.2g', destacado: 'Potasio y antioxidantes' },
  { alimento: 'Licuado de Fruta Natural', porcion: '500ml', calorias: '210 kcal', carbohidratos: '42g', proteinas: '5g', grasas: '1.8g', destacado: 'Hidratación natural' },
  { alimento: 'Yogurt con Frutas y Granola', porcion: '200g', calorias: '260 kcal', carbohidratos: '38g', proteinas: '9g', grasas: '4.5g', destacado: 'Probióticos y energía' },
  { alimento: 'Jugo de Naranja Exprimido', porcion: '500ml', calorias: '180 kcal', carbohidratos: '40g', proteinas: '3g', grasas: '0.2g', destacado: '100% fruta natural' }
]
</script>

<template>
  <div class="max-w-6xl mx-auto px-6 py-10 space-y-8">
    
    <!-- Encabezado -->
    <div class="bg-white p-8 rounded-3xl border border-slate-200 shadow-xs flex flex-col md:flex-row items-center justify-between gap-6">
      <div class="space-y-2">
        <span class="bg-green-100 text-green-800 text-xs font-black px-3 py-1 rounded-full border border-green-200">
          🥗 Saludable & Balanceado
        </span>
        <h1 class="text-3xl font-black text-slate-900">Información Nutricional</h1>
        <p class="text-xs text-slate-500 font-bold max-w-xl">
          Conocé la composición de nuestras frutas de estación, batidos y opciones frescas para mantener una alimentación sana en la jornada escolar.
        </p>
      </div>
      <div class="text-5xl">🍏</div>
    </div>

    <!-- Tabla Nutricional de Frutas y Menú Saludable -->
    <div class="bg-white rounded-3xl border border-slate-200 shadow-xs overflow-hidden">
      <div class="p-6 border-b border-slate-100 bg-slate-50 flex items-center justify-between">
        <h2 class="text-lg font-black text-slate-900">Tabla de Aportes Nutricionales (Frutas & Batidos)</h2>
        <span class="text-xs font-bold text-slate-500">Valores por porción</span>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs">
          <thead class="bg-slate-100 text-slate-700 font-black uppercase text-[10px] tracking-wider border-b border-slate-200">
            <tr>
              <th class="p-4">Alimento / Fruta</th>
              <th class="p-4">Porción</th>
              <th class="p-4">Calorías</th>
              <th class="p-4">Carbohidratos</th>
              <th class="p-4">Proteínas</th>
              <th class="p-4">Grasas</th>
              <th class="p-4">Nutrientes Clave</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100 font-semibold text-slate-800">
            <tr v-for="(item, idx) in tablaNutricional" :key="idx" class="hover:bg-slate-50/80 transition-colors">
              <td class="p-4 font-black text-slate-900">{{ item.alimento }}</td>
              <td class="p-4 text-slate-600">{{ item.porcion }}</td>
              <td class="p-4 text-sb-red font-black">{{ item.calorias }}</td>
              <td class="p-4">{{ item.carbohidratos }}</td>
              <td class="p-4">{{ item.proteinas }}</td>
              <td class="p-4">{{ item.grasas }}</td>
              <td class="p-4">
                <span class="bg-slate-100 text-slate-700 px-2.5 py-1 rounded-lg text-[10px] font-bold border border-slate-200">
                  {{ item.destacado }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Tips de Alimentación -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="bg-emerald-50 border border-emerald-200 p-5 rounded-2xl">
        <span class="text-2xl">🍓</span>
        <h3 class="font-black text-emerald-950 text-sm mt-2">Frutas Frescas de Estación</h3>
        <p class="text-xs text-emerald-800 font-medium mt-1">
          Lavadas y desinfectadas diariamente para consumir directo al instante.
        </p>
      </div>
      <div class="bg-blue-50 border border-blue-200 p-5 rounded-2xl">
        <span class="text-2xl">💧</span>
        <h3 class="font-black text-blue-950 text-sm mt-2">Hidratación Activa</h3>
        <p class="text-xs text-blue-800 font-medium mt-1">
          Nuestros exprimidos no contienen aditivos ni azúcares procesadas agregadas.
        </p>
      </div>
      <div class="bg-amber-50 border border-amber-200 p-5 rounded-2xl">
        <span class="text-2xl">🍌</span>
        <h3 class="font-black text-amber-950 text-sm mt-2">Energía de Absorción Lenta</h3>
        <p class="text-xs text-amber-800 font-medium mt-1">
          Combiná fruta con granola y yogurt para rendir al máximo en los exámenes.
        </p>
      </div>
    </div>

  </div>
</template>