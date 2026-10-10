<#
claude-cuenta: abre Claude Code con la cuenta que elijas, en Windows.

Cada cuenta tiene su propia carpeta de configuración (CLAUDE_CONFIG_DIR) con su propia sesión iniciada,
pero COMPARTE con tu configuración normal (~\.claude) la memoria, los agentes, las skills, los plugins,
settings.json y CLAUDE.md mediante enlaces, así que en todas las cuentas Claude sabe lo mismo.

Uso:
  claude-cuenta                  menú para elegir cuenta
  claude-cuenta <nombre>         abre directamente esa cuenta
  claude-cuenta nueva <nombre>   crea una cuenta (después, dentro de Claude, haz /login con esa cuenta)
  claude-cuenta lista            muestra las cuentas
  claude-cuenta <nombre> -- -c   lo que va después de «--» se le pasa a claude (aquí: continuar la última sesión)

Configuración: %USERPROFILE%\.claude-cuentas\cuentas.json (ver cuentas.ejemplo.json).
#>
$Resto = [string[]]$args

$ErrorActionPreference = 'Stop'
$Base = Join-Path $env:USERPROFILE '.claude'
$Raiz = Join-Path $env:USERPROFILE '.claude-cuentas'
$FicheroConfig = Join-Path $Raiz 'cuentas.json'

# --- configuración ---------------------------------------------------------------------------------
$Config = $null
if (Test-Path $FicheroConfig) { $Config = Get-Content $FicheroConfig -Raw -Encoding UTF8 | ConvertFrom-Json }

# Qué se comparte con la configuración normal (carpetas por junction, ficheros por hardlink)
$Compartido = @('projects', 'agents', 'skills', 'plugins')
$Ficheros = @('settings.json', 'CLAUDE.md')
if ($Config -and $Config.compartir) { $Compartido = @($Config.compartir) }
if ($Config -and $Config.compartir_ficheros) { $Ficheros = @($Config.compartir_ficheros) }

# Argumentos que se pasan siempre a claude (p. ej. "--dangerously-skip-permissions"); vacío por defecto
$ArgsFijos = @()
if ($Config -and $Config.argumentos_claude) { $ArgsFijos = @($Config.argumentos_claude) }

# Tabla nombre -> { carpeta, etiqueta }. carpeta "" = tu configuración normal (~\.claude)
$Tabla = [ordered]@{}
$Alias = @{}
if ($Config -and $Config.cuentas) {
    foreach ($c in $Config.cuentas) {
        $carp = if ($null -ne $c.carpeta) { [string]$c.carpeta } else { [string]$c.nombre }
        $Tabla[[string]$c.nombre] = @{ Carpeta = $carp; Etiqueta = [string]$c.etiqueta }
        if ($c.alias) { foreach ($a in $c.alias) { $Alias[[string]$a] = [string]$c.nombre } }
    }
}
if (-not ($Tabla.Values | Where-Object { $_.Carpeta -eq '' })) {
    # sin configuración: la cuenta normal se llama «personal»
    $nueva = [ordered]@{ 'personal' = @{ Carpeta = ''; Etiqueta = 'configuración normal (~\.claude)' } }
    foreach ($k in $Tabla.Keys) { $nueva[$k] = $Tabla[$k] }
    $Tabla = $nueva
}

function Cuentas {
    $l = @($Tabla.Keys)
    $usadas = @($Tabla.Values | ForEach-Object { $_.Carpeta })
    if (Test-Path $Raiz) { $l += (Get-ChildItem $Raiz -Directory | Sort-Object Name | Where-Object { $usadas -notcontains $_.Name } | ForEach-Object Name) }
    return $l
}

function Etiqueta([string]$nombre) {
    if ($Tabla.Contains($nombre)) { return $Tabla[$nombre].Etiqueta }
    return ''
}

function Carpeta([string]$nombre) {
    if ($Tabla.Contains($nombre)) { return $Tabla[$nombre].Carpeta }
    return $nombre
}

