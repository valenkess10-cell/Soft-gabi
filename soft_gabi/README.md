# MiCantina (Flutter + Firebase)

App móvil de la cantina. Los pedidos y las cuentas ahora viven en **Firebase**
(Authentication + Cloud Firestore), así que se sincronizan solos entre todos
los celulares: si alguien pide desde su teléfono, la vendedora lo ve en el
suyo al instante, sin que estén en el mismo dispositivo.

**IMPORTANTE:** la app no va a prender hasta que hagas los pasos de Firebase
de más abajo. Sin eso, `firebase_options.dart` tiene datos de ejemplo que no
apuntan a ningún proyecto real.

---

## 1. Crear el proyecto en Firebase

1. Andá a **https://console.firebase.google.com** y entrá con tu cuenta de Google.
2. **Agregar proyecto** → ponele un nombre (por ejemplo `micantina`) → seguí los pasos (podés desactivar Google Analytics, no hace falta) → **Crear proyecto**.

## 2. Activar Authentication

1. En el menú de la izquierda: **Compilación → Authentication** → **Comenzar**.
2. Pestaña **Sign-in method** → **Agregar proveedor**.
3. Activá **Correo electrónico/contraseña** (el primero de la lista) → Guardar.
4. Volvé a **Sign-in method** → **Agregar proveedor** otra vez → activá también **Anónimo**. Esto es lo que deja que alguien pida sin registrarse (como invitado).

## 3. Activar Cloud Firestore

1. **Compilación → Firestore Database** → **Crear base de datos**.
2. Elegí una ubicación (cualquiera de Sudamérica, por ejemplo `southamerica-east1`) → **Siguiente**.
3. Elegí **Iniciar en modo de producción** → **Habilitar**.
4. Andá a la pestaña **Reglas**, borrá todo el contenido y pegá el archivo `firestore.rules` que está en la raíz de este proyecto. Dale a **Publicar**.

## 4. Registrar la app Android en Firebase

1. En la página principal del proyecto (ícono de ⚙️ → **Configuración del proyecto**, o el botón Android en el resumen), tocá el ícono de **Android** para agregar una app.
2. **Nombre del paquete de Android:** tiene que ser exactamente `com.example.soft_gabi` (así está configurado el proyecto ahora). Si más adelante le cambiás el nombre al paquete, repetís este paso con el nuevo.
3. Los demás campos (apodo, SHA-1) son opcionales, los podés dejar vacíos.
4. Le das **Registrar app** y Firebase te ofrece descargar un archivo **`google-services.json`**. Descargalo.
5. Copiá ese archivo a esta carpeta exacta de tu proyecto:
   ```
   soft_gabi/android/app/google-services.json
   ```
6. Los pasos siguientes que te muestra Firebase ("agregar el SDK de Firebase a tu build.gradle") **ya están hechos** en este proyecto, podés saltarlos. Tocá **Siguiente** hasta terminar el asistente.

## 5. Generar `firebase_options.dart` con FlutterFire CLI

Esto conecta tu app de Flutter con el proyecto que acabás de crear.

1. Instalá el Firebase CLI (una sola vez). En PowerShell o la terminal de VS Code:
   ```
   npm install -g firebase-tools
   firebase login
   ```
   Te abre el navegador para que inicies sesión con la misma cuenta de Google.
2. Instalá la herramienta de FlutterFire (una sola vez):
   ```
   dart pub global activate flutterfire_cli
   ```
3. Pará en la carpeta del proyecto (`soft_gabi`) y corré:
   ```
   flutterfire configure
   ```
4. Te pregunta qué proyecto de Firebase usar: elegí el que creaste (`micantina`).
5. Te pregunta qué plataformas configurar: marcá al menos **android** (con la barra espaciadora) y confirmá con Enter.
6. Esto **reemplaza automáticamente** el archivo `lib/firebase_options.dart` por uno con los datos reales de tu proyecto. No lo edites a mano después.

Si `flutterfire` no se reconoce como comando después de instalarlo, cerrá y volvé a abrir la terminal (a veces hace falta para que tome el PATH nuevo).

## 6. Correr la app

```
flutter pub get
flutter run
```

Si ves un error de Firebase al abrir la app, lo más probable es que falte alguno de los pasos de arriba (sobre todo el 4 o el 5). Fijate el mensaje exacto y, si no lo entendés, pasámelo.

---

## Cuentas

- **Clientes:** se registran desde la app con cualquier email. También se puede pedir sin cuenta (como invitado).
- **Vendedora:** entra directo con `vendedora@micantina.com` / `Vendedora2026` (sin registrarse antes: la cuenta se crea sola la primera vez que alguien inicia sesión con esos datos). Ve el Panel de Ventas con todos los pedidos, en tiempo real.
- **Master (administración):** entra con `master@micantina.com` / `Cantina2026`. Ve el Panel de Ventas y además la lista de usuarios registrados.

Las contraseñas ahora las guarda Firebase Authentication de forma segura (ya no viajan ni se guardan en texto plano como en la versión anterior). Para cambiar las contraseñas fijas de vendedora/master, editá las constantes al principio de `lib/providers/cantina_provider.dart` **antes de que esas cuentas se usen por primera vez** (si ya se crearon con la contraseña vieja, hay que cambiarla a mano desde Firebase Console → Authentication → Users).

## Qué incluye

- Inicio, Menú con categorías (platos, pizzas, empanadas, pastas, tartas, Desayuno y Merienda, Bebidas, Sin TACC), y pestañas propias de **Desayuno** y **Bebidas** para acceso rápido desde la barra inferior
- Carrito con +/−, pago con 4 métodos: transferencia (QR), Mercado Pago, tarjeta (formulario) o efectivo. Ninguno cobra de verdad: son simulaciones, no hay pasarela de pago conectada
- Ticket con número de turno (se calcula con una transacción de Firestore, así nunca se repite aunque dos personas pidan al mismo tiempo), y posventa con calificación
- Panel de Ventas en tiempo real: estadísticas, listado de pedidos de TODOS los celulares y (solo master) usuarios registrados
- **Mis productos** (vendedora/master, desde el Panel de Ventas): agregar, editar o eliminar cualquier producto del catálogo (nombre, precio, categoría y una foto desde la cámara o la galería). Los cambios se ven al instante en todos los celulares.
- Usuarios y pedidos viven en Firebase (Authentication + Cloud Firestore). El catálogo de productos también vive ahí: la primera vez que la vendedora/master entra a un proyecto de Firebase nuevo, la app copia solo el catálogo de fábrica a la base de datos

## Estructura

`lib/models` · `lib/data` (catálogo) · `lib/providers` (estado + Firebase) · `lib/screens` · `lib/widgets`

`firestore.rules` → reglas de seguridad de la base de datos (quién puede leer/escribir qué). `firebase.json` → config opcional para subir esas reglas con el Firebase CLI en vez de pegarlas a mano.

## Pendiente para producción

- **Seguridad de roles:** sin Cloud Functions (código del lado del servidor), alguien con conocimientos técnicos podría intentar forzar su propio rol en la base. Para una cantina escolar interna el riesgo es bajo; para algo más sensible, migrar la asignación de roles a una Cloud Function con "custom claims".
- **Pasarela de pago real** (Mercado Pago Checkout API o similar) para cobrar de verdad.
- El paquete de Android sigue siendo `com.example.soft_gabi`: antes de publicarla en la Play Store hay que cambiarlo a uno propio (y repetir el paso 4 en Firebase con el nuevo nombre).
