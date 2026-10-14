import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

// Mismo proyecto de Firebase que usa la app de Flutter (MiCantina), así que
// el catálogo, los pedidos y los usuarios se comparten en tiempo real entre
// la web y la app.
const firebaseConfig = {
  apiKey: 'AIzaSyAF6R6V4hzeVGhQGZMJ3ICvgimk1njFKIc',
  authDomain: 'micantina-ef6be.firebaseapp.com',
  projectId: 'micantina-ef6be',
  storageBucket: 'micantina-ef6be.firebasestorage.app',
  messagingSenderId: '59424907876',
  appId: '1:59424907876:web:91855f6c47d25e5d063571',
  measurementId: 'G-BNBLG6B3CN',
}

export const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)
export const db = getFirestore(app)
