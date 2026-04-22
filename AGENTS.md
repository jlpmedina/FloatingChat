# AGENTS.md — FloatingChat

## Descripción del proyecto

FloatingChat es una aplicación nativa para macOS (macOS 13+) que muestra un panel de chat flotante siempre accesible desde la barra de menú. Está construida con SwiftUI y AppKit, y se comunica con la API de OpenAI (chat completions).

- **Repositorio remoto:** `git@github.com:jlpmedina/FloatingChat.git`
- **Branch principal:** `main`
- **Tecnologías:** Swift 5, SwiftUI, AppKit, Swift Package Manager (tests), Xcode 15+
- **Plataforma:** macOS 13+ (arm64 / x86_64)

## Estructura del proyecto

```
FloatingChat/
├── FloatingChat/                  # Código fuente principal de la app
│   ├── FloatingChatApp.swift      # Punto de entrada, panel flotante, status bar, hotkey
│   ├── ContentView.swift          # Interfaz de chat, burbujas, input y ajustes
│   ├── MessageBubble.swift        # Componente de burbuja de mensaje
│   ├── SettingsSheet.swift        # Hoja de ajustes
│   ├── ChatViewModel.swift        # ViewModel del chat
│   ├── OpenAIService.swift        # Cliente HTTP para OpenAI
│   ├── ChatModels.swift           # Modelos de datos del chat
│   ├── APIKeyStore.swift          # Almacenamiento de API key en Keychain
│   ├── AppSettingsStore.swift     # Configuración en UserDefaults
│   ├── AppConfiguration.swift     # Configuración general de la app
│   ├── HotKeyController.swift     # Controlador de atajo global (Cmd+Shift+Space)
│   ├── Info.plist                 # Versión, bundle ID, sandbox, LSUIElement
│   └── Assets.xcassets/           # Iconos y recursos
├── FloatingChat.xcodeproj/        # Proyecto de Xcode
├── Package.swift                  # Swift Package Manager (librería core + tests)
├── Tests/                         # Tests unitarios del core
├── screens/                       # Capturas de pantalla para README
├── FloatingChat.app/              # Build release copiado en raíz (NO versionar en Git)
├── FloatingChat-Release.zip       # Zip del build release (NO versionar en Git)
└── FloatingChat-Release-X.Y.Z.zip # Zip versionado del release
```

## Versión de la app

La versión se define en **dos lugares** que deben mantenerse sincronizados:

1. **`FloatingChat/Info.plist`**
   - `CFBundleShortVersionString` → versión pública (ej: `1.0.3`)
   - `CFBundleVersion` → build number (ej: `4`)

2. **`FloatingChat.xcodeproj/project.pbxproj`**
   - `MARKETING_VERSION` → igual a `CFBundleShortVersionString`
   - `CURRENT_PROJECT_VERSION` → igual a `CFBundleVersion`

> Importante: existen dos bloques (Debug y Release); ambos deben actualizarse.

## Flujo de release

Seguir estos pasos para generar un nuevo release:

### 1. Incrementar versión
- Actualizar `CFBundleShortVersionString` y `CFBundleVersion` en `FloatingChat/Info.plist`.
- Actualizar `MARKETING_VERSION` y `CURRENT_PROJECT_VERSION` en ambas configuraciones (Debug/Release) de `FloatingChat.xcodeproj/project.pbxproj`.

### 2. Build Release
```bash
xcodebuild -project FloatingChat.xcodeproj \
  -scheme FloatingChat \
  -configuration Release \
  -derivedDataPath build/release-derived \
  build
```
El `.app` resultante se encuentra en:
```
build/release-derived/Build/Products/Release/FloatingChat.app
```

### 3. Reemplazar app y generar zip
```bash
# Reemplazar el bundle en raíz
rm -rf FloatingChat.app
cp -R build/release-derived/Build/Products/Release/FloatingChat.app FloatingChat.app

# Generar zip versionado y zip genérico
zip -r --symlinks FloatingChat-Release-X.Y.Z.zip FloatingChat.app
cp FloatingChat-Release-X.Y.Z.zip FloatingChat-Release.zip
```

> **No versionar** `FloatingChat.app` ni los zips en Git (ya están ignorados en `.gitignore` excepto los zips; si se trackean, evitar incluirlos en commits de versión).

### 4. Commit, tag y push
```bash
git add FloatingChat/Info.plist FloatingChat.xcodeproj/project.pbxproj
git commit -m "Bump version to X.Y.Z"
git tag -a X.Y.Z -m "Release X.Y.Z"
git push origin main --follow-tags
```

### 5. Crear release en GitHub (CLI)
```bash
gh release create X.Y.Z FloatingChat-Release-X.Y.Z.zip \
  --title "FloatingChat X.Y.Z" \
  --notes "Release X.Y.Z"
```

## Tests

Ejecutar desde la raíz del proyecto:
```bash
swift test
```

## Notas para agentes

- La API key de OpenAI se guarda en el **Keychain** del usuario; nunca debe hardcodearse.
- La app funciona como `LSUIElement` (sin ícono en el Dock), viviendo solo en la barra de menú.
- El atajo global para mostrar/ocultar el panel es **Cmd + Shift + Space**.
- Si se modifica la estructura de archivos en `FloatingChat/`, revisar `Package.swift` para asegurar que las rutas de `exclude` y `sources` sigan siendo correctas.

## Permisos de Accesibilidad

El atajo global (`HotKeyController.swift`) se registra mediante las APIs de **Carbon** (`RegisterEventHotKey` / `InstallEventHandler`). En macOS moderno, esto requiere que la aplicación esté habilitada en **Seguridad y Privacidad > Accesibilidad** para poder interceptar eventos de teclado a nivel global.

### Comportamiento esperado
- Al primer uso (o si el usuario revoca el permiso), macOS puede mostrar un diálogo indicando que la app quiere controlar el equipo usando funciones de accesibilidad.
- Si el permiso no se otorga, el atajo global **Cmd + Shift + Space** no funcionará; el panel solo se podrá mostrar/ocultar desde el ícono de la barra de menú.

### Instrucciones para el usuario
1. Abrir **Preferencias del Sistema > Seguridad y Privacidad > Accesibilidad** (o **Privacidad y Seguridad > Accesibilidad** en macOS Ventura+).
2. Hacer clic en el candado y autenticarse para realizar cambios.
3. Arrastrar `FloatingChat.app` a la lista de apps permitidas (o usar el botón **+**).
4. Asegurarse de que la casilla junto a `FloatingChat` esté marcada.
5. Si la app ya estaba en la lista pero el atajo no responde, desmarcar y volver a marcar la casilla para forzar la re-autorización.
