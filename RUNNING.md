# Ejecución y comprobación local

## Entorno

Aplicación Rails en `proyecto/`. Validada con Ubuntu/WSL, Ruby 3.2.3, Bundler 4.0.24, Rails 8.1.4.1, SQLite y Node 22 para precompilar activos. Ruby nativo de Windows y producción no están certificados. Puedes editar desde VS Code con WSL, Antigravity o Sublime Text.

Instala Ruby y sus herramientas de compilación, SQLite y cabeceras de desarrollo en WSL. Instala Bundler compatible con el lockfile (`gem install bundler -v 4.0.24`). El script ejecuta `bundle check` o `bundle install`; necesita red la primera vez. Las gemas se guardan fuera del repositorio en `$HOME/.local/share/gh-ruby-gems`, configurable con `GH_RUBY_BUNDLE_PATH`. Si existe `/opt/gh-node22/bin`, lo agrega al PATH; en otros equipos instala Node 22 o configura el PATH de WSL.

Desde PowerShell en la raíz del repositorio:

```powershell
.\build-local.ps1 -Action test
.\build-local.ps1 -Action build
.\build-local.ps1 -Action run
```

La distribución predeterminada es Ubuntu; puedes usar `-Distribution NombreDeTuDistro`. Desde Linux/WSL: `sh scripts/run-local.sh test`, `build` o `run`.

- `test`: prepara una base SQLite temporal y ejecuta **toda** la suite Rails. Elimina esa base al terminar. Si proporcionas `RAILS_TEST_DATABASE_PATH` en WSL, usa y conserva esa ruta: debe ser exclusivamente de pruebas porque Rails carga fixtures.
- `build`: comprueba autoload con Zeitwerk, prepara/migra la base del entorno y precompila activos. No inicia servidor.
- `run`: prepara/migra la base y arranca Puma en `127.0.0.1:3000`. Abre esa dirección; termina con Ctrl+C. El puerto se puede cambiar mediante `PORT` en WSL.

## Datos y primera cuenta

**Respalda tu base antes de ejecutar `build` o `run` sobre datos existentes.** Desarrollo usa `proyecto/storage/development.sqlite3`; las variables WSL `RAILS_DEVELOPMENT_DATABASE_PATH`, `RAILS_TEST_DATABASE_PATH` y `RAILS_DATABASE_PATH` permiten rutas distintas por entorno. La antigua base MySQL no fue importada. No copies datos de producción al entorno de pruebas.

La migración nueva añade `password_digest`, conserva tablas y campos históricos y no intenta adivinar contraseñas. No hay registro público ni usuario predeterminado. Crea tu cuenta en una consola Rails local después de preparar la base:

```sh
cd proyecto
export BUNDLE_PATH="${GH_RUBY_BUNDLE_PATH:-$HOME/.local/share/gh-ruby-gems}"
bundle exec rails console
```

En la consola, solicita la contraseña sin escribirla en el historial:

```ruby
require 'io/console'
secret = IO.console.getpass('Contraseña propia (8 caracteres mínimo, 72 bytes máximo): ')
User.create!(username: 'tu_usuario', password: secret, password_confirmation: secret)
secret.clear
exit
```

Los nombres de usuario son únicos y no se cambian después de crear la cuenta. Una cuenta autenticada también puede crear otras mediante la API; este ejercicio no implementa administradores ni roles. El catálogo es compartido.

## Interfaz y API

La raíz muestra el login y las pestañas Productos, Intercambios y Mi cuenta. Los formularios mantienen sus datos si falla una operación; la búsqueda no altera registros. Precio y estado son enteros entre 0 y 2147483647; no se truncan fracciones. Un intercambio necesita dos productos existentes y distintos. Se rechaza el mismo par ordenado; el inverso se considera otro par. Para borrar un producto, elimina primero sus intercambios relacionados.

API JSON:

- `POST /signin` con `{"user":{"username":"...","password":"..."}}`: devuelve `auth_token`, `username` y `expires_at`. Un login correcto rota el token anterior.
- Envía `Authorization: Bearer TOKEN` para `/products.json`, `/transactions.json` y `/users.json`. Sigue aceptándose el encabezado sin prefijo de clientes antiguos.
- Productos: `product[name]`, `product[price]`, `product[state]`. Intercambios: `transaction[offert_product_id]`, `transaction[require_product_id]`; se conserva el nombre histórico `offert` por compatibilidad.
- Crear con POST devuelve 201; editar con PATCH devuelve 200; borrar con DELETE devuelve 204. Validación: 422; producto referenciado: 409; ID inexistente/malformado: 404; token vencido: 401; objeto obligatorio ausente: 400.
- `/users.json` solo lista tu identidad. Consultar, editar o borrar otra cuenta devuelve 404. Cambiar contraseña mediante PATCH requiere `password`, `password_confirmation` y `password_challenge` (contraseña actual); revoca todos sus tokens.
- `DELETE /logout` revoca el token; el GET histórico sigue disponible por compatibilidad.

Los tokens vencen a las 24 horas desde el login. La interfaz los mantiene en memoria: recargar requiere autenticarse otra vez. BCrypt limita contraseñas a 72 **bytes**, que pueden ser menos de 72 caracteres Unicode. Un login MD5 histórico correcto actualiza el registro y limpia el hash antiguo si la contraseña cabe en ese límite; las contraseñas históricas más largas siguen verificándose con MD5 sin truncarlas y deben cambiarse explícitamente para migrar. Los campos sensibles se filtran de los logs y no se serializan en respuestas de cuentas.

CORS está cerrado a otros orígenes por defecto. Para clientes que controles, configura `LOCAL_API_ALLOWED_ORIGINS` en WSL con una lista separada por comas de orígenes exactos.

## Evidencia y límites

40 pruebas / 193 aserciones aprobadas: CRUD, códigos HTTP, asociaciones, validaciones, identidades aisladas, tokens, vencimiento, MD5/BCrypt y cambio de contraseña. Un recorrido adicional en Edge 157 comprobó productos, intercambios, contraseña/logout y tamaños 320/390/768. SQLite y perfil de navegador independientes; no se modificaron cuentas reales ni la base de desarrollo. Zeitwerk y precompilación se comprueban antes de publicar.

El prototipo todavía no tiene restricciones únicas/foráneas nuevas para intercambios en SQL: las validaciones de modelo no garantizan exclusión de duplicados ante escrituras concurrentes desde múltiples instancias. Los tokens se conservan en la tabla histórica sin hashing. No incluye limitación de intentos, HTTPS configurado, recuperación por correo, separación de catálogos por cuenta ni despliegue público. Las vistas scaffold antiguas se conservan; la interfaz web de la raíz es el cliente verificado.

`.gitignore` excluye bases y archivos auxiliares de storage, logs, gemas locales, estado del editor y activos generados. Lockfiles, fuentes, migraciones, fixtures sintéticas y scripts sí se versionan. No se distribuye un instalador ni se cambiaron servicios del equipo.
