# Instala claude-cuenta: copia los scripts a %USERPROFILE%\.claude-cuentas\bin y añade esa carpeta al PATH del usuario.
$ErrorActionPreference = 'Stop'
$Raiz = Join-Path $env:USERPROFILE '.claude-cuentas'
$Bin = Join-Path $Raiz 'bin'
New-Item -ItemType Directory -Force $Bin | Out-Null
foreach ($f in 'claude-cuenta.cmd', 'claude-cuenta.ps1', 'claude-cuenta-mcp.py', 'claude-cuenta-ajuste.py', 'claude-cuenta-barra.ps1') {
    Copy-Item (Join-Path $PSScriptRoot $f) (Join-Path $Bin $f) -Force
}

$config = Join-Path $Raiz 'cuentas.json'
if (-not (Test-Path $config)) {
    $json = @'
{
  "cuentas": [
    { "nombre": "personal", "carpeta": "", "etiqueta": "configuración normal (~\\.claude)" }
  ],
  "argumentos_claude": []
}
'@
    [IO.File]::WriteAllText($config, $json, (New-Object Text.UTF8Encoding($false)))
    Write-Host "Creado $config (edítalo para poner nombres y etiquetas)" -ForegroundColor Green
}

$path = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($path -split ';') -notcontains $Bin) {
    [Environment]::SetEnvironmentVariable('Path', ($path.TrimEnd(';') + ';' + $Bin), 'User')
    Write-Host "Añadido $Bin al PATH del usuario. Abre una terminal nueva." -ForegroundColor Yellow
}
Write-Host "Listo. Prueba: claude-cuenta nueva trabajo" -ForegroundColor Cyan
