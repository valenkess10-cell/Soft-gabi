<script setup>
import { ref } from 'vue'

defineProps({
  mostrar: Boolean
})

const emit = defineEmits(['cerrar', 'login-exitoso'])

const esLogin = ref(true)
const nombre = ref('')
const email = ref('')
const password = ref('')
const mensajeError = ref('')

const handleSubmit = () => {
  mensajeError.value = ''

  if (!email.value || !password.value || (!esLogin.value && !nombre.value)) {
    mensajeError.value = 'Por favor completá todos los campos'
    return
  }

  const usuariosGuardados = JSON.parse(localStorage.getItem('schoolbite_users_db') || '[]')

  if (esLogin.value) {
    // Proceso de Login
    const usuarioEncontrado = usuariosGuardados.find(u => u.email === email.value && u.password === password.value)
    if (!usuarioEncontrado) {
      mensajeError.value = 'Email o contraseña incorrectos'
      return
    }
    localStorage.setItem('schoolbite_user', JSON.stringify(usuarioEncontrado))
    emit('login-exitoso', usuarioEncontrado)
  } else {
    // Proceso de Registro
    const existe = usuariosGuardados.some(u => u.email === email.value)
    if (existe) {
      mensajeError.value = 'El email ya está registrado'
      return
    }

    const nuevoUsuario = { nombre: nombre.value, email: email.value, password: password.value }
    usuariosGuardados.push(nuevoUsuario)
    localStorage.setItem('schoolbite_users_db', JSON.stringify(usuariosGuardados))
    localStorage.setItem('schoolbite_user', JSON.stringify(nuevoUsuario))
    emit('login-exitoso', nuevoUsuario)
  }

  // Limpiar formulario
  nombre.value = ''
  email.value = ''
  password.value = ''
}
</script>

<template>
  <div v-if="mostrar" class="fixed inset-0 z-50 flex items-center justify-center p-4">
    <div @click="$emit('cerrar')" class="absolute inset-0 bg-black/60 backdrop-blur-sm"></div>

    <div class="relative bg-white rounded-3xl p-6 sm:p-8 max-w-sm w-full shadow-2xl z-10 border border-slate-200">
      <button @click="$emit('cerrar')" class="absolute top-4 right-4 text-slate-400 hover:text-slate-700 font-bold">✕</button>

      <div class="text-center mb-6">
        <h3 class="text-2xl font-black text-slate-900">{{ esLogin ? 'Iniciá Sesión' : 'Creá tu Cuenta' }}</h3>
        <p class="text-xs text-slate-500 mt-1">
          {{ esLogin ? 'Ingresá a tu cuenta de SchoolBite' : 'Registrate para hacer pedidos más rápido' }}
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
          class="w-full bg-sb-red hover:bg-red-700 text-white font-black py-3 rounded-xl text-sm shadow-md transition-all active:scale-95"
        >
          {{ esLogin ? 'Entrar' : 'Registrarme' }}
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