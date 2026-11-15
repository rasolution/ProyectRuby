# ProyectRuby

<!-- local-development:start -->
## Desarrollo local

Consulta [RUNNING.md](RUNNING.md) para ubicar cada componente, abrirlo en su IDE, compilarlo y conocer las comprobaciones realizadas y los requisitos pendientes.
<!-- local-development:end -->

<!-- build-repairs-20261115:start -->
## Reparación y comprobación — 2026-11-15

- Rails 4.2 se migró a Rails 8.1.4.1, con Ruby 3.2 en Ubuntu/WSL, Bundler y dependencias actuales.
- El desarrollo y las pruebas usan SQLite. Se corrigieron configuración de activos, almacenamiento, migraciones y retorno de códigos HTTP.
- El login vincula cada token con el usuario autenticado; dejó de compartir tokens por un parámetro de usuario vacío.

Comprobado:

- Zeitwerk carga la aplicación, la base se prepara y las rutas se resuelven.
- Dos pruebas de integración cubren salud, login, CRUD autenticado, logout y separación de tokens entre usuarios.
- Los activos se precompilan con Node 22.

Comandos:

```powershell
.\build-local.ps1 -Action test
.\build-local.ps1 -Action run
```

Alcance pendiente:

- La comprobación se hizo en Ubuntu/WSL; no en Ruby nativo de Windows. No se migró la antigua base MySQL. Se conserva el esquema de contraseñas histórico del ejercicio.

<!-- build-repairs-20261115:end -->
