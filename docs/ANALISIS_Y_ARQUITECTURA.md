# Vinca Data · Análisis y Arquitectura (versión móvil)

Documento técnico de la app móvil **Vinca Data**, versión Flutter/Android de la
plataforma web de finanzas personales. Cubre: (1) análisis de la web original,
(2) arquitectura propuesta, (3) wireframes y (4) estructura de datos en Firestore.

---

## 1. Análisis de la plataforma web

### 1.1 Stack original
- **Backend:** Flask (Python) + SQLite, servido con gunicorn en Railway.
- **Frontend:** una sola plantilla `index.html` que actúa como SPA y consume una
  API REST interna (`/api/*`). Gráficos con Chart.js 4.4.1.
- **Autenticación:** usuario/contraseña con sesión de servidor. Roles `admin`,
  `user` y `shared`. El **admin** daba de alta a los usuarios manualmente.

### 1.2 Funcionalidades detectadas
| Sección | Qué hace |
|---|---|
| **Dashboard** | KPIs del mes (saldo, ingresos, gastos, ahorro, balance, meta), gasto vs. límite, donut por categoría, evolución 6 meses y movimientos recientes. |
| **Gastos** | Alta/baja/listado por mes. Campos: descripción, categoría, método, importe, persona, tipo, comentario. |
| **Ingresos** | Igual que gastos, con tipos de ingreso. |
| **Ahorro** | Aportes con concepto y persona; total acumulado vs. objetivo. |
| **Deudas** | Total, pagado, pendiente y vencimiento, con barra de progreso. |
| **Suscripciones** | Coste mensual/anual, categoría y renovación. Baja = borrado lógico. |
| **Resumen** | Tabla de 12 meses (ingresos/gastos/ahorro/balance) y ranking de categorías por año. |
| **Configuración** | Saldo inicial, límite de gasto, objetivo de ahorro, aporte mensual; cambio de contraseña. |
| **Usuarios (admin)** | Alta/baja de usuarios. **Se elimina en la app móvil** (ver §2.2). |

### 1.3 Modelo de datos (SQLite, todo por `user_id`)
- `gastos(id, fecha, descripcion, categoria, metodo, monto, persona, tipo, comentario)`
- `ingresos(id, fecha, descripcion, monto, persona, tipo, comentario)`
- `ahorro(id, fecha, monto, persona, concepto)`
- `deudas(id, descripcion, total, pagado, vencimiento, persona)`
- `suscripciones(id, nombre, precio_mes, persona, categoria, renovacion, activa)`
- `config(user_id, key, value)` → saldo_inicial, limite_gasto, objetivo_ahorro, aporte_mensual
- `users(id, username, display_name, password_hash, role, created_at)`

### 1.4 Sistema de diseño (extraído del CSS de la web)
- **Fondo** `#0F1729` · **sidebar** `#0D1526` · **card** `#1A2744` · **borde** `#1E3A5F`
- **Primario (teal)** `#00D4AA` · azul `#4B9EF5` · morado `#8B5CF6` · rosa `#F472B6`
- verde `#10B981` · rojo `#EF4444` · amarillo `#F59E0B`
- texto `#F1F5F9` · apagado `#64748B`
- Radios: cards 14px, inputs/botones 10px. KPI cards con barra de acento inferior de 3px.
- Moneda **EUR**, locale **es-ES**, 2 decimales. Fechas `YYYY-MM-DD`.

Todo esto se ha trasladado 1:1 al tema de la app (`AppColors` / `AppTheme`).

---

## 2. Arquitectura de la app móvil

### 2.1 Stack
- **Flutter** (Material 3) — Android (y compatible iOS/web con configuración).
- **Firebase Auth** (Google + email/contraseña + recuperación).
- **Cloud Firestore** (datos por usuario, en tiempo real).
- **Riverpod** para estado (sencillo, testeable, sin boilerplate de Bloc).
- **go_router** para navegación con guardas de sesión.
- **fl_chart** para los gráficos (sustituye a Chart.js).

