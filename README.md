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
- La memoria (`projects`), los agentes, las skills, los plugins y `CLAUDE.md` **se comparten** con tu configuración normal (`~\.claude`) mediante enlaces (junctions y hardlinks). Todas las cuentas saben lo mismo.
- `settings.json` empieza enlazado, pero Claude Code lo reescribe al cambiar un ajuste y a partir de ahí cada cuenta tiene el suyo (por ejemplo, otro modelo por defecto). Por eso `claude-cuenta barra` lo edita en todas.
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
claude-cuenta barra             # muestra la cuenta en la barra de estado de Claude (claude-cuenta barra quitar: la quita)
```

## Saber en qué cuenta estás

Con `claude-cuenta barra`, la barra de estado de cada terminal (la línea de abajo, junto al modo de permisos) muestra la cuenta con un color, para no pedirle a la cuenta de la empresa algo que no toca:

```
 CUENTA: personal | yo@gmail.com - Max (personal)            Opus
 CUENTA: trabajo | yo@empresa.com - Team Premium (empresa)   Opus
```

La cuenta se deduce de `CLAUDE_CONFIG_DIR`, así que también funciona si abres `claude` directamente. Por defecto la configuración normal sale en verde y las demás en amarillo; cámbialo con `"color"` en cada cuenta (`rojo`, `verde`, `amarillo`, `azul`, `morado`, `cian`, `gris`). Si ya tenías una barra de estado propia, este comando la sustituye (queda copia en `settings.json.antes_claude-cuenta`).

## Nombres y etiquetas

Edita `%USERPROFILE%\.claude-cuentas\cuentas.json` (ver `cuentas.ejemplo.json`):

```json
{
  "cuentas": [
    { "nombre": "personal", "carpeta": "",        "etiqueta": "yo@gmail.com - Max (personal)", "alias": ["yo"] },
    { "nombre": "trabajo",  "carpeta": "trabajo", "etiqueta": "yo@empresa.com - Team Premium (empresa)", "color": "rojo" }
  ],
  "argumentos_claude": []
}
```

- `nombre`: lo que escribes en `claude-cuenta <nombre>`. El menú sigue este orden.
- `carpeta`: carpeta dentro de `.claude-cuentas`. Puede ser distinta del nombre, así renombras una cuenta sin mover su carpeta (ni romper una sesión abierta). `""` = configuración normal.
- `alias`: otros nombres que también la abren.
- `color`: color de la cuenta en la barra de estado.
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

## Uso permitido: lo que dicen los términos de Anthropic

Esta herramienta **solo** cambia la carpeta de configuración con la que arranca `claude`. No automatiza nada, no rota cuentas, no inicia sesión por ti y no copia ni comparte credenciales: cada cuenta se abre con su propio `/login`, por el flujo oficial de Anthropic, y la usa una persona delante del teclado. Úsala así. Resumen de las normas aplicables (lee siempre el texto original, que es el que vale y puede cambiar):

- **Qué términos se aplican.** Las cuentas Free, Pro y Max se rigen por los [Términos de servicio del consumidor](https://www.anthropic.com/legal/consumer-terms); Team, Enterprise y API, por los [Términos comerciales](https://www.anthropic.com/legal/commercial-terms) ([Legal y cumplimiento de Claude Code](https://code.claude.com/docs/es/legal-and-compliance)).
- **Nada de acceso automatizado con cuentas de consumidor.** Los Términos del consumidor (sección 3) prohíben acceder a los Servicios «through automated or non-human means, whether through a bot, script, or otherwise», salvo con una clave de API de Anthropic o cuando Anthropic lo permita explícitamente. No uses estas cuentas para bots, tareas desatendidas o procesos que se lancen solos; para eso está la API con clave de [Claude Console](https://platform.claude.com/).
- **Cada cuenta es de una persona.** No puedes compartir tus credenciales ni poner tu cuenta a disposición de otra persona (Términos del consumidor, sección 2). Eres responsable de todo lo que se haga con ella.
- **Uso ordinario e individual.** Los límites anunciados de Pro y Max «asumen el uso ordinario e individual de Claude Code y el Agent SDK». No uses varias cuentas para saltarte límites de uso: los términos prohíben eludir los sistemas o medidas de protección de Anthropic.
- **El login de Claude.ai es solo para el flujo de Anthropic.** No se permite que terceros ofrezcan inicio de sesión de Claude.ai en sus aplicaciones, enruten peticiones con credenciales Free/Pro/Max en nombre de otros usuarios ni recopilen, almacenen o intermedien credenciales o tokens de sesión. Quien construya un producto, incluido el Agent SDK, debe usar clave de API.
- **Planes de empresa.** Si una cuenta es de Team o Enterprise, úsala para lo que tu organización o el programa que te la dio permitan.
- **Consecuencias.** Anthropic puede suspender o cancelar cuentas que incumplan los términos, y puede hacerlo sin aviso previo.

Este proyecto no está afiliado a Anthropic ni respaldado por ella. «Claude» y «Claude Code» son marcas de Anthropic.

---

**English:** run several Claude Code accounts side by side on Windows. Each one gets its own `CLAUDE_CONFIG_DIR` (its own login) while sharing memory, agents, skills, plugins, `settings.json` and `CLAUDE.md` with your normal `~\.claude` through junctions and hardlinks. Install with `instalar.ps1`, then `claude-cuenta nueva work`, `/login`, and from then on `claude-cuenta work`. Names, labels and order live in `%USERPROFILE%\.claude-cuentas\cuentas.json`.

It only switches the config folder: it does not automate anything, rotate accounts or handle credentials. Use each account interactively, by its owner, under Anthropic's terms: the [Consumer Terms](https://www.anthropic.com/legal/consumer-terms) forbid automated or non-human access with Free/Pro/Max accounts (except via an API key or where explicitly permitted) and sharing your account, Pro/Max limits assume ordinary individual use, and third parties may not broker Claude.ai logins or route requests through subscription credentials ([Claude Code legal and compliance](https://code.claude.com/docs/en/legal-and-compliance)). Not affiliated with or endorsed by Anthropic.

Licencia MIT.
