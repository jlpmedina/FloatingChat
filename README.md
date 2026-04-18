# FloatingChat

Aplicacion de chat flotante para macOS, construida con SwiftUI y AppKit.

## Que hace

- Muestra un panel flotante siempre accesible.
- Se integra en la barra de menu de macOS.
- Permite mostrar u ocultar el panel con el atajo global Cmd + Shift + Space.
- Envia mensajes a OpenAI usando el endpoint de chat completions.
- Guarda la API key en Keychain y la configuracion no sensible en UserDefaults.

## Requisitos

- macOS
- Xcode 15+
- Una API key de OpenAI

## Como ejecutar

1. Abre [FloatingChat.xcodeproj](FloatingChat.xcodeproj) en Xcode.
2. Selecciona el esquema FloatingChat.
3. Ejecuta con Product > Run.
4. Abre Ajustes (icono de engrane) y agrega tu API key.

## Uso rapido

- Escribe un mensaje y presiona Enter para enviar.
- Usa Shift + Enter para salto de linea.
- Usa el menu de la barra de menu para Mostrar / Ocultar y Salir.
- Boton de papelera para limpiar el historial local de la conversacion.

## Estructura del proyecto

- [FloatingChat/](FloatingChat/): codigo fuente principal de la app.
- [FloatingChat/ContentView.swift](FloatingChat/ContentView.swift): interfaz de chat, burbujas, input y ajustes.
- [FloatingChat/OpenAIService.swift](FloatingChat/OpenAIService.swift): cliente HTTP para OpenAI y manejo de errores.
- [FloatingChat/FloatingChatApp.swift](FloatingChat/FloatingChatApp.swift): arranque de app, panel flotante, status bar y hotkey.
- [Package.swift](Package.swift): suite de pruebas rapida para la logica principal con Swift Package Manager.
- [FloatingChat/Assets.xcassets/](FloatingChat/Assets.xcassets/): iconos y recursos visuales.
- [FloatingChat.xcodeproj/](FloatingChat.xcodeproj/): configuracion del proyecto de Xcode.

## Notas

- La API key se guarda en el llavero del usuario actual.
- Si el panel no aparece, usa el item de la barra de menu para mostrarlo.
- El bundle compilado FloatingChat.app no debe versionarse en Git.

## Tests

Ejecuta `swift test` desde la raiz del proyecto para correr los tests del ViewModel y del cliente HTTP.

## Licencia

Pendiente de definir.
