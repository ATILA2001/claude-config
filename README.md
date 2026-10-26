# claude-config

Mis reglas para Claude Code (extensión de VS Code), versionadas para usarlas igual en cualquier PC.

## Qué hay

| Archivo | Qué es | Dónde termina |
|---|---|---|
| `global/CLAUDE.md` | Reglas para todos los proyectos | Se importa desde `%USERPROFILE%\.claude\CLAUDE.md` |
| `global/settings.json` | Permisos (`ask`) y atribución desactivada | Se combina con `%USERPROFILE%\.claude\settings.json` |
| `proyectos/net10.md` | Reglas para repos .NET 10 | `CLAUDE.md` o `CLAUDE.local.md` de cada repo |
| `proyectos/net48.md` | Reglas para repos .NET Framework 4.8 | `CLAUDE.md` o `CLAUDE.local.md` de cada repo |
| `instalar.ps1` | Instala todo lo anterior | — |

## Instalar en una PC nueva

```powershell
git clone https://github.com/<tu-usuario>/claude-config.git "$env:USERPROFILE\claude-config"
cd "$env:USERPROFILE\claude-config"
powershell -ExecutionPolicy Bypass -File .\instalar.ps1
```

- Cloná el repo **dentro de tu perfil y sin espacios en la ruta**. Así el import queda como `@~/claude-config/...` y un `git pull` alcanza para actualizar las reglas.
- `-ExecutionPolicy Bypass` vale solo para esa ejecución; no cambia la configuración de Windows.
- El script es seguro de correr varias veces. Antes de modificar un archivo existente guarda una copia `.bak-<fecha>`.

## Aplicar reglas a un repositorio

Para el equipo (crea `CLAUDE.md` con una copia de las reglas, para commitear):

```powershell
powershell -ExecutionPolicy Bypass -File .\instalar.ps1 -SoloProyecto -Proyecto C:\Repos\MiApp -Tipo net48
```

Solo para vos (crea `CLAUDE.local.md`, que importa las reglas desde este repo y queda excluido de Git en esa PC):

```powershell
powershell -ExecutionPolicy Bypass -File .\instalar.ps1 -SoloProyecto -Proyecto C:\Repos\MiApi -Tipo net10 -Local
```

Si el repo ya tiene un `CLAUDE.md` o `CLAUDE.local.md`, el script no lo toca: combinalo a mano.

## Cambiar una regla

1. Editá el archivo en este repo.
2. Commit y push.
3. En las otras PCs, `git pull`.

| Qué cambiaste | Qué hacer después del `git pull` |
|---|---|
| `global/CLAUDE.md` | Nada: se aplica en la próxima conversación. |
| `global/settings.json` | Volver a correr `instalar.ps1`. |
| `proyectos/*.md` en repos con `-Local` | Nada: se aplica en la próxima conversación. |
| `proyectos/*.md` en repos con `CLAUDE.md` del equipo | Actualizar ese `CLAUDE.md` a mano y commitearlo en el repo. |

## Verificar que funciona

1. Abrí en VS Code la carpeta raíz de un repo.
2. Iniciá una conversación **nueva** de Claude Code (las abiertas no releen `CLAUDE.md`).
3. Preguntá: *"¿Qué reglas tenés cargadas desde CLAUDE.md?"*
4. Pedí un commit de prueba: tiene que aparecer la tarjeta de aprobación.

Si Claude Code pide aprobar la importación de archivos externos, aceptala.

## Qué hace el script con tu configuración actual

- `CLAUDE.md` global: si ya existía, lo guarda como copia y lo reemplaza por el import. Pasá a `global/CLAUDE.md` cualquier regla propia que tuviera la copia.
- `settings.json` global: no lo pisa. Agrega la atribución vacía y las reglas `ask` que falten; el resto de tus claves (modelo, `allow`, hooks, etc.) queda igual.
- Repos: nunca pisa un `CLAUDE.md` existente.

## Importante

Este repo es solo de reglas: mantenelo **privado** y no guardes contraseñas, tokens ni cadenas de conexión.
