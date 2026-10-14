// Mapea los emojis que usa el catálogo (compartido con la app de Flutter,
// que sí los muestra como emoji) a íconos de la librería lucide para
// mostrar en la web en su lugar. Así Firestore sigue guardando el mismo
// campo "emoji" para ambas plataformas, pero la web lo pinta como ícono.
import {
  UtensilsCrossed,
  Pizza,
  Sandwich,
  Soup,
  CakeSlice,
  Croissant,
  CupSoda,
  WheatOff,
  Wheat,
  Star,
  Candy,
  Cookie,
  Nut,
  IceCreamBowl,
  GlassWater,
} from 'lucide-vue-next'

// Ícono por categoría (se usa en los chips de Categorias.vue)
const iconosPorCategoria = {
  'todos': Star,
  'platos': UtensilsCrossed,
  'pizzas': Pizza,
  'empanadas': Sandwich,
  'pastas': Soup,
  'tartas': CakeSlice,
  'desayuno': Croissant,
  'bebidas': CupSoda,
  'sin-tacc': WheatOff,
}

// Ícono por emoji de producto (kiosco, bebidas, y respaldo genérico)
const iconosPorEmoji = {
  '🍽️': UtensilsCrossed,
  '🍕': Pizza,
  '🥟': Sandwich,
  '🍝': Soup,
  '🥧': CakeSlice,
  '🥐': Croissant,
  '🥤': CupSoda,
  '🌾': Wheat,
  '🍫': Candy,
  '🍪': Cookie,
  '🍬': Candy,
  '🥨': Cookie,
  '🍘': Cookie,
  '🥜': Nut,
  '🍧': IceCreamBowl,
  '💧': GlassWater,
  '🧃': GlassWater,
}

export function iconoDeCategoria(categoriaId) {
  return iconosPorCategoria[categoriaId] || UtensilsCrossed
}

export function iconoDeEmoji(emoji) {
  return iconosPorEmoji[emoji] || UtensilsCrossed
}
