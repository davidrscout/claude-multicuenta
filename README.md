# claude-multicuenta

Varias cuentas de **Claude Code** en el mismo PC con Windows, cada una con su sesión iniciada, **sin cerrar sesión ni volver a hacer `/login`** cada vez que cambias. Sirve, por ejemplo, para tener tu cuenta personal (Max) y las de tu empresa (Team) abiertas en terminales distintas a la vez.

```
> claude-cuenta
Cuentas de Claude Code:
  1) personal             yo@gmail.com - Max (personal)
  2) trabajo              yo@empresa.com - Team Premium (empresa)
  3) soporte              soporte@empresa.com - Team Standard (empresa)
  n) crear una cuenta nueva
Elige:
```

## Cómo funciona

- Cada cuenta tiene su carpeta en `%USERPROFILE%\.claude-cuentas\<nombre>` y se abre con `CLAUDE_CONFIG_DIR` apuntando ahí. Por eso cada una guarda su propia sesión y sus credenciales.
- La memoria (`projects`), los agentes, las skills, los plugins, `settings.json` y `CLAUDE.md` **se comparten** con tu configuración normal (`~\.claude`) mediante enlaces (junctions y hardlinks). Todas las cuentas saben lo mismo y lo que configuras en una vale para todas.
- Al crear una cuenta se copian tus servidores MCP (solo la lista de servidores, nunca tu identidad).
- La cuenta con `"carpeta": ""` es tu configuración de siempre, sin tocar nada.

## Instalación

Necesitas Claude Code (`claude` en el PATH) y PowerShell 5 o superior. Python es opcional: solo se usa para copiar los servidores MCP.

```powershell
git clone https://github.com/davidrscout/claude-multicuenta
cd claude-multicuenta
powershell -ExecutionPolicy Bypass -File .\instalar.ps1
```

Abre una terminal nueva y:

```
claude-cuenta nueva trabajo     # crea la cuenta y abre Claude: escribe /login y entra con esa cuenta
claude-cuenta trabajo           # a partir de ahí, entra directa
claude-cuenta                   # menú
claude-cuenta lista
claude-cuenta trabajo -- -c     # lo que va tras «--» se le pasa a claude (aquí: continuar la última sesión)
```

## Nombres y etiquetas

Edita `%USERPROFILE%\.claude-cuentas\cuentas.json` (ver `cuentas.ejemplo.json`):

```json
{
  "cuentas": [
    { "nombre": "personal", "carpeta": "",        "etiqueta": "yo@gmail.com - Max (personal)", "alias": ["yo"] },
    { "nombre": "trabajo",  "carpeta": "trabajo", "etiqueta": "yo@empresa.com - Team Premium (empresa)" }
  ],
  "argumentos_claude": []
}
```

- `nombre`: lo que escribes en `claude-cuenta <nombre>`. El menú sigue este orden.
- `carpeta`: carpeta dentro de `.claude-cuentas`. Puede ser distinta del nombre, así renombras una cuenta sin mover su carpeta (ni romper una sesión abierta). `""` = configuración normal.
- `alias`: otros nombres que también la abren.
- `argumentos_claude`: argumentos que se pasan siempre a `claude`, por ejemplo `["--dangerously-skip-permissions"]` si trabajas sin confirmaciones (bajo tu responsabilidad). Si pasas un modo de permisos a mano tras `--`, manda el tuyo.
- `compartir` / `compartir_ficheros` (opcionales): qué se comparte con la configuración normal.

Las carpetas que hay en `.claude-cuentas` y no aparecen en el JSON también salen en el menú, con su propio nombre.

### Carpeta de trabajo por cuenta (opcional)

Si en la carpeta de una cuenta creas `inicio.txt` con una ruta (p. ej. `C:\Dev\MiEmpresa`), esa cuenta arranca siempre ahí, con el `CLAUDE.md` de ese proyecto.

### Memoria propia para una cuenta (opcional)

Si quieres que una cuenta **no** comparta la memoria, borra el enlace `projects` dentro de su carpeta (es un junction: borrarlo no toca la memoria original) y crea en su lugar una carpeta normal.

## Notas

- Solo Windows. En macOS y Linux basta con un alias: `CLAUDE_CONFIG_DIR=~/.claude-trabajo claude`.
- Las credenciales de cada cuenta están en su carpeta (`.credentials.json`). No subas `.claude-cuentas` a ningún sitio.
- Respeta las condiciones de cada plan: usa cada cuenta para aquello a lo que está destinada.

---

**English:** run several Claude Code accounts side by side on Windows. Each one gets its own `CLAUDE_CONFIG_DIR` (its own login) while sharing memory, agents, skills, plugins, `settings.json` and `CLAUDE.md` with your normal `~\.claude` through junctions and hardlinks. Install with `instalar.ps1`, then `claude-cuenta nueva work`, `/login`, and from then on `claude-cuenta work`. Names, labels and order live in `%USERPROFILE%\.claude-cuentas\cuentas.json`.

Licencia MIT.
