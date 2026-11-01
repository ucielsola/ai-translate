# Commits atómicos

- Al terminar y verificar cada cambio lógico, crear un commit que incluya solo los archivos de ese cambio.
- Separar implementación, documentación y reglas cuando representen trabajos independientes. No agrupar cambios ajenos ni modificar trabajo previo del usuario.
- Revisar `git diff --cached` y `git diff --cached --check` antes de confirmar. No registrar credenciales, archivos del Kindle ni `reference/`.
- Usar un mensaje breve que describa el resultado. Informar el hash del commit al usuario.
- No hacer push ni publicar una release salvo que el usuario lo pida.
