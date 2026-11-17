# RÍOVA – Guardianes del Río 💧

App móvil educativa para niños (Android, Flutter) sobre los ríos **Malacatos** y **Zamora** de Loja, Ecuador.
Los niños recorren los 13 sectores del río en un mapa real, escanean los tótems QR del recorrido, juegan
minijuegos, ganan gotitas y medallas, y personalizan a su avatar.

Proyecto de la asignatura **Plataformas Móviles – UTPL**. El contenido de los sectores (textos, testimonios y
fotos) proviene del periódico *«Todo lo que necesita conocer sobre los afluentes que recorren nuestra ciudad»*,
Taller de Proyectos Urbano Arquitectónicos II, Loja, enero 2026.

## Funcionalidades

- **Mapa real** (OpenStreetMap) con el trazado real de los ríos, los 13 sectores (A1–A4 Sur, B1–B3 Centro,
  C1–C6 Norte), filtros por río y zona, ubicación GPS y vista ilustrada de "Ruta de aventura".
- **Ficha de cada sector**: noticia, fotos reales, voces de vecinos, problemas del río, línea de tiempo,
  especies, deslizador antes/ahora, lectura en voz alta y pregunta de repaso.
- **Escaneo QR** de los tótems con la cámara (o código manual, p. ej. `T03`).
- **9 minijuegos**: Rescata el Río, ¿Cuánto sabes de Loja?, Detective de Inundaciones, Encuentra Palabras,
  El Camino del Agua, Guardianes Naturaleza, Mitos y Verdades, Recicla en la Orilla y Rompecabezas del Río.
  Los extra se desbloquean subiendo de nivel o escaneando tótems.
- **Progresión**: gotitas (XP), 8 niveles, 14 medallas (solo por nivel o por escanear QR), racha diaria y
  misión del día.
- **Tienda de sombreros** para el avatar (10 sombreros), pagados con gotitas disponibles sin bajar de nivel.
- **Semáforo fluvial** con sensores simulados (listos para recibir lecturas reales de sensores IoT).
- **Firebase**: contenido editable desde la consola, avance de cada explorador (sesión anónima) y contadores.

## Tecnologías

Flutter · Dart · Riverpod · go_router · flutter_map (OpenStreetMap) · Firebase (Auth anónima + Cloud Firestore)
· mobile_scanner · geolocator · flutter_tts · shared_preferences

## Cómo ejecutarlo

Requisitos: Flutter 3.47+ (Dart 3.13+) y un teléfono o emulador Android.

```bash
git clone https://github.com/RomeroG05/RIOVA.git
cd RIOVA
flutter pub get
flutter run                       # en un dispositivo conectado
```

APK optimizado:

```bash
flutter build apk --release --split-per-abi
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  (la mayoría de teléfonos actuales)
```

> El APK de release está firmado con la clave de depuración: sirve para instalar y presentar, no para Play Store.

## Estructura

```text
lib/
├── core/            tema, animaciones, mascota "Río", widgets comunes, router
├── data/
│   ├── content/     sectores, juegos, medallas, misiones, sombreros (contenido empaquetado)
│   ├── models/      modelos (Place, ExplorerProgress…)
│   ├── remote/      Firebase: sincronización de contenido y del explorador
│   └── repositories/ guardado local
├── features/        pantallas: onboarding, inicio, mapa, sector, QR, juegos, perfil, tienda, biblioteca
└── state/           estado (Riverpod): explorador, sensores, lectura en voz alta
assets/              fuentes, fotos de los sectores, ícono
firestore.rules      reglas de seguridad de Firestore
tool/                exportar y subir el contenido a Firestore, generar el ícono
test/                pruebas (lógica, juegos, pantallas angostas, tienda)
```

## Firebase (proyecto `appriova`)

| Colección | Contenido |
| --- | --- |
| `sectors`, `quizBank`, `games`, `medals`, `missions`, `sensors`, `meta` | Contenido de la app (lectura pública; se edita desde la consola) |
| `users/{uid}` (+ `visits`, `games`) | Avance de cada explorador; cada teléfono solo ve lo suyo |
| `sectorStats`, `gameStats` | Contadores anónimos |

- Lo que se edite en Firestore (por ejemplo, el titular de un sector) aparece en la app sin publicar otra versión.
- Para actualizar el contenido desde el código:
  `flutter test tool/export_content_test.dart` y luego `python3 tool/seed_firestore.py --prune`
  (con las reglas activas necesita un token de una cuenta del proyecto; ver el script).
- Publicar las reglas: `firebase deploy --only firestore:rules --project appriova`.
- Los sensores son simulados. Un sensor real puede escribir `sensors/{sector}.live` y `liveAt` con una cuenta
  de servicio (Admin SDK) y la app mostrará esa lectura.

## Pruebas

```bash
flutter analyze
flutter test
```

## Créditos

- Fotos e información de los sectores: periódico del Taller de Proyectos Urbano Arquitectónicos II (UTPL, 2026).
  Algunas imágenes del periódico son de medios o del Municipio de Loja y se citan como allí se indica.
- Mapas © colaboradores de OpenStreetMap.