function Crear([string]$nombre) {
    if ($nombre -notmatch '^[a-z0-9_-]+$') { throw "Nombre no válido: usa minúsculas, números, - o _" }
    if ($Tabla.Contains($nombre) -or $Alias.ContainsKey($nombre)) { throw "«$nombre» ya existe" }
    $dir = Join-Path $Raiz $nombre
    if (Test-Path $dir) { throw "Ya hay una carpeta «$nombre» en $Raiz" }
    New-Item -ItemType Directory -Force $dir | Out-Null
    foreach ($c in $Compartido) {
        $origen = Join-Path $Base $c; $destino = Join-Path $dir $c
        if (-not (Test-Path $origen)) { New-Item -ItemType Directory -Force $origen | Out-Null }
        if (-not (Test-Path $destino)) { New-Item -ItemType Junction -Path $destino -Target $origen | Out-Null }
    }
    foreach ($f in $Ficheros) {
        $origen = Join-Path $Base $f; $destino = Join-Path $dir $f
        if ((Test-Path $origen) -and -not (Test-Path $destino)) { New-Item -ItemType HardLink -Path $destino -Target $origen | Out-Null }
    }
    # Servidores MCP de la configuración normal (sin copiar su identidad: la sesión se inicia con /login)
    $estado = Join-Path $dir '.claude.json'
    $normal = Join-Path $env:USERPROFILE '.claude.json'
    if ((-not (Test-Path $estado)) -and (Test-Path $normal)) {
        # PowerShell 5 no lee ese JSON (claves que solo cambian en mayúsculas): se copia con Python si está
        $py = Get-Command python -ErrorAction SilentlyContinue
        if ($py) { & python (Join-Path $PSScriptRoot 'claude-cuenta-mcp.py') $normal $estado }
        if (-not (Test-Path $estado)) { Write-Host "Aviso: no se copiaron los servidores MCP (añádelos luego con claude mcp add)" -ForegroundColor Yellow }
    }
    Write-Host "Cuenta «$nombre» creada en $dir" -ForegroundColor Green
    Write-Host "Comparte memoria, agentes, skills, plugins y ajustes con tu configuración normal; la sesión es suya." -ForegroundColor Green
    Write-Host "Ahora se abre Claude: escribe /login y entra con la cuenta que quieras para «$nombre»." -ForegroundColor Cyan
    Write-Host "Opcional: ponle nombre y etiqueta en $FicheroConfig" -ForegroundColor DarkGray
}

function Abrir([string]$nombre, [string[]]$extra) {
    if ($Alias.ContainsKey($nombre)) { $nombre = $Alias[$nombre] }
    $carp = Carpeta $nombre
    if ($carp -eq '') {
        Remove-Item Env:CLAUDE_CONFIG_DIR -ErrorAction SilentlyContinue
    } else {
        $dir = Join-Path $Raiz $carp
        if (-not (Test-Path $dir)) { throw "No existe la cuenta «$nombre». Créala con: claude-cuenta nueva $nombre" }
        $env:CLAUDE_CONFIG_DIR = $dir
        # carpeta de trabajo fija de la cuenta (inicio.txt, opcional): arranca ahí con su CLAUDE.md
        $ini = Join-Path $dir 'inicio.txt'
        if (Test-Path $ini) {
            $carpeta = (Get-Content $ini -Raw).Trim()
            if ($carpeta -and (Test-Path $carpeta)) { Set-Location $carpeta; Write-Host "Carpeta de trabajo: $carpeta" -ForegroundColor Cyan }
        }
    }
    $et = Etiqueta $nombre
    Write-Host ("Claude Code con la cuenta: $nombre" + $(if ($et) { "  ($et)" } else { '' })) -ForegroundColor Cyan
    # argumentos fijos de la configuración, salvo que ya se pase un modo de permisos a mano
    $modos = @('--dangerously-skip-permissions', '--permission-mode', '--allow-dangerously-skip-permissions')
    $fijos = $ArgsFijos
    if ($extra | Where-Object { $modos -contains $_ }) { $fijos = @($ArgsFijos | Where-Object { $modos -notcontains $_ }) }
    $todo = @(@($fijos) + @($extra) | Where-Object { $_ })
    & claude @todo
}

# separar lo que va para claude (después de «--»)
$extra = @(); $args2 = @()
$i = [array]::IndexOf([string[]]$Resto, '--')
if ($Resto -and $i -ge 0) { $args2 = @($Resto[0..($i - 1)] | Where-Object { $_ }); if ($i + 1 -lt $Resto.Count) { $extra = $Resto[($i + 1)..($Resto.Count - 1)] } }
elseif ($Resto) { $args2 = $Resto }

switch ($args2.Count) {
    0 {
        $l = Cuentas
        Write-Host "Cuentas de Claude Code:" -ForegroundColor Cyan
        for ($k = 0; $k -lt $l.Count; $k++) { Write-Host ("  {0}) {1,-20} {2}" -f ($k + 1), $l[$k], (Etiqueta $l[$k])) }
        Write-Host "  n) crear una cuenta nueva"
        $r = Read-Host "Elige"
        if ($r -eq 'n') { $nom = Read-Host "Nombre de la cuenta (p. ej. trabajo)"; Crear $nom; Abrir $nom $extra }
        elseif ($r -match '^\d+$' -and [int]$r -ge 1 -and [int]$r -le $l.Count) { Abrir $l[[int]$r - 1] $extra }
        else { Write-Host "Opción no válida" -ForegroundColor Red }
    }
    default {
        $cmd = $args2[0].ToLower()
        if ($cmd -eq 'lista') { Cuentas | ForEach-Object { Write-Host ("  {0,-20} {1}" -f $_, (Etiqueta $_)) } }
        elseif ($cmd -eq 'nueva') { if ($args2.Count -lt 2) { throw "Uso: claude-cuenta nueva <nombre>" }; Crear $args2[1].ToLower(); Abrir $args2[1].ToLower() $extra }
        else { Abrir $cmd $extra }
    }
}
