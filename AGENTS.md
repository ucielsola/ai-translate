# ai-translate

## Objetivo

Este repositorio contiene un plugin independiente de KOReader que ofrece una traducción contextual de la selección actual y, cuando aporta valor, una breve nota sobre su matiz. Muestra el resultado en un popup, sin modificar ni reemplazar el texto del libro.

## Reglas de trabajo

- Mantener el plugin pequeño, independiente y sin dependencia de X-Ray en tiempo de ejecución.
- Seguir la skill externa [KOReader Plugin Development](https://github.com/uttam-salamander/koreader-dev/tree/main/skills/koreader-plugin-dev) para la estructura base, ciclo de vida, widgets y persistencia estándar de KOReader.
- Antes de decidir cómo interactuar con KOReader, consultar la copia local de X-Ray en `reference/xray.koplugin`.
- Tratar X-Ray como referencia de comportamiento para hooks de selección, botones de diccionario, popups, requests asíncronos, cancelación y extracción de contexto.
- No incorporar funcionalidades ajenas al alcance: reemplazo de selección, copia automática, diccionario independiente, escaneo del libro, personajes, timeline o cache de X-Ray.
- Probar la lógica pura de Lua fuera de KOReader siempre que sea posible.
- Como no se dispone del emulador de KOReader, reservar las pruebas visuales y de interacción final para el Kindle.
- No incluir `reference/` en el repositorio: está excluido mediante `.gitignore`.
- Crear commits atómicos después de verificar cada cambio lógico, siguiendo `.agents/rules/atomic-commits.md`. No hacer push salvo pedido explícito.

## Alcance de configuración

Las opciones visibles deben limitarse a provider e idioma objetivo. La API key es técnicamente obligatoria, pero puede almacenarse en configuración persistente. Endpoint y modelo deben usar defaults internos para providers conocidos; solo un provider personalizado necesita configurarlos explícitamente.

El idioma origen se detecta automáticamente y el contexto se obtiene con límites internos razonables.

## Convenciones

- Preferir módulos pequeños y responsabilidades separadas.
- Mantener la estructura mínima de plugin con `_meta.lua` y `main.lua`.
- Usar `WidgetContainer`, `LuaSettings`, `DataStorage`, `UIManager` y widgets nativos de KOReader cuando correspondan.
- Mantener los mensajes y la UI legibles en pantallas e-ink pequeñas.
- Toda solicitud de red debe tener timeout, cancelación y manejo de errores.
- No enviar el libro completo: solo la selección y contexto cercano limitado.
- Traducir únicamente el texto seleccionado; el contexto sirve para desambiguar y apoyar una nota breve cuando sea útil, sin añadir hechos inventados.

## Estado del trabajo

El plan inicial se considera terminado cuando existe como `plans/ai-translate-plan-[done].md`, después de completar y verificar la implementación.
