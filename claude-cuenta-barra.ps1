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

# colores: verde para la configuración normal, amarillo para el resto, salvo que cuentas.json diga otro
$codigos = @{ rojo = '41;97'; verde = '42;30'; amarillo = '43;30'; azul = '44;97'; morado = '45;97'; cian = '46;30'; gris = '100;97' }
if (-not $color) { $color = if ($carpeta) { 'amarillo' } else { 'verde' } }
$cod = $codigos[$color.ToLower()]
if (-not $cod) { $cod = $codigos['amarillo'] }

$texto = " CUENTA: $nombre "
if ($etiqueta) { $texto += "| $etiqueta " }
$linea = "$e[${cod}m$e[1m$texto$e[0m"
if ($modelo) { $linea += "  $modelo" }
[Console]::Out.Write($linea)
