# 🌿 Vinca Data — App móvil (Flutter + Firebase)

Versión Android de **Vinca Data**, tu plataforma de finanzas personales.
Flutter · Material 3 · Firebase Auth (Google + email) · Cloud Firestore · Riverpod.

> **Estado:** base funcional completa y coherente (auth, tema claro/oscuro,
> dashboard, gastos, ingresos, ahorro, deudas, suscripciones, resumen,
> configuración). El proyecto está escrito con cuidado pero **no se ha compilado
> en este entorno**: necesita que ejecutes los pasos de abajo (Firebase + assets).
> Ajusta versiones de paquetes con `flutter pub get` / `flutter pub upgrade` si tu
> SDK lo pide.
>
> **Compatibilidad de versión:** el tema usa APIs de Flutter 3.24+ (`CardThemeData`,
> `WidgetState`, `Color.withValues`). Si usas Flutter 3.22, cambia `CardThemeData`
> por `CardTheme` en `lib/core/theme/app_theme.dart`.

---

## 0. Requisitos previos
- **Flutter** estable (3.22+) y **Dart** 3.4+ → `flutter doctor` sin errores.
- **Android Studio** (SDK Android, emulador o dispositivo).
- Una cuenta de **Firebase** (gratis) y **Google Play Console** (25 USD, pago único) para publicar.

---

## 1. Generar las carpetas de plataforma
El proyecto incluye `lib/`, `pubspec.yaml` y configuración. Genera las carpetas
nativas (`android/`, `ios/`, etc.) sobre este mismo directorio:

```bash
cd vinca_data_app
flutter create . --org com.vincadata --project-name vinca_data
flutter pub get
```

En `android/app/build.gradle` (o `build.gradle.kts`) asegúrate de:
- `applicationId = "com.vincadata.app"`
- `minSdkVersion 21` (necesario para Firebase Auth)
- `targetSdkVersion` y `compileSdkVersion` a la última estable.

---

## 2. Configurar Firebase

### 2.1 Crear el proyecto
1. Ve a <https://console.firebase.google.com> → **Agregar proyecto** → nómbralo `vinca-data`.
2. Activa **Authentication** → pestaña *Sign-in method*:
   - Habilita **Google**.
   - Habilita **Correo electrónico/contraseña**.
3. Crea **Cloud Firestore** en modo producción (región europa, p. ej. `eur3`).

### 2.2 Vincular la app con FlutterFire (recomendado)
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Selecciona el proyecto `vinca-data` y las plataformas. Esto:
- genera el **`lib/firebase_options.dart`** real (sustituye la plantilla incluida),
- crea **`android/app/google-services.json`** automáticamente.

### 2.3 SHA-1 / SHA-256 (imprescindible para Google Sign-In en Android)
Google Sign-In **no funciona** sin registrar las huellas de tu firma:

```bash
# Huella de depuración (para probar en debug):
cd android && ./gradlew signingReport
# Busca las líneas SHA1 y SHA-256 de la variante "debug".
```
Copia **SHA-1** y **SHA-256** en *Firebase → Configuración del proyecto → Tus apps
(Android) → Agregar huella digital*. Cuando publiques, **repite con la huella del
keystore de release** (y con la de *App Signing* de Google Play, §5.3).

### 2.4 Aplicar las reglas de seguridad
En *Firestore → Reglas*, pega el contenido de **`firestore.rules`** (incluido) y
publica. Garantizan que cada usuario solo acceda a `users/{su-uid}/**`.

---

## 3. Iconos y splash
Coloca tres imágenes en `assets/` y descomenta la sección `assets:` del `pubspec.yaml`:
- `assets/icon.png` (1024×1024) — icono base.
- `assets/icon_foreground.png` — capa frontal del icono adaptativo (transparente).
- `assets/splash.png` — logo para la pantalla de carga.

Genera ambos:
```bash
dart run flutter_launcher_icons     # icono adaptativo Android 8+
dart run flutter_native_splash:create
```

---

## 4. Ejecutar en desarrollo
```bash
flutter run            # en un emulador o móvil conectado
```
Prueba: registro con Google, registro con email, recuperación de contraseña,
alta de gastos/ingresos, KPIs del dashboard y cambio de tema.

---

## 5. Compilar para publicar

### 5.1 Crear el keystore de firma (una sola vez)
```bash
keytool -genkey -v -keystore ~/vinca-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Guarda el `.jks` y las contraseñas **en lugar seguro** (si los pierdes, no podrás
actualizar la app).

### 5.2 Configurar la firma
Crea `android/key.properties` (no lo subas a git):
```properties
storePassword=TU_PASSWORD
keyPassword=TU_PASSWORD
keyAlias=upload
storeFile=/ruta/absoluta/vinca-upload.jks
```
Y en `android/app/build.gradle`, dentro de `android { ... }`, añade el bloque
`signingConfigs` que lee `key.properties` y asígnalo a `buildTypes.release`
(la documentación oficial de Flutter “Build and release an Android app” trae el
snippet exacto).

### 5.3 Generar APK y AAB
```bash
# APK (para pruebas / instalación directa):
flutter build apk --release

