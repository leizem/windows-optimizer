# HT Technology — Windows Optimizer Pro
# Build Script: gera o MSI usando WiX Toolset v3
# Uso / Usage: .\build-msi.ps1
# Requisito / Requires: WiX Toolset v3.14+ instalado

param(
    [string]$Version = "3.3.0.0",
    [string]$OutDir  = "..\dist"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Localiza o WiX
$wixBin = @(
    "C:\Program Files (x86)\WiX Toolset v3.14\bin",
    "C:\Program Files\WiX Toolset v3.14\bin",
    "${env:WIX}bin"
) | Where-Object { Test-Path "$_\candle.exe" } | Select-Object -First 1

if (-not $wixBin) {
    Write-Error "WiX Toolset nao encontrado. Instale via: winget install WiXToolset.WiXToolset"
    exit 1
}

$candle = "$wixBin\candle.exe"
$light  = "$wixBin\light.exe"
$wxs    = "$ScriptDir\HT-Optimizer.wxs"
$outDir = "$ScriptDir\$OutDir"
$wixobj = "$ScriptDir\tmp\HT-Optimizer.wixobj"
$msi    = "$outDir\HT-Technology-WindowsOptimizer-Pro-v$($Version.Substring(0,3)).msi"

New-Item -ItemType Directory -Force $outDir  | Out-Null
New-Item -ItemType Directory -Force "$ScriptDir\tmp" | Out-Null

Push-Location $ScriptDir

Write-Host "=== HT Technology MSI Build ===" -ForegroundColor Cyan
Write-Host "WiX   : $wixBin"
Write-Host "Source: $wxs"
Write-Host "Output: $msi"
Write-Host ""

# Etapa 1: Compilar .wxs -> .wixobj
Write-Host "[1/2] Compilando com candle..." -ForegroundColor Yellow
& $candle -nologo -arch x64 -ext "WixUtilExtension" -out $wixobj $wxs
if ($LASTEXITCODE -ne 0) { Write-Error "candle.exe falhou."; exit 1 }

# Etapa 2: Linkar .wixobj -> .msi
Write-Host "[2/2] Linkando com light..." -ForegroundColor Yellow
& $light -nologo `
    -ext "WixUIExtension" `
    -ext "WixUtilExtension" `
    -cultures:pt-BR`;en-US `
    -spdb -out $msi $wixobj
if ($LASTEXITCODE -ne 0) { Write-Error "light.exe falhou."; exit 1 }

Pop-Location

# Resultado
$fi = Get-Item $msi
Write-Host ""
Write-Host "=== BUILD CONCLUIDO ===" -ForegroundColor Green
Write-Host "Arquivo : $($fi.Name)"
Write-Host "Tamanho : $([math]::Round($fi.Length/1MB,2)) MB"
Write-Host "SHA256  : $((Get-FileHash $msi -Algorithm SHA256).Hash)"
Write-Host "Path    : $($fi.FullName)"
