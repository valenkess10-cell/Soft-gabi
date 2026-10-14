// Mismas categorías y catálogo "de fábrica" que usa la app de Flutter
// (lib/data/catalogo.dart). Esto se usa para sembrar Firestore la primera
// vez que no hay nada cargado, y como respaldo si todavía no llegó nada
// desde la base de datos.

export const categorias = [
  { id: 'platos', nombre: 'Platos', icono: '🍽️', bg: 'bg-amber-50', border: 'border-amber-200', ring: 'ring-amber-400' },
  { id: 'pizzas', nombre: 'Pizzas', icono: '🍕', bg: 'bg-red-50', border: 'border-red-200', ring: 'ring-red-400' },
  { id: 'empanadas', nombre: 'Empanadas', icono: '🥟', bg: 'bg-orange-50', border: 'border-orange-200', ring: 'ring-orange-400' },
  { id: 'pastas', nombre: 'Pastas', icono: '🍝', bg: 'bg-blue-50', border: 'border-blue-200', ring: 'ring-blue-400' },
  { id: 'tartas', nombre: 'Tartas', icono: '🥧', bg: 'bg-pink-50', border: 'border-pink-200', ring: 'ring-pink-400' },
  { id: 'desayuno', nombre: 'Desayuno y Merienda', icono: '🥐', bg: 'bg-amber-50', border: 'border-amber-300', ring: 'ring-amber-500' },
  { id: 'bebidas', nombre: 'Bebidas', icono: '🥤', bg: 'bg-sky-50', border: 'border-sky-200', ring: 'ring-sky-400' },
  { id: 'sin-tacc', nombre: 'Sin TACC', icono: '🌾', bg: 'bg-emerald-50', border: 'border-emerald-200', ring: 'ring-emerald-400' },
]

// Categorías "de kiosco": no se preparan, así que no muestran tiempo.
export const categoriasDeKiosco = new Set(['desayuno', 'bebidas'])