### 2.2 Cambio clave: autenticación
La web exigía que el **admin** crease cada cuenta. En la app, **cada usuario se
registra solo**:
- **Google Sign-In:** un toque; si es la primera vez, se crea automáticamente su
  documento `users/{uid}` y su configuración por defecto.
- **Email/contraseña:** registro propio + recuperación por correo.
- Se eliminan los roles y la gestión de usuarios. Se conserva el campo **persona**
  (Yo/Pareja/Otro) para etiquetar movimientos, que cubre el caso de la “cuenta
  compartida” sin necesidad de cuentas especiales.

### 2.3 Capas (Clean Architecture pragmática)
```
Presentation  → features/<modulo>/screens + widgets   (UI)
State         → features/.../providers (Riverpod)      (estado/casos de uso)
Data          → data/repositories + data/models        (Firestore/Auth)
Core          → theme, constants, utils, router        (transversal)
```
Regla de dependencia: la UI depende de providers; los providers, de repositorios;
los repositorios, de Firebase. Nunca al revés.

### 2.4 Flujo de autenticación
```
App arranca → Firebase recupera sesión
  ├─ Hay sesión  → go_router redirige a "/" (HomeShell)
  └─ No hay       → "/login"
       ├─ Google  → signInWithCredential → crea users/{uid} si es nuevo
       ├─ Email   → signIn / register
       └─ Olvido  → sendPasswordResetEmail
```

---

## 3. Wireframes (estructura de pantallas)

```
┌─ LOGIN ──────────────┐   ┌─ DASHBOARD ───────────┐   ┌─ GASTOS ──────────────┐
│   🌿 Vinca Data      │   │ AppBar: 🏠 + ◀Mes▶ 🌓 │   │ Total: -€xxx          │
│  [ Continuar Google ]│   │ ┌─KPI──┐ ┌─KPI──┐      │   │ ┌───────────────────┐ │
│  ─── o con correo ───│   │ │Saldo │ │Ingr. │      │   │ │ desc · cat · fecha │ │
│  [correo          ]  │   │ └──────┘ └──────┘      │   │ │            -€   🗑 │ │
│  [contraseña      ]  │   │ Gasto vs límite ▓▓░░  │   │ └───────────────────┘ │
│  ¿olvidaste?         │   │ Donut categorías       │   │            (+) Nuevo   │
│  [    Entrar      ]  │   │ Barras 6 meses         │   │  BottomBar: 5 destinos │
│  ¿No tienes? Regístr.│   │ BottomBar              │   └───────────────────────┘
└──────────────────────┘   └────────────────────────┘

Navegación: BottomBar (Inicio · Gastos · Ingresos · Resumen · Más)
            Drawer lateral = sidebar de la web (todas las secciones + salir).
Formularios: bottom sheet con campos + date picker (gastos, ingresos, ahorro,
             deudas, suscripciones).
```

---

## 4. Estructura de datos en Firestore

```
users/{uid}                         ← perfil (email, displayName, photoUrl, createdAt)
  ├─ config/finance                 ← { saldo_inicial, limite_gasto,
  │                                      objetivo_ahorro, aporte_mensual }
  ├─ gastos/{autoId}                ← { fecha, descripcion, categoria, metodo,
  │                                      monto, persona, tipo, comentario, createdAt }
  ├─ ingresos/{autoId}              ← { fecha, descripcion, monto, persona,
  │                                      tipo, comentario, createdAt }
  ├─ ahorro/{autoId}                ← { fecha, monto, persona, concepto, createdAt }
  ├─ deudas/{autoId}                ← { descripcion, total, pagado,
  │                                      vencimiento, persona, createdAt }
  └─ suscripciones/{autoId}         ← { nombre, precioMes, persona, categoria,
                                         renovacion, activa, createdAt }
```

**Por qué esta forma:** anidar todo bajo `users/{uid}` da aislamiento natural por
usuario y permite una regla de seguridad muy simple (ver `firestore.rules`):
*“solo el dueño accede a su subárbol”*. Las fechas se guardan como texto
`YYYY-MM-DD` (igual que la web) y el filtrado por mes se hace en cliente, por lo
que **no hacen falta índices compuestos** en el alcance actual.
