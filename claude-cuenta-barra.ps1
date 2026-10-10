<#
Barra de estado de Claude Code que muestra en qué cuenta estás (la usa el statusLine de settings.json).
Lee CLAUDE_CONFIG_DIR, busca la cuenta en %USERPROFILE%\.claude-cuentas\cuentas.json y pinta su etiqueta con su color.
Instálala en todas las cuentas con: claude-cuenta barra
#>
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$e = [char]27

# Claude Code pasa por stdin un JSON con el modelo, la carpeta, etc.
$modelo = ''
try {
    $entrada = [Console]::In.ReadToEnd() | ConvertFrom-Json
    if ($entrada.model.display_name) { $modelo = [string]$entrada.model.display_name }
} catch { }

$Raiz = Join-Path $env:USERPROFILE '.claude-cuentas'
$carpeta = ''
if ($env:CLAUDE_CONFIG_DIR) { $carpeta = Split-Path ($env:CLAUDE_CONFIG_DIR.TrimEnd('\', '/')) -Leaf }

$nombre = if ($carpeta) { $carpeta } else { 'personal' }
$etiqueta = ''
$color = ''
$config = Join-Path $Raiz 'cuentas.json'
if (Test-Path $config) {
    $cfg = Get-Content $config -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($c in $cfg.cuentas) {
        $carp = if ($null -ne $c.carpeta) { [string]$c.carpeta } else { [string]$c.nombre }
        if ($carp -eq $carpeta) { $nombre = [string]$c.nombre; $etiqueta = [string]$c.etiqueta; $color = [string]$c.color; break }
    }
}

# colores del TEXTO: verde para la configuración normal, amarillo para el resto, salvo que cuentas.json diga otro (nombre o #RRGGBB)
$codigos = @{ rojo = '91'; verde = '92'; amarillo = '93'; azul = '94'; morado = '95'; cian = '96'; gris = '37'; blanco = '97' }
if (-not $color) { $color = if ($carpeta) { 'amarillo' } else { 'verde' } }
if ($color -match '^#?([0-9a-fA-F]{6})$') {
    # color exacto (#RRGGBB); necesita una terminal con color real (Windows Terminal)
    $h = $Matches[1]
    $cod = '38;2;{0};{1};{2}' -f [Convert]::ToInt32($h.Substring(0, 2), 16), [Convert]::ToInt32($h.Substring(2, 2), 16), [Convert]::ToInt32($h.Substring(4, 2), 16)
} else {
    $cod = $codigos[$color.ToLower()]
    if (-not $cod) { $cod = $codigos['amarillo'] }
}

$texto = "● $nombre"
if ($etiqueta) { $texto += " · $etiqueta" }
$linea = "$e[1;${cod}m$texto$e[0m"
if ($modelo) { $linea += "  $e[37m$modelo$e[0m" }
[Console]::Out.Write($linea)
