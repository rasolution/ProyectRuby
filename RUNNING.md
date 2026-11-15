

<!-- local-development:start -->
# Desarrollo local

Puedes abrir este repositorio en VS Code, Antigravity o Sublime Text. El compilador y los servicios necesarios dependen del componente indicado abajo.

## Ruby / Rails

Usa la versión de Ruby y el Gemfile de cada aplicación en WSL o Linux. Crea una base de datos local y ejecuta sus pruebas antes de iniciarla. El editor de Windows no aporta el runtime Ruby.

## Componentes y validación

Inventario y compilaciones locales del 2026-11-15. Una compilación correcta no acredita todavía interacción, compatibilidad de base de datos, instalador ni despliegue.

| Componente | Tipo / destino | Validación |
| --- | --- | --- |
| [proyecto/Gemfile](<proyecto/Gemfile>) | ruby | Sin ejecutar |

## Archivos ignorados

`.gitignore` excluye credenciales locales, estado del editor y salidas de las herramientas detectadas. No deja de versionar archivos que ya estaban en Git. Los manifiestos, archivos de bloqueo, recursos fuente y scripts de esquema forman parte del código.
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
