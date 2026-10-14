<script setup>
import { ref } from 'vue'
import { X } from 'lucide-vue-next'
import { useCantina } from '../composables/useCantina.js'

defineProps({
  mostrar: Boolean
})

const emit = defineEmits(['cerrar', 'login-exitoso'])

const { registrar, iniciarSesion } = useCantina()

const esLogin = ref(true)
const nombre = ref('')
const email = ref('')
const password = ref('')
const mensajeError = ref('')
const enviando = ref(false)

const traducirError = (err) => {
  const codigo = err?.code || ''
  if (codigo.includes('wrong-password') || codigo.includes('invalid-credential')) return 'Email o contraseña incorrectos'
  if (codigo.includes('user-not-found')) return 'No existe una cuenta con ese email'
  if (codigo.includes('email-already-in-use')) return 'El email ya está registrado'
  if (codigo.includes('weak-password')) return 'La contraseña debe tener al menos 6 caracteres'
  if (codigo.includes('invalid-email')) return 'El email no es válido'
  return 'Ocurrió un error. Probá de nuevo.'
}

const handleSubmit = async () => {
  mensajeError.value = ''

  if (!email.value || !password.value || (!esLogin.value && !nombre.value)) {
    mensajeError.value = 'Por favor completá todos los campos'
    return
  }

  enviando.value = true
  try {
    if (esLogin.value) {
      await iniciarSesion(email.value, password.value)
    } else {
      await registrar(nombre.value, email.value, password.value)
    }
    emit('login-exitoso')
    nombre.value = ''
    email.value = ''
    password.value = ''
  } catch (err) {
    mensajeError.value = traducirError(err)
  } finally {
    enviando.value = false
  }
}
</script>

<template>
  <div v-if="mostrar" class="fixed inset-0 z-50 flex items-center justify-center p-4">
    <div @click="$emit('cerrar')" class="absolute inset-0 bg-black/60 backdrop-blur-sm"></div>

    <div class="relative bg-white rounded-3xl p-6 sm:p-8 max-w-sm w-full shadow-2xl z-10 border border-slate-200">
      <button @click="$emit('cerrar')" class="absolute top-4 right-4 text-slate-400 hover:text-slate-700 font-bold"><X :size="16" /></button>

      <div class="text-center mb-6">
        <h3 class="text-2xl font-black text-slate-900">{{ esLogin ? 'Iniciá Sesión' : 'Creá tu Cuenta' }}</h3>
        <p class="text-xs text-slate-500 mt-1">
          {{ esLogin ? 'Ingresá a tu cuenta de MiCantina' : 'Registrate para hacer pedidos más rápido' }}
        </p>
      </div>

      <form @submit.prevent="handleSubmit" class="space-y-4">
        <div v-if="!esLogin">
          <label class="block text-xs font-bold text-slate-700 mb-1">Nombre Completo</label>
          <input
            v-model="nombre"
            type="text"
            placeholder="Ej: Valentin Kessler"
            class="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red"
          />
        </div>

        <div>
          <label class="block text-xs font-bold text-slate-700 mb-1">Correo Electrónico</label>
          <input
            v-model="email"
            type="email"
            placeholder="tu@email.com"
            class="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red"
          />
        </div>

        <div>
          <label class="block text-xs font-bold text-slate-700 mb-1">Contraseña</label>
          <input
            v-model="password"
            type="password"
            placeholder="••••••••"
            class="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-sb-red"
          />
        </div>

        <p v-if="mensajeError" class="text-xs font-bold text-sb-red text-center">
          {{ mensajeError }}
        </p>

        <button
          type="submit"
          :disabled="enviando"
          class="w-full bg-sb-red hover:bg-red-700 text-white font-black py-3 rounded-xl text-sm shadow-md transition-all active:scale-95 disabled:opacity-50"
        >
          {{ enviando ? 'Un momento...' : (esLogin ? 'Entrar' : 'Registrarme') }}
        </button>
      </form>

      <div class="text-center mt-4 pt-4 border-t border-slate-100">
        <button
          @click="esLogin = !esLogin; mensajeError = ''"
          class="text-xs font-bold text-slate-600 hover:text-sb-red transition-colors"
        >
          {{ esLogin ? '¿No tenés cuenta? Registrate acá' : '¿Ya tenés cuenta? Iniciá sesión' }}
        </button>
      </div>
    </div>
  </div>
</template>
