# Reglas de ai-translate

## Referencia obligatoria: X-Ray

Ante cualquier duda sobre cómo debe funcionar una integración con KOReader, revisar primero `reference/xray.koplugin`.

En particular, consultar la implementación de X-Ray antes de modificar:

- hooks del popup de selección o diccionario;
- lectura de `selected_text`, `pos0` y `pos1`;
- cierre y limpieza de popups nativos;
- ejecución asíncrona de requests;
- cancelación y limpieza de procesos;
- extracción de texto contextual;
- persistencia de configuración;
- presentación de errores y resultados.

La referencia sirve para entender el comportamiento esperado de KOReader, pero `ai-translate` debe conservar una arquitectura propia y mínima.

## Pruebas

- Las pruebas aisladas deben cubrir prompts, JSON, UTF-8, configuración, límites de contexto y errores.
- La prueba manual en Kindle debe cubrir selección, popup, traducción, cancelación, desconexión y retorno a la lectura.
- No declarar terminada una integración de UI sin probarla en el dispositivo real.
