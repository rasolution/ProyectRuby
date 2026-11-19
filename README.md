# ProyectRuby — productos e intercambios

Aplicación de clase recuperada con Ruby 3.2 y Rails 8.1.4.1. Incluye una interfaz web en español para consultar, buscar, crear, editar y eliminar productos e intercambios, y una API JSON autenticada. El catálogo es compartido entre las cuentas de esta instancia.

## Ejecutar en Windows

Usa Ubuntu en WSL y abre la carpeta en VS Code, Antigravity o Sublime Text. El runtime Ruby se ejecuta en WSL. Consulta [RUNNING.md](RUNNING.md) para instalar dependencias y crear tu primera cuenta.

```powershell
.\build-local.ps1 -Action test
.\build-local.ps1 -Action build
.\build-local.ps1 -Action run
```

Abre <http://127.0.0.1:3000>. No se crea ninguna cuenta con contraseña predeterminada. `build` y `run` preparan la base local; respáldala antes si ya contiene datos. `test` usa una base temporal propia por defecto.

## Reparaciones y mejoras del 18 de noviembre de 2026

- Interfaz adaptable a móvil con búsqueda, formularios, estados de espera, confirmación de borrado y mensajes de validación. JavaScript nativo sin CDN.
- Intercambios validados: ambos productos deben existir y ser diferentes; se rechazan pares duplicados y se protege el borrado de productos relacionados.
- Contraseñas nuevas con BCrypt. Los registros históricos MD5 se actualizan al iniciar sesión correctamente cuando la contraseña cabe en BCrypt; no se reemplazan contraseñas desconocidas.
- Tokens renovados al iniciar sesión, vencimiento de 24 horas, cierre de sesión y revocación al cambiar contraseña. La interfaz los conserva solo en memoria.
- La API de cuentas solo permite consultar/modificar la identidad autenticada y no devuelve contraseñas ni tokens históricos. Cambiar contraseña exige la contraseña actual.
- README, guía de ejecución, exclusiones Git y finales de línea de scripts compatibles con WSL actualizados.

## Comprobado

40 pruebas Rails y 193 aserciones aprobadas en Ubuntu/WSL con SQLite aislado. Recorrido real en Edge 157: login, CRUD de productos, creación/eliminación de intercambios, protección de referencias, cambio de contraseña, nuevo login y logout; vistas de 320, 390 y 768 píxeles sin desbordamiento horizontal ni errores JavaScript. La prueba del navegador es evidencia automatizada del lote, no una suite instalada dentro del repositorio.

El precio y el estado conservan el esquema original de enteros; no representan importes decimales ni un nuevo sistema de monedas. Se mantiene como prototipo local: no incluye roles, aislamiento por propietario, límites de intentos de login, despliegue público ni migración de la antigua base MySQL. Consulta [RUNNING.md](RUNNING.md).