export const productosSemilla = [
  { id: '1', nombre: 'Pizza Muzzarella', descripcion: 'Pizza artesanal a la piedra con abundante muzzarella y aceitunas.', precio: 3500, imagen: 'assets/images/pizza.jpg', tag: 'Popular', tiempo: 15, categoria: 'pizzas', categoriaLabel: 'Pizzas', destacado: true, esSinTacc: false },
  { id: '2', nombre: 'Empanadas de Jamón y Queso', descripcion: 'Empanadas horneadas con queso derretido y jamón.', precio: 1200, imagen: 'assets/images/empanadas.jpg', tag: 'Clásico', tiempo: 5, categoria: 'empanadas', categoriaLabel: 'Empanadas', destacado: true, esSinTacc: false },
  { id: '3', nombre: 'Spaghetti a la Boloñesa', descripcion: 'Pasta casera acompañada de una exquisita salsa boloñesa.', precio: 2800, imagen: 'assets/images/fideos.jpg', tag: 'Plato del día', tiempo: 10, categoria: 'pastas', categoriaLabel: 'Pastas', destacado: true, esSinTacc: false },
  { id: '4', nombre: 'Milanesa con Ensalada', descripcion: 'Milanesa dorada y crujiente acompañada de ensalada fresca.', precio: 3200, imagen: 'assets/images/milanesa.jpg', tag: 'Recomendado', tiempo: 12, categoria: 'platos', categoriaLabel: 'Platos', destacado: false, esSinTacc: false },
  { id: '5', nombre: 'Pechuga de Pollo a la Plancha', descripcion: 'Suprema de pollo condimentada con hierbas finas.', precio: 3000, imagen: 'assets/images/pollo.jpg', tag: 'Saludable', tiempo: 10, categoria: 'platos', categoriaLabel: 'Platos', destacado: true, esSinTacc: true },
  { id: '6', nombre: 'Medallones Rebozados', descripcion: 'Medallones súper crujientes con guarnición.', precio: 2500, imagen: 'assets/images/medallon.jpg', tag: 'Rápido', tiempo: 8, categoria: 'platos', categoriaLabel: 'Platos', destacado: false, esSinTacc: false },
  { id: '7', nombre: 'Tarta de Jamón y Queso', descripcion: 'Porción de tarta casera dorada al horno.', precio: 2200, imagen: 'assets/images/tarta.jpg', tag: 'Casero', tiempo: 5, categoria: 'tartas', categoriaLabel: 'Tartas', destacado: false, esSinTacc: false },

  // --- Desayuno y Merienda (kiosco, sin foto propia) ---
  { id: '9', nombre: 'Hamlet', descripcion: 'Oblea bañada en chocolate.', precio: 1200, emoji: '🍫', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '10', nombre: 'Tita', descripcion: 'Galletita rellena bañada en chocolate.', precio: 1300, emoji: '🍪', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '11', nombre: 'Rhodesia', descripcion: 'Chocolate con leche clásico.', precio: 1400, emoji: '🍫', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '12', nombre: 'Rocklets', descripcion: 'Grageas de chocolate con cobertura de color.', precio: 1300, emoji: '🍬', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '13', nombre: 'Bonafide Maní', descripcion: 'Chocolate con maní.', precio: 1500, emoji: '🍫', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '14', nombre: 'Bocadito Bonafide', descripcion: 'Bombón relleno individual.', precio: 900, emoji: '🍬', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '15', nombre: 'Oreo', descripcion: 'Galletitas de chocolate rellenas de crema.', precio: 1600, emoji: '🍪', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '16', nombre: 'Palitos de Selva', descripcion: 'Palitos salados crocantes.', precio: 1400, emoji: '🥨', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '17', nombre: 'Mogul Rellenas', descripcion: 'Galletitas rellenas de chocolate o vainilla.', precio: 1500, emoji: '🍪', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '18', nombre: 'Twist', descripcion: 'Galletitas crocantes clásicas.', precio: 1300, emoji: '🍪', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '19', nombre: 'Mentos', descripcion: 'Caramelos masticables.', precio: 900, emoji: '🍬', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '20', nombre: 'Mentho Plus', descripcion: 'Caramelos de menta.', precio: 800, emoji: '🍬', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '21', nombre: 'Club Social', descripcion: 'Galletitas crackers clásicas.', precio: 1400, emoji: '🍘', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '22', nombre: 'Cereal Mix Yogur & Frutilla', descripcion: 'Barrita de cereal con yogur y frutilla.', precio: 1300, emoji: '🌾', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '23', nombre: 'Polvorita', descripcion: 'Alfajor de maicena espolvoreado con azúcar.', precio: 1200, emoji: '🍪', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '24', nombre: 'Turrón', descripcion: 'Turrón de maní clásico.', precio: 900, emoji: '🥜', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '25', nombre: 'Alfajor Rasta', descripcion: 'Alfajor de maicena relleno de dulce de leche.', precio: 1500, emoji: '🍪', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '26', nombre: 'Tic-Tac', descripcion: 'Caramelos pequeños de menta.', precio: 700, emoji: '🍬', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },
  { id: '27', nombre: 'Raspadita', descripcion: 'Helado de agua raspado, sabor a elección.', precio: 700, emoji: '🍧', tag: 'Kiosco', tiempo: 1, categoria: 'desayuno', categoriaLabel: 'Desayuno y Merienda' },

  // --- Bebidas ---
  { id: '28', nombre: 'Coca-Cola', descripcion: 'Gaseosa cola bien fría.', precio: 1800, emoji: '🥤', tag: 'Frío', tiempo: 1, categoria: 'bebidas', categoriaLabel: 'Bebidas' },
  { id: '29', nombre: 'Coca-Cola Zero', descripcion: 'Gaseosa cola sin azúcar.', precio: 1800, emoji: '🥤', tag: 'Frío', tiempo: 1, categoria: 'bebidas', categoriaLabel: 'Bebidas' },
  { id: '30', nombre: 'Sprite', descripcion: 'Gaseosa sabor lima-limón.', precio: 1700, emoji: '🥤', tag: 'Frío', tiempo: 1, categoria: 'bebidas', categoriaLabel: 'Bebidas' },
  { id: '31', nombre: 'Fanta', descripcion: 'Gaseosa sabor naranja.', precio: 1700, emoji: '🥤', tag: 'Frío', tiempo: 1, categoria: 'bebidas', categoriaLabel: 'Bebidas' },
  { id: '32', nombre: 'Agua', descripcion: 'Agua mineral bien fría.', precio: 1200, emoji: '💧', tag: 'Frío', tiempo: 1, categoria: 'bebidas', categoriaLabel: 'Bebidas' },
  { id: '33', nombre: 'Jugo', descripcion: 'Jugo o bebida saborizada, sabor a elección.', precio: 1500, emoji: '🧃', tag: 'Frío', tiempo: 1, categoria: 'bebidas', categoriaLabel: 'Bebidas' },
].map((p) => ({ destacado: false, esSinTacc: false, imagen: null, imagenBase64: null, emoji: '🍽️', ...p }))

// Convierte un path de asset de Flutter ('assets/images/pizza.jpg') al
// archivo equivalente servido desde /public en la web ('/pizza.jpg'). Los 7
// platos originales comparten las mismas fotos en ambas plataformas.
export function resolverImagenUrl(producto) {
  if (producto.imagenBase64) return `data:image/jpeg;base64,${producto.imagenBase64}`
  if (producto.imagen) {
    const archivo = producto.imagen.split('/').pop()
    return `/${archivo}`
  }
  return null
}
