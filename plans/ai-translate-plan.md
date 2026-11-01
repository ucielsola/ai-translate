# ai-translate — plan de implementación

## Objetivo

Crear un plugin independiente de KOReader llamado `ai-translate` que traduzca el texto seleccionado de forma contextual y muestre el resultado en un popup, sin modificar ni reemplazar el texto del libro.

## Alcance funcional

- Agregar una acción `Translate` / `Traducir` al popup de selección y, cuando corresponda, al popup de diccionario.
- Capturar el texto seleccionado y su posición (`selected_text`, `pos0`, `pos1`).
- Obtener contexto cercano del documento actual.
- Enviar selección, contexto e idioma objetivo al proveedor configurado.
- Mostrar únicamente la traducción en un popup legible para Kindle.
- Permitir cancelar la solicitud y mostrar errores comprensibles.
- Detectar automáticamente el idioma origen.

Fuera de alcance:

- Reemplazar la selección.
- Copiar automáticamente al portapapeles.
- Funcionalidad de diccionario o explicación de entidades.
- Escaneo completo del libro, cache de personajes o protección contra spoilers de X-Ray.
- Emulador de KOReader por ahora.

## Arquitectura prevista

Plugin propio, sin depender de X-Ray en tiempo de ejecución.

Módulos mínimos previstos:

- `_meta.lua`: metadata requerida por el loader de plugins de KOReader.
- `main.lua`: ciclo de vida, registro del plugin y hooks de selección.
- `translator.lua`: construcción del prompt, request HTTP y parsing de respuesta.
- `config.lua`: defaults y configuración persistente.
- `ui.lua`: popup de progreso, resultado, cancelación y errores.
- `context.lua`: extracción y limitación del contexto cercano.
- `tests/`: pruebas aisladas de Lua para configuración, prompts, parsing y errores.

La estructura base seguirá la skill externa [KOReader Plugin Development](https://github.com/uttam-salamander/koreader-dev/tree/main/skills/koreader-plugin-dev), usando `WidgetContainer`, `LuaSettings`, `DataStorage`, `UIManager` y widgets nativos cuando correspondan.

La codebase local de X-Ray en `reference/xray.koplugin` será la referencia obligatoria cuando exista cualquier duda sobre APIs, hooks, selección, popups, contexto o requests de KOReader.

## Configuración

Opciones visibles mínimas:

- `provider`.
- `target_language`.

Configuración técnica necesaria:

- API key o credencial del provider.
- Defaults internos de endpoint y modelo para providers conocidos.
- Para providers personalizados: endpoint y modelo.

El idioma origen será automático. El tamaño del contexto, timeout, modelo predeterminado y formato de request serán defaults internos, salvo que la implementación revele que alguno debe exponerse.

Providers iniciales recomendados:

- Gemini.
- OpenAI-compatible.

La capa de transporte deberá permitir agregar Claude, DeepSeek u otros sin modificar la integración con la selección.

## Flujo de usuario

1. El usuario selecciona un fragmento.
2. KOReader muestra el popup nativo.
3. El usuario toca `Traducir`.
4. El plugin cierra el popup nativo y conserva el texto seleccionado.
5. Se obtiene contexto cercano, con límites para evitar requests excesivos.
6. Se muestra un popup de progreso con opción de cancelar.
7. Se realiza la solicitud asíncrona.
8. Se muestra la traducción final en un popup.
9. Ante error, se muestra el motivo y se permite cerrar sin afectar la lectura.

## Traducción contextual

El prompt debe distinguir explícitamente:

- texto seleccionado: fragmento que debe traducirse;
- contexto: texto auxiliar para interpretar significado;
- idioma objetivo: idioma de salida;
- restricción: traducir solamente la selección;
- preservación: mantener nombres propios, formato y saltos de línea cuando corresponda;
- salida: devolver únicamente la traducción, sin comentarios ni análisis.

El contexto se limitará alrededor de la posición de la selección. No se enviará automáticamente el libro completo.

## Pruebas

### Pruebas aisladas

- Carga y defaults de configuración.
- Selección de provider y validación de credenciales.
- Construcción de prompts con texto simple, texto largo y Unicode.
- Parsing de respuestas válidas y respuestas incompletas.
- Manejo de errores HTTP, timeout, cancelación y respuesta vacía.
- Límites de tamaño del contexto.
- Escape correcto de JSON y UTF-8.

### Pruebas en Kindle

- Instalación y carga del plugin.
- Aparición del botón en selección de una palabra.
- Aparición del botón en selección de varias líneas.
- Traducción con Gemini y provider OpenAI-compatible.
- Textos con acentos, CJK, cirílico y emojis si el documento los contiene.
- Popup de progreso y cancelación.
- Respuesta larga en pantalla pequeña.
- Error sin conexión y credencial inválida.
- Cierre del popup y regreso normal a la lectura.

## Criterios de aceptación

- La selección no se modifica.
- El resultado no depende de un lookup de diccionario.
- El contexto mejora la interpretación sin traducir contenido adicional.
- La interfaz sigue siendo usable en pantalla e-ink pequeña.
- Una falla de red no bloquea KOReader ni deja diálogos huérfanos.
- El plugin puede instalarse como una carpeta `.koplugin` independiente.
- La referencia de X-Ray permanece excluida por Git.

## Orden de implementación

1. Esqueleto del plugin (`_meta.lua` y `main.lua`) y carga desde el menú de KOReader.
2. Integración con el popup de selección, siguiendo X-Ray como referencia.
3. Popup mínimo de resultado con texto fijo/mock.
4. Contexto cercano y límites de tamaño.
5. Cliente HTTP asíncrono y provider inicial.
6. Configuración persistente y validaciones.
7. Cancelación, errores y limpieza de UI.
8. Pruebas aisladas.
9. Instalación y pruebas manuales en Kindle.

## Regla de referencia

Ante cualquier duda sobre cómo debe interactuar el plugin con KOReader, primero revisar la copia local de X-Ray y documentar la decisión en el código o en el plan antes de implementar una variante propia.