# App Bundle (formato exigido por Google Play):
flutter build appbundle --release
```
Salidas:
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

---

## 6. Publicar en Google Play (paso a paso)
1. **Play Console** (<https://play.google.com/console>) → paga la cuota única → *Crear app*.
2. Rellena nombre (*Vinca Data*), idioma, tipo (App), gratuita.
3. **Ficha de Play Store:** descripción corta y larga, icono 512×512, *feature graphic*
   1024×500 y al menos 2 capturas de pantalla del teléfono.
4. **Contenido de la app** (obligatorio):
   - **Política de privacidad** (URL pública, ver §7).
   - **Seguridad de los datos:** declara que recoges correo y datos financieros que
     el usuario introduce, almacenados en Firebase, no compartidos con terceros.
   - Clasificación de contenido (cuestionario), público objetivo, anuncios (ninguno).
5. **App Signing:** acepta que Google gestione la clave (*Play App Signing*). Te dará
   un **SHA-1 de App Signing** → regístralo también en Firebase (§2.3) o Google
   Sign-In fallará en las builds publicadas.
6. **Versiones → Producción** (o prueba interna primero, recomendado) → sube el
   **`.aab`** → completa el *release name* y las notas → **Revisar y publicar**.
7. La primera revisión de Google puede tardar de unas horas a varios días.

> Consejo: usa primero un **canal de prueba interna** con tu propio correo para
> validar Google Sign-In en una build de release antes de ir a producción.

---

## 7. Política de privacidad y permisos

### Permisos
La app pide lo **mínimo**: acceso a Internet (implícito) para Firebase. No usa
cámara, ubicación, contactos ni almacenamiento. Si añades login de Google, el
plugin gestiona sus propios permisos.

### Política de privacidad (resumen para publicar)
Debes alojar una página pública. Puntos a cubrir:
- Qué recoges: correo, nombre y foto (si usan Google), y los datos financieros que
  el usuario introduce.
- Dónde se guardan: Firebase Authentication y Cloud Firestore (Google Cloud, UE).
- Para qué: prestar el servicio. **No se venden ni comparten** con terceros.
- Derechos: el usuario puede solicitar el borrado de su cuenta y datos.
- Contacto: tu correo.

(Servicios como *Termly*, *iubenda* o una página estática propia sirven para alojarla.)

---

## 8. Mejoras futuras
- **Eliminar cuenta en la app** (requisito creciente de Google Play): borrar
  `users/{uid}/**` y la cuenta de Auth desde Configuración.
- **Soporte offline** real (Firestore lo permite; activar `persistenceEnabled`).
- **Edición** de movimientos (hoy: alta y baja).
- **Filtros** por persona/categoría y búsqueda.
- **Exportar** a CSV/PDF y backups.
- **Notificaciones** de vencimiento de deudas y renovación de suscripciones (FCM).
- **Migrar Google Sign-In a la API v7** del paquete (hoy se usa la 6.x, estable).
- **Cuenta compartida real** (pareja) vía Firestore con datos compartidos por
  invitación, si quieres recuperar ese concepto de la web.
- **Tests** de widgets y de los repositorios con `fake_cloud_firestore`.
- **CI/CD** (GitHub Actions) para builds y despliegue a Play.

---

## 9. Estructura del proyecto
```
lib/
├── main.dart                  # arranque: Firebase + ProviderScope + router
├── firebase_options.dart      # PLANTILLA (reemplaza con flutterfire configure)
├── core/
│   ├── theme/                 # AppColors (paleta web) + AppTheme (M3 claro/oscuro)
│   ├── constants/             # categorías, métodos, tipos, personas, config
│   ├── utils/                 # Fmt: moneda EUR es-ES, fechas
│   └── router/                # go_router con guardas de sesión
├── data/
│   ├── models/                # Gasto, Ingreso, Ahorro, Deuda, Suscripcion, etc.
│   └── repositories/          # AuthRepository, FinanceRepository
├── features/
│   ├── auth/                  # login, registro, recuperación + providers
│   ├── home/                  # HomeShell (drawer + bottom nav)
│   ├── dashboard/             # KPIs + donut + evolución
│   ├── transactions/          # gastos e ingresos
│   ├── ahorro/ deudas/ suscripciones/ resumen/ settings/
└── shared/
    ├── widgets/               # KpiCard, SectionCard, MonthSelector, EmptyState
    └── providers/             # finance, month, theme

firestore.rules                # reglas de seguridad (pegar en consola)
firestore.indexes.json         # índices (vacío: no se requieren ahora)
docs/ANALISIS_Y_ARQUITECTURA.md
```
