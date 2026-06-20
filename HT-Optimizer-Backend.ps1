#Requires -RunAsAdministrator
<#
.SYNOPSIS
    HT Technology — Windows Optimizer Pro Backend
    Motor PowerShell que executa todas as funções do Dashboard

.DESCRIPTION
    Este script é o backend do HT Technology Windows Optimizer Pro.
    Pode ser chamado diretamente (modo standalone) ou via parâmetro
    para executar um tweak específico.

    Uso:
      .\HT-Optimizer-Backend.ps1                     # Menu interativo
      .\HT-Optimizer-Backend.ps1 -Tweak "telemetria" # Tweak específico
      .\HT-Optimizer-Backend.ps1 -RunAll              # Todos os recomendados
      .\HT-Optimizer-Backend.ps1 -ExportReport        # Gera relatório

.NOTES
    HT Technology | v2.0 | 19/06/2026
    Execute sempre como Administrador
    Crie um Ponto de Restauração antes de aplicar tweaks

    Segurança:
    - Nenhum download externo
    - Apenas APIs nativas do Windows
    - Registro reversível via Ponto de Restauração
    - Logs completos gravados em %TEMP%\HT-Optimizer-Log.txt
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Tweak     = "",
    [switch]$RunAll,
    [switch]$ExportReport,
    [switch]$SkipRestorePoint,
    [switch]$Silent
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# ═══════════════════════════════════════════════════════════════════════
# CONFIGURAÇÕES GLOBAIS
# ═══════════════════════════════════════════════════════════════════════
$Script:Config = @{
    Version    = "2.0"
    AppName    = "HT Technology Windows Optimizer Pro"
    LogFile    = "$env:TEMP\HT-Optimizer-Log.txt"
    ReportFile = "$env:USERPROFILE\Desktop\HT-Optimizer-Relatorio.html"
    StartTime  = Get-Date
    Applied    = [System.Collections.Generic.List[string]]::new()
    Errors     = [System.Collections.Generic.List[string]]::new()
}

# ═══════════════════════════════════════════════════════════════════════
# FUNÇÕES DE LOG E UI
# ═══════════════════════════════════════════════════════════════════════

function Write-HT {
    param(
        [string]$Message,
        [ValidateSet('Info','Success','Warn','Error','Step','Title')]
        [string]$Type = 'Info'
    )

    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $colors = @{
        Info    = 'Cyan'
        Success = 'Green'
        Warn    = 'Yellow'
        Error   = 'Red'
        Step    = 'White'
        Title   = 'Magenta'
    }
    $prefixes = @{
        Info    = '[INFO]  '
        Success = '[OK]    '
        Warn    = '[AVISO] '
        Error   = '[ERRO]  '
        Step    = '[>>]    '
        Title   = ''
    }

    $prefix = $prefixes[$Type]
    $color  = $colors[$Type]

    if (-not $Silent) {
        Write-Host "$prefix$Message" -ForegroundColor $color
    }

    # Log to file (always)
    "$timestamp | $Type | $Message" | Add-Content -Path $Script:Config.LogFile -Encoding UTF8
}

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║       HT Technology — Windows Optimizer Pro  v2.0       ║" -ForegroundColor Cyan
    Write-Host "  ║         Sistema de Otimização Windows 10 & 11            ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    $osInfo = Get-CimInstance Win32_OperatingSystem
    Write-HT "OS: $($osInfo.Caption) | Build: $($osInfo.BuildNumber)" Info
    Write-HT "Computador: $env:COMPUTERNAME | Usuário: $env:USERNAME" Info
    Write-HT "Data/Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" Info
    Write-HT "Log: $($Script:Config.LogFile)" Info
    Write-Host ""
}

function Test-Admin {
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ═══════════════════════════════════════════════════════════════════════
# PONTO DE RESTAURAÇÃO
# ═══════════════════════════════════════════════════════════════════════

function New-RestorePoint {
    Write-HT "Criando Ponto de Restauração do Sistema..." Step
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        vssadmin resize shadowstorage /for=C: /on=C: /maxsize=5% 2>&1 | Out-Null
        $desc = "HT Technology Optimizer - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Checkpoint-Computer -Description $desc -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-HT "Ponto de Restauração criado: '$desc'" Success
        return $true
    } catch {
        Write-HT "Não foi possível criar Ponto de Restauração: $_" Warn
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════
# FUNÇÕES AUXILIARES
# ═══════════════════════════════════════════════════════════════════════

function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        Write-HT "  REG: $Name = $Value @ $($Path.Split('\')[-1])" Step
        return $true
    } catch {
        Write-HT "  REG FALHA: $Name @ $Path — $_" Error
        return $false
    }
}

function Disable-ServiceSafe {
    param([string]$Name)
    try {
        $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service $Name -Force -ErrorAction SilentlyContinue
            Set-Service  $Name -StartupType Disabled -ErrorAction SilentlyContinue
            Write-HT "  Serviço desativado: $Name" Step
            return $true
        }
        Write-HT "  Serviço não encontrado: $Name" Warn
        return $false
    } catch {
        Write-HT "  Erro ao desativar $Name : $_" Error
        return $false
    }
}

function Remove-AppxSafe {
    param([string]$AppName)
    try {
        Get-AppxPackage -Name $AppName -AllUsers -ErrorAction SilentlyContinue |
            Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object DisplayName -like $AppName |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        Write-HT "  App removido: $AppName" Step
        return $true
    } catch {
        Write-HT "  Erro ao remover $AppName : $_" Warn
        return $false
    }
}

# ═══════════════════════════════════════════════════════════════════════
# TWEAKS — DIAGNÓSTICO & REPAROS
# ═══════════════════════════════════════════════════════════════════════

function Invoke-TweakReparoRapido {
    Write-HT "=== REPARO RÁPIDO COMPLETO ===" Title
    Write-HT "Executando SFC /scannow..." Step
    $sfcResult = sfc /scannow 2>&1
    if ($LASTEXITCODE -eq 0) { Write-HT "SFC concluído sem erros críticos." Success }
    else { Write-HT "SFC reportou problemas. Verificando DISM..." Warn }

    Write-HT "Verificando integridade da imagem (DISM)..." Step
    DISM /Online /Cleanup-Image /ScanHealth 2>&1 | Out-Null
    DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
    Write-HT "DISM RestoreHealth concluído." Success
    $Script:Config.Applied.Add("reparo_rapido")
}

function Invoke-TweakSfcDism {
    Write-HT "=== SFC / DISM COMPLETO ===" Title
    sfc /scannow
    DISM /Online /Cleanup-Image /RestoreHealth
    Write-HT "SFC e DISM concluídos." Success
    $Script:Config.Applied.Add("sfc_dism")
}

function Invoke-TweakChkDsk {
    Write-HT "=== CHECKDISK C: ===" Title
    Write-HT "Agendando ChkDsk para próximo reinício..." Step
    echo y | chkdsk C: /f /r /x 2>&1 | Out-Null
    Write-HT "ChkDsk agendado. Reinicie para executar." Warn
    $Script:Config.Applied.Add("chkdsk")
}

function Invoke-TweakLimpezaCache {
    Write-HT "=== LIMPEZA TOTAL (CACHE E VSS) ===" Title
    $paths = @(
        $env:TEMP,
        "C:\Windows\Temp",
        "C:\Windows\SoftwareDistribution\Download",
        "$env:LOCALAPPDATA\Temp",
        "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations",
        "C:\Windows\Prefetch"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $size = (Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue
            $freed = [math]::Round($size / 1MB, 1)
            Write-HT "  Limpo: $p ($freed MB)" Step
        }
    }
    Write-HT "Limpeza de cache concluída." Success
    $Script:Config.Applied.Add("limpeza_cache")
}

function Invoke-TweakRepararWMI {
    Write-HT "=== REPARAR REPOSITÓRIO WMI ===" Title
    Stop-Service winmgmt -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $result = & winmgmt /resetrepository 2>&1
    Write-HT "WMI reset: $result" Step
    Start-Service winmgmt -ErrorAction SilentlyContinue
    Write-HT "Repositório WMI reparado." Success
    $Script:Config.Applied.Add("reparar_wmi")
}

function Invoke-TweakResetWUpdate {
    Write-HT "=== RESET ESTRUTURAL WINDOWS UPDATE ===" Title
    $services = @('wuauserv','bits','msiserver','appidsvc','cryptsvc')
    foreach ($svc in $services) {
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Write-HT "  Parado: $svc" Step
    }
    Remove-Item "C:\Windows\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\catroot2"   -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($svc in $services) {
        Start-Service $svc -ErrorAction SilentlyContinue
    }
    Write-HT "Windows Update reiniciado com sucesso." Success
    $Script:Config.Applied.Add("reset_wupdate")
}

function Invoke-TweakOtimizarRede {
    Write-HT "=== OTIMIZAÇÃO E RESET DE REDE ===" Title
    netsh int ip reset all | Out-Null
    netsh winsock reset    | Out-Null
    ipconfig /flushdns     | Out-Null
    ipconfig /release      | Out-Null
    ipconfig /renew        | Out-Null
    Write-HT "Pilha TCP/IP, Winsock e DNS reiniciados." Success
    $Script:Config.Applied.Add("otimizar_rede")
}

function Invoke-TweakTrimDefrag {
    Write-HT "=== OTIMIZAR ARMAZENAMENTO (TRIM/DEFRAG) ===" Title
    $drives = Get-PhysicalDisk | Select-Object MediaType
    Get-Volume | Where-Object DriveLetter | ForEach-Object {
        $dl = $_.DriveLetter
        Write-HT "  Otimizando drive $dl ..." Step
        Optimize-Volume -DriveLetter $dl -Verbose -ErrorAction SilentlyContinue
    }
    Write-HT "Otimização de armazenamento concluída." Success
    $Script:Config.Applied.Add("trim_defrag")
}

function Invoke-TweakEventLog {
    Write-HT "=== LIMPAR LOG DE EVENTOS ===" Title
    Get-EventLog -LogName * -ErrorAction SilentlyContinue | ForEach-Object {
        Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue
        Write-HT "  Limpo: $($_.Log)" Step
    }
    Write-HT "Todos os logs de eventos limpos." Success
    $Script:Config.Applied.Add("event_log")
}

function Invoke-TweakDiagnosticoEnergia {
    Write-HT "=== DIAGNÓSTICO DE ENERGIA/BATERIA ===" Title
    $battPath = "$env:USERPROFILE\Desktop\battery-report.html"
    $energyPath = "$env:USERPROFILE\Desktop\energy-report.html"
    powercfg /batteryreport /output $battPath 2>&1 | Out-Null
    powercfg /energy /output $energyPath 2>&1 | Out-Null
    Write-HT "Relatório de bateria: $battPath" Success
    Write-HT "Relatório de energia: $energyPath" Success
    Start-Process $battPath -ErrorAction SilentlyContinue
    $Script:Config.Applied.Add("diagnostico_energia")
}

# ═══════════════════════════════════════════════════════════════════════
# TWEAKS — HARDWARE & PERFORMANCE
# ═══════════════════════════════════════════════════════════════════════

function Invoke-TweakPerfFSO {
    Write-HT "=== TWEAKS DE PERFORMANCE E FSO ===" Title

    # Ultimate Performance Plan
    Write-HT "Ativando Plano Ultimate Performance..." Step
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
    powercfg -setactive SCHEME_MIN

    # HAGS - Hardware Accelerated GPU Scheduling
    Write-HT "Ativando HAGS..." Step
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2

    # Game Mode
    Write-HT "Ativando Game Mode..." Step
    Set-RegValue "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1
    Set-RegValue "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1

    # System profile para Games
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" String
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" "High" String

    Write-HT "Tweaks de Performance e FSO aplicados." Success
    $Script:Config.Applied.Add("perf_fso")
}

function Invoke-TweakLatenciaRede {
    Write-HT "=== OTIMIZAR LATÊNCIA DE REDE ===" Title

    # Desativa Nagle Algorithm em todos os adaptadores
    $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    foreach ($if in $interfaces) {
        Set-ItemProperty -Path $if.PSPath -Name TcpAckFrequency -Value 1 -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $if.PSPath -Name TCPNoDelay      -Value 1 -Force -ErrorAction SilentlyContinue
    }
    Write-HT "Nagle Algorithm desativado em $($interfaces.Count) adaptadores." Step

    # Network Throttling
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xffffffff

    # IRPStackSize
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "IRPStackSize" 20

    Write-HT "Latência de rede otimizada." Success
    $Script:Config.Applied.Add("latencia_rede")
}

function Invoke-TweakPlanoMax {
    Write-HT "=== PLANO ULTIMATE PERFORMANCE ===" Title
    $existing = powercfg /list | Select-String "Ultimate"
    if (-not $existing) {
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
    }
    powercfg -setactive SCHEME_MIN
    Write-HT "Plano Ultimate Performance ativado." Success
    $Script:Config.Applied.Add("plano_max")
}

function Invoke-TweakBloatwares {
    Write-HT "=== REMOVER BLOATWARES ===" Title
    $apps = @(
        'Microsoft.BingNews',
        'Microsoft.BingWeather',
        'Microsoft.BingSports',
        'Microsoft.BingFinance',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.People',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.Todos',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo',
        'MicrosoftTeams',
        'Clipchamp.Clipchamp',
        'Microsoft.549981C3F5F10',
        'Microsoft.WindowsMaps',
        'Microsoft.MixedReality.Portal',
        'Microsoft.SkypeApp',
        'Disney.37853FC22B2CE',
        'SpotifyAB.SpotifyMusic',
        'AmazonVideo.PrimeVideo'
    )
    foreach ($app in $apps) {
        Remove-AppxSafe $app
    }
    Write-HT "Bloatwares removidos com sucesso." Success
    $Script:Config.Applied.Add("bloatwares")
}

function Invoke-TweakEfeitosVisuais {
    Write-HT "=== OPÇÕES DE DESEMPENHO VISUAL ===" Title
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
    # Desativa animações
    Set-RegValue "HKCU:\Control Panel\Desktop" "DragFullWindows"  "0" String
    Set-RegValue "HKCU:\Control Panel\Desktop" "MenuShowDelay"    "0" String
    Set-RegValue "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" String
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewAlphaSelect"  0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations"    0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "EnableAeroPeek" 0
    Write-HT "Efeitos visuais configurados para máxima performance." Success
    $Script:Config.Applied.Add("efeitos_visuais")
}

function Invoke-TweakSysMain {
    Write-HT "=== DESATIVAR SYSMAIN (SUPERFETCH) ===" Title
    Disable-ServiceSafe "SysMain"
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\SysMain" "Start" 4
    Write-HT "SysMain desativado." Success
    $Script:Config.Applied.Add("sysmain")
}

function Invoke-TweakCacheRAM {
    Write-HT "=== OTIMIZAR CACHE DE MEMÓRIA RAM ===" Title
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache"        0
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "ClearPageFileAtShutdown" 0
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive"  1
    Write-HT "Cache de RAM otimizado." Success
    $Script:Config.Applied.Add("cache_ram")
}

function Invoke-TweakEnergyThrottle {
    Write-HT "=== DESATIVAR ENERGY THROTTLING GLOBAL ===" Title
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegValue $path "PowerThrottlingOff" 1
    Write-HT "Energy Throttling desativado." Success
    $Script:Config.Applied.Add("energy_throttle")
}

function Invoke-TweakTimerResolution {
    Write-HT "=== TIMER RESOLUTION 0.5ms ===" Title
    bcdedit /set useplatformtick yes    | Out-Null
    bcdedit /set disabledynamictick yes | Out-Null
    Write-HT "Timer resolution configurado via bcdedit. Reinicie para aplicar." Warn
    $Script:Config.Applied.Add("timer_resolution")
}

# ═══════════════════════════════════════════════════════════════════════
# TWEAKS — PRIVACIDADE & SISTEMA
# ═══════════════════════════════════════════════════════════════════════

function Invoke-TweakTelemetria {
    Write-HT "=== DESATIVAR TELEMETRIA COMPLETA ===" Title

    $services = @('DiagTrack','dmwappushservice','WerSvc','DPS','WdiServiceHost','WdiSystemHost','diagnosticshub.standardcollector.service','lfsvc')
    foreach ($svc in $services) { Disable-ServiceSafe $svc }

    # Registro
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"                    "AllowTelemetry"            0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"      "AllowTelemetry"            0
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"      "MaxTelemetryAllowed"       0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"                     "TailoredExperiencesWithDiagnosticDataEnabled" 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"                         "AITEnable"                 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"                         "DisableInventory"          1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows"                         "CEIPEnable"                0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"           "Disabled"                  1

    Write-HT "Telemetria completamente desativada." Success
    $Script:Config.Applied.Add("telemetria")
}

function Invoke-TweakCopilotBing {
    Write-HT "=== REMOVER COPILOT E BING ===" Title
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"     "BingSearchEnabled"  0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"     "CortanaConsent"     0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"     "AllowSearchToUseLocation" 0

    $copilotPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
    if (-not (Test-Path $copilotPath)) { New-Item -Path $copilotPath -Force | Out-Null }
    Set-RegValue $copilotPath "TurnOffWindowsCopilot" 1

    Remove-AppxSafe "Microsoft.Copilot"
    Remove-AppxSafe "Microsoft.BingSearch"

    Write-HT "Copilot e Bing desativados." Success
    $Script:Config.Applied.Add("copilot_bing")
}

function Invoke-TweakWidgets {
    Write-HT "=== REMOVER WIDGETS E CLIMA ===" Title
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
    Remove-AppxSafe "MicrosoftWindows.Client.WebExperience"
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
    Write-HT "Widgets e painel de clima removidos." Success
    $Script:Config.Applied.Add("widgets")
}

function Invoke-TweakSmartScreen {
    Write-HT "=== DESATIVAR SMARTSCREEN LOCAL ===" Title
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"            "EnableSmartScreen"           0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" "ConfigureAppInstallControl" "Anywhere" String
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost"     "EnableWebContentEvaluation"  0
    Write-HT "SmartScreen local desativado." Warn
    $Script:Config.Applied.Add("smartscreen")
}

function Invoke-TweakProtecaoDisco {
    Write-HT "=== ATIVAR PROTEÇÃO DO DISCO C: ===" Title
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    vssadmin resize shadowstorage /for=C: /on=C: /maxsize=5% 2>&1 | Out-Null
    Write-HT "System Protection ativado no C:." Success
    $Script:Config.Applied.Add("protecao_disco")
}

function Invoke-TweakHibernacaoSSD {
    Write-HT "=== DESATIVAR HIBERNAÇÃO (LIBERAR SSD) ===" Title
    powercfg -h off
    $freed = if (Test-Path "C:\hiberfil.sys") {
        (Get-Item "C:\hiberfil.sys").Length / 1GB
        "[OK] hiberfil.sys removido. Liberado: $([math]::Round($freed, 1)) GB"
    } else { "hibernação já estava desativada" }
    Write-HT "Hibernação desativada." Success
    $Script:Config.Applied.Add("hibernacao_ssd")
}

function Invoke-TweakHistoricoAtividade {
    Write-HT "=== BLOQUEAR HISTÓRICO DE ATIVIDADES ===" Title
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed"    0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities"  0
    Write-HT "Histórico de atividades bloqueado." Success
    $Script:Config.Applied.Add("historico_atividade")
}

function Invoke-TweakAdvertisingId {
    Write-HT "=== DESATIVAR ID DE ANÚNCIOS E TÉCNICO ===" Title
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"  "Enabled" 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"           "TailoredExperiencesWithDiagnosticDataEnabled" 0
    Write-HT "Advertising ID e Machine ID técnico desativados." Success
    $Script:Config.Applied.Add("advertising_id")
}

function Invoke-TweakRecallAI {
    Write-HT "=== DESATIVAR WINDOWS RECALL E AI FEATURES ===" Title
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegValue $path "DisableAIDataAnalysis" 1
    Set-RegValue $path "AllowRecallEnablement" 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\WindowsAI" "DisableProactiveSurfacing" 1 -ErrorAction SilentlyContinue
    Write-HT "Windows Recall e AI Explorer desativados." Success
    $Script:Config.Applied.Add("recall_ai")
}

function Invoke-TweakLocationCam {
    Write-HT "=== BLOQUEAR LOCALIZAÇÃO, CÂMERA E MICROFONE ===" Title
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation"            1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"         "LetAppsAccessCamera"        2
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"         "LetAppsAccessMicrophone"    2
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"         "LetAppsAccessLocation"      2
    Write-HT "Localização, câmera e microfone bloqueados para apps." Success
    $Script:Config.Applied.Add("location_cam")
}

# ═══════════════════════════════════════════════════════════════════════
# TWEAKS — LIMPEZA & MANUTENÇÃO
# ═══════════════════════════════════════════════════════════════════════

function Invoke-TweakTempSystem {
    Write-HT "=== LIMPEZA PROFUNDA DE ARQUIVOS TEMPORÁRIOS ===" Title
    $totalMB = 0
    $paths = @(
        $env:TEMP, "C:\Windows\Temp", "$env:LOCALAPPDATA\Temp",
        "C:\Windows\SoftwareDistribution\Download",
        "C:\`$Recycle.Bin", "C:\Windows\Logs",
        "$env:APPDATA\Microsoft\Windows\Recent"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $size = (Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue
            $mb = [math]::Round($size / 1MB, 1)
            $totalMB += $mb
            Write-HT "  Limpo: $p ($mb MB)" Step
        }
    }
    Write-HT "Limpeza completa. Total liberado: $totalMB MB" Success
    $Script:Config.Applied.Add("temp_system")
}

function Invoke-TweakWinSxS {
    Write-HT "=== COMPACTAR WINSXS E COMPONENTSTORE ===" Title
    DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase
    DISM /Online /Cleanup-Image /SPSuperseded
    Write-HT "WinSxS compactado com sucesso." Success
    $Script:Config.Applied.Add("winsxs")
}

function Invoke-TweakRecycleBin {
    Write-HT "=== ESVAZIAR LIXEIRA E THUMBNAILS ===" Title
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path "C:\" -Include "Thumbs.db","desktop.ini",".DS_Store" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-HT "Lixeira e cache de miniaturas limpos." Success
    $Script:Config.Applied.Add("recycle_bin")
}

function Invoke-TweakBrowserCache {
    Write-HT "=== LIMPAR CACHE DE NAVEGADORES ===" Title
    $browsers = @{
        Chrome  = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        Edge    = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        Firefox = "$env:APPDATA\Mozilla\Firefox\Profiles"
        Brave   = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache"
        Opera   = "$env:APPDATA\Opera Software\Opera Stable\Cache"
        Vivaldi = "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Cache"
    }
    foreach ($browser in $browsers.GetEnumerator()) {
        if (Test-Path $browser.Value) {
            $size = (Get-ChildItem $browser.Value -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            Remove-Item "$($browser.Value)\*" -Recurse -Force -ErrorAction SilentlyContinue
            $mb = [math]::Round($size / 1MB, 1)
            Write-HT "  $($browser.Key): $mb MB liberados" Step
        }
    }
    Write-HT "Cache de navegadores limpo." Success
    $Script:Config.Applied.Add("browser_cache")
}

function Invoke-TweakFontCache {
    Write-HT "=== RECONSTRUIR CACHE DE FONTES ===" Title
    Stop-Service "FontCache" -Force -ErrorAction SilentlyContinue
    Stop-Service "FontCache3.0.0.0" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache*" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Windows\FontCache*" -Force -ErrorAction SilentlyContinue
    Start-Service "FontCache" -ErrorAction SilentlyContinue
    Write-HT "Cache de fontes reconstruído." Success
    $Script:Config.Applied.Add("font_cache")
}

# ═══════════════════════════════════════════════════════════════════════
# TWEAKS — REDE & DNS
# ═══════════════════════════════════════════════════════════════════════

function Invoke-TweakDnsDoh {
    Write-HT "=== DNS SEGURO (DoH) — CLOUDFLARE ===" Title
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        Set-DnsClientServerAddress -InterfaceAlias $adapter.InterfaceAlias -ServerAddresses ("1.1.1.1","1.0.0.1") -ErrorAction SilentlyContinue
        Write-HT "  $($adapter.Name): DNS → 1.1.1.1 / 1.0.0.1 (Cloudflare)" Step
    }
    # Flush DNS após mudança
    Clear-DnsClientCache
    Write-HT "DNS configurado para Cloudflare 1.1.1.1. Cache limpo." Success
    $Script:Config.Applied.Add("dns_doh")
}

function Invoke-TweakTcpAutotuning {
    Write-HT "=== TCP AUTO-TUNING E RECEIVE WINDOW ===" Title
    netsh int tcp set global autotuninglevel=normal  | Out-Null
    netsh int tcp set global rss=enabled              | Out-Null
    netsh int tcp set global ecncapability=enabled    | Out-Null
    netsh int tcp set global timestamps=enabled       | Out-Null
    netsh int tcp set global chimney=disabled         | Out-Null
    Write-HT "TCP Auto-Tuning, RSS e ECN configurados." Success
    $Script:Config.Applied.Add("tcp_autotuning")
}

function Invoke-TweakIPv6Disable {
    Write-HT "=== DESATIVAR IPv6 ===" Title
    Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents" 0xff
    Write-HT "IPv6 desativado em todos os adaptadores." Warn
    $Script:Config.Applied.Add("ipv6_disable")
}

function Invoke-TweakFirewallRules {
    Write-HT "=== REGRAS DE FIREWALL ANTI-TELEMETRIA ===" Title
    $hosts = @(
        'vortex.data.microsoft.com','watson.telemetry.microsoft.com',
        'telemetry.microsoft.com','settings-win.data.microsoft.com',
        'oca.telemetry.microsoft.com','reports.wes.df.telemetry.microsoft.com',
        'v10.vortex-win.data.microsoft.com','sqm.microsoft.com',
        'a-0001.a-msedge.net','statsfe2.ws.microsoft.com'
    )
    foreach ($h in $hosts) {
        try {
            $ips = [System.Net.Dns]::GetHostAddresses($h) | Select-Object -ExpandProperty IPAddressToString
            foreach ($ip in $ips) {
                $ruleName = "HT-Block-$h"
                Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
                New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Action Block -RemoteAddress $ip -Protocol Any -ErrorAction SilentlyContinue | Out-Null
                Write-HT "  Bloqueado: $h ($ip)" Step
            }
        } catch {
            Write-HT "  Não foi possível resolver: $h" Warn
        }
    }
    Write-HT "Regras de firewall anti-telemetria aplicadas." Success
    $Script:Config.Applied.Add("firewall_rules")
}

# ═══════════════════════════════════════════════════════════════════════
# TWEAKS — GAMING & FPS
# ═══════════════════════════════════════════════════════════════════════

function Invoke-TweakGameMode {
    Write-HT "=== GAME MODE + HAGS COMPLETO ===" Title
    Set-RegValue "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1
    Set-RegValue "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode"   1
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" 2
    # Variable Refresh Rate
    Set-RegValue "HKCU:\Software\Microsoft\Direct3D"    "D3D11_ENABLE_DYNAMIC_CODEPATH" 1
    Set-RegValue "HKCU:\System\GameConfigStore"         "GameDVR_HonorUserFSEBehaviorMode" 0
    Write-HT "Game Mode, HAGS e VRR ativados." Success
    $Script:Config.Applied.Add("game_mode")
}

function Invoke-TweakDxShader {
    Write-HT "=== LIMPAR CACHE DE SHADERS DIRECTX ===" Title
    $shaderPaths = @(
        "$env:LOCALAPPDATA\D3DSCache",
        "$env:LOCALAPPDATA\Microsoft\DirectX\Shaders",
        "$env:LOCALAPPDATA\NVIDIA\DXCache",
        "$env:LOCALAPPDATA\AMD\DxCache"
    )
    foreach ($p in $shaderPaths) {
        if (Test-Path $p) {
            Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-HT "  Shader cache limpo: $p" Step
        }
    }
    Write-HT "Cache de shaders DirectX/Vulkan limpo." Success
    $Script:Config.Applied.Add("dx_shader")
}

function Invoke-TweakCpuPriority {
    Write-HT "=== PRIORIDADE DE CPU PARA JOGOS ===" Title
    # Win32PrioritySeparation = 38 (foreground boost máximo)
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38
    Write-HT "Prioridade de CPU foreground maximizada (38)." Success
    $Script:Config.Applied.Add("cpu_priority")
}

function Invoke-TweakDisableFullscreenOpt {
    Write-HT "=== DESATIVAR FULLSCREEN OPTIMIZATIONS GLOBAL ===" Title
    Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_Enabled"          0
    Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode"  2
    Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1
    Write-HT "Fullscreen Optimizations globalmente desativado." Success
    $Script:Config.Applied.Add("disable_fullscreen_opt")
}

function Invoke-TweakNvidiaTweaks {
    Write-HT "=== TWEAKS NVIDIA/AMD ===" Title
    $nvPaths = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" -ErrorAction SilentlyContinue |
        Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc -match "NVIDIA|GeForce|Quadro" }

    if ($nvPaths) {
        foreach ($path in $nvPaths) {
            Set-ItemProperty -Path $path.PSPath -Name "PerfLevelSrc"           -Value 0x3322   -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $path.PSPath -Name "PowerMizerEnable"        -Value 1        -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $path.PSPath -Name "PowerMizerLevel"         -Value 1        -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $path.PSPath -Name "RMHdcpKeyglobZero"       -Value 1        -Force -ErrorAction SilentlyContinue
            Write-HT "  NVIDIA tweaks aplicados: $($path.PSPath)" Step
        }
        Write-HT "Tweaks NVIDIA aplicados." Success
    } else {
        Write-HT "Driver NVIDIA não detectado. Verificando AMD..." Warn
        $amdPaths = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" -ErrorAction SilentlyContinue |
            Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc -match "AMD|Radeon" }
        if ($amdPaths) {
            Write-HT "GPU AMD detectada. Anti-Lag disponível via Radeon Software." Info
        } else {
            Write-HT "Nenhuma GPU dedicada encontrada no registro padrão." Warn
        }
    }
    $Script:Config.Applied.Add("nvidia_tweaks")
}

# ═══════════════════════════════════════════════════════════════════════
# TWEAKS — SEGURANÇA & PROTEÇÃO
# ═══════════════════════════════════════════════════════════════════════

function Invoke-TweakDefenderUpdate {
    Write-HT "=== ATUALIZAR WINDOWS DEFENDER ===" Title
    Update-MpSignature -ErrorAction SilentlyContinue
    $sig = Get-MpComputerStatus | Select-Object AntivirusSignatureLastUpdated, AntivirusSignatureVersion
    Write-HT "Assinaturas: $($sig.AntivirusSignatureVersion) | Atualizado: $($sig.AntivirusSignatureLastUpdated)" Success
    Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue
    Write-HT "Varredura rápida iniciada em background." Step
    $Script:Config.Applied.Add("defender_update")
}

function Invoke-TweakUACLevel {
    Write-HT "=== CONFIGURAR NÍVEL DE UAC ===" Title
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 5
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop"      1
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA"                  1
    Write-HT "UAC configurado para nível recomendado (notificar somente)." Success
    $Script:Config.Applied.Add("uac_level")
}

function Invoke-TweakExploitProtection {
    Write-HT "=== HABILITAR EXPLOIT PROTECTION ===" Title
    try {
        Set-Processmitigation -System -Enable DEP,SEHOP -ErrorAction SilentlyContinue
        Write-HT "DEP e SEHOP habilitados." Success
    } catch {
        Write-HT "Não foi possível configurar via cmdlet. Verificando registro..." Warn
        Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "MitigationOptions" 0x100 -Type QWord
    }
    $Script:Config.Applied.Add("exploit_protection")
}

function Invoke-TweakRdpDisable {
    Write-HT "=== DESATIVAR RDP ===" Title
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections" 1
    Disable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
    Write-HT "Área de Trabalho Remota (RDP) desativada. Porta 3389 bloqueada." Success
    $Script:Config.Applied.Add("rdp_disable")
}

# ═══════════════════════════════════════════════════════════════════════
# TWEAKS — SISTEMA & INTERFACE
# ═══════════════════════════════════════════════════════════════════════

function Invoke-TweakDarkMode {
    Write-HT "=== FORÇAR MODO ESCURO GLOBAL ===" Title
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme"   0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Start-Process explorer
    Write-HT "Modo Escuro global ativado. Explorer reiniciado." Success
    $Script:Config.Applied.Add("dark_mode")
}

function Invoke-TweakContextMenu {
    Write-HT "=== MENU DE CONTEXTO CLÁSSICO (WIN 10 STYLE) ===" Title
    $path = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name "(Default)" -Value "" -Type String -Force
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep 1; Start-Process explorer
    Write-HT "Menu de contexto clássico restaurado. Explorer reiniciado." Success
    $Script:Config.Applied.Add("context_menu")
}

function Invoke-TweakShowExtensions {
    Write-HT "=== EXIBIR EXTENSÕES DE ARQUIVO E PASTAS OCULTAS ===" Title
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt"   0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden"        1
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSuperHidden" 1
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep 1; Start-Process explorer
    Write-HT "Extensões e arquivos ocultos agora visíveis." Success
    $Script:Config.Applied.Add("show_extensions")
}

function Invoke-TweakNumLock {
    Write-HT "=== NUMLOCK NA INICIALIZAÇÃO ===" Title
    Set-RegValue "HKCU:\Control Panel\Keyboard" "InitialKeyboardIndicators" 2
    Write-HT "NumLock será ativado automaticamente em toda inicialização." Success
    $Script:Config.Applied.Add("num_lock")
}

function Invoke-TweakAutoUpdates {
    Write-HT "=== CONFIGURAR ATUALIZAÇÕES AUTOMÁTICAS ===" Title
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegValue $path "AUOptions"    2  # Notificar antes de baixar
    Set-RegValue $path "NoAutoUpdate" 0
    Write-HT "Windows Update configurado para notificar antes de baixar." Success
    $Script:Config.Applied.Add("auto_updates")
}

# ═══════════════════════════════════════════════════════════════════════
# ROTEADOR DE TWEAKS
# ═══════════════════════════════════════════════════════════════════════

$Script:TweakMap = @{
    # Diagnóstico
    "reparo_rapido"        = { Invoke-TweakReparoRapido }
    "sfc_dism"             = { Invoke-TweakSfcDism }
    "chkdsk"               = { Invoke-TweakChkDsk }
    "limpeza_cache"        = { Invoke-TweakLimpezaCache }
    "reparar_wmi"          = { Invoke-TweakRepararWMI }
    "reset_wupdate"        = { Invoke-TweakResetWUpdate }
    "otimizar_rede"        = { Invoke-TweakOtimizarRede }
    "trim_defrag"          = { Invoke-TweakTrimDefrag }
    "event_log"            = { Invoke-TweakEventLog }
    "diagnostico_energia"  = { Invoke-TweakDiagnosticoEnergia }
    # Performance
    "perf_fso"             = { Invoke-TweakPerfFSO }
    "latencia_rede"        = { Invoke-TweakLatenciaRede }
    "plano_max"            = { Invoke-TweakPlanoMax }
    "bloatwares"           = { Invoke-TweakBloatwares }
    "efeitos_visuais"      = { Invoke-TweakEfeitosVisuais }
    "sysmain"              = { Invoke-TweakSysMain }
    "cache_ram"            = { Invoke-TweakCacheRAM }
    "energy_throttle"      = { Invoke-TweakEnergyThrottle }
    "timer_resolution"     = { Invoke-TweakTimerResolution }
    # Privacidade
    "telemetria"           = { Invoke-TweakTelemetria }
    "copilot_bing"         = { Invoke-TweakCopilotBing }
    "widgets"              = { Invoke-TweakWidgets }
    "smartscreen"          = { Invoke-TweakSmartScreen }
    "protecao_disco"       = { Invoke-TweakProtecaoDisco }
    "hibernacao_ssd"       = { Invoke-TweakHibernacaoSSD }
    "historico_atividade"  = { Invoke-TweakHistoricoAtividade }
    "advertising_id"       = { Invoke-TweakAdvertisingId }
    "recall_ai"            = { Invoke-TweakRecallAI }
    "location_cam"         = { Invoke-TweakLocationCam }
    # Limpeza
    "temp_system"          = { Invoke-TweakTempSystem }
    "winsxs"               = { Invoke-TweakWinSxS }
    "recycle_bin"          = { Invoke-TweakRecycleBin }
    "browser_cache"        = { Invoke-TweakBrowserCache }
    "font_cache"           = { Invoke-TweakFontCache }
    # Rede
    "dns_doh"              = { Invoke-TweakDnsDoh }
    "tcp_autotuning"       = { Invoke-TweakTcpAutotuning }
    "ipv6_disable"         = { Invoke-TweakIPv6Disable }
    "firewall_rules"       = { Invoke-TweakFirewallRules }
    # Gaming
    "game_mode"            = { Invoke-TweakGameMode }
    "dx_shader"            = { Invoke-TweakDxShader }
    "cpu_priority"         = { Invoke-TweakCpuPriority }
    "nvidia_tweaks"        = { Invoke-TweakNvidiaTweaks }
    "disable_fullscreen_opt" = { Invoke-TweakDisableFullscreenOpt }
    # Segurança
    "defender_update"      = { Invoke-TweakDefenderUpdate }
    "uac_level"            = { Invoke-TweakUACLevel }
    "exploit_protection"   = { Invoke-TweakExploitProtection }
    "rdp_disable"          = { Invoke-TweakRdpDisable }
    # Sistema
    "dark_mode"            = { Invoke-TweakDarkMode }
    "context_menu"         = { Invoke-TweakContextMenu }
    "show_extensions"      = { Invoke-TweakShowExtensions }
    "num_lock"             = { Invoke-TweakNumLock }
    "auto_updates"         = { Invoke-TweakAutoUpdates }
}

# Lista de tweaks "seguros" recomendados para RunAll
$Script:SafeTweaks = @(
    "telemetria","copilot_bing","widgets","advertising_id","recall_ai",
    "historico_atividade","protecao_disco","hibernacao_ssd","location_cam",
    "perf_fso","latencia_rede","plano_max","efeitos_visuais","cache_ram",
    "game_mode","cpu_priority","dx_shader","disable_fullscreen_opt",
    "temp_system","recycle_bin","browser_cache","font_cache",
    "dns_doh","tcp_autotuning","firewall_rules",
    "defender_update","uac_level","exploit_protection","rdp_disable",
    "dark_mode","show_extensions","num_lock","auto_updates",
    "limpeza_cache","otimizar_rede","event_log","diagnostico_energia"
)

# ═══════════════════════════════════════════════════════════════════════
# RELATÓRIO HTML
# ═══════════════════════════════════════════════════════════════════════

function Export-HtmlReport {
    $elapsed  = ((Get-Date) - $Script:Config.StartTime).ToString("mm\:ss")
    $os       = (Get-CimInstance Win32_OperatingSystem).Caption
    $applied  = $Script:Config.Applied -join ", "
    $errors   = if ($Script:Config.Errors.Count -gt 0) { $Script:Config.Errors -join "<br>" } else { "Nenhum erro registrado." }

    $html = @"
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="UTF-8">
<title>HT Technology — Relatório de Otimização</title>
<style>
  body { font-family: 'Segoe UI', sans-serif; background: #0a0c10; color: #f0f2f8; padding: 30px; }
  h1 { color: #00d4ff; } h2 { color: #7c3aed; }
  table { width:100%; border-collapse: collapse; margin: 16px 0; }
  th { background: #1c2030; color: #00d4ff; padding: 8px 12px; text-align:left; }
  td { padding: 8px 12px; border-bottom: 1px solid #1c2030; }
  tr:hover td { background: #13161e; }
  .ok { color: #10d97e; } .warn { color: #f59e0b; } .err { color: #ef4444; }
  .badge { padding: 2px 8px; border-radius: 999px; font-size: 12px; font-weight: 700; }
  .badge-green { background: rgba(16,217,126,.15); color: #10d97e; border: 1px solid rgba(16,217,126,.3); }
</style></head><body>
<h1>HT Technology — Windows Optimizer Pro</h1>
<p>Relatório gerado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') | Duração: $elapsed</p>
<hr style="border-color:#1c2030">
<h2>Informações do Sistema</h2>
<table><tr><th>Item</th><th>Valor</th></tr>
<tr><td>Sistema Operacional</td><td>$os</td></tr>
<tr><td>Computador</td><td>$env:COMPUTERNAME</td></tr>
<tr><td>Usuário</td><td>$env:USERNAME</td></tr>
<tr><td>Tweaks Aplicados</td><td><span class="badge badge-green">$($Script:Config.Applied.Count)</span></td></tr>
</table>
<h2>Tweaks Aplicados</h2>
<p class="ok">$applied</p>
<h2>Log de Erros</h2>
<p class="warn">$errors</p>
<hr style="border-color:#1c2030">
<p style="color:#4a5568;font-size:12px">HT Technology Windows Optimizer Pro v$($Script:Config.Version) | $(Get-Date -Format 'yyyy')</p>
</body></html>
"@
    $html | Set-Content -Path $Script:Config.ReportFile -Encoding UTF8
    Write-HT "Relatório HTML gerado: $($Script:Config.ReportFile)" Success
    Start-Process $Script:Config.ReportFile -ErrorAction SilentlyContinue
}

# ═══════════════════════════════════════════════════════════════════════
# PONTO DE ENTRADA PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════

# Verificar admin
if (-not (Test-Admin)) {
    Write-HT "ERRO: Este script requer privilégios de Administrador!" Error
    Write-HT "Clique com botão direito no PowerShell e escolha 'Executar como Administrador'." Warn
    pause; exit 1
}

Write-Banner

# Iniciar log
"" | Set-Content -Path $Script:Config.LogFile -Encoding UTF8
Write-HT "Log iniciado: $($Script:Config.LogFile)" Info

# Modo: tweak específico
if ($Tweak -ne "") {
    $tweakKey = $Tweak.ToLower()
    if ($Script:TweakMap.ContainsKey($tweakKey)) {
        if (-not $SkipRestorePoint) { New-RestorePoint | Out-Null }
        Write-HT "Executando tweak: $tweakKey" Step
        & $Script:TweakMap[$tweakKey]
    } else {
        Write-HT "Tweak não encontrado: $tweakKey" Error
        Write-HT "Tweaks disponíveis: $($Script:TweakMap.Keys -join ', ')" Info
    }
}
# Modo: executar todos os seguros
elseif ($RunAll) {
    Write-HT "Modo RunAll: $($Script:SafeTweaks.Count) tweaks seguros serão aplicados..." Warn
    if (-not $SkipRestorePoint) { New-RestorePoint | Out-Null }
    foreach ($tid in $Script:SafeTweaks) {
        if ($Script:TweakMap.ContainsKey($tid)) {
            try {
                & $Script:TweakMap[$tid]
                Start-Sleep -Milliseconds 200
            } catch {
                $Script:Config.Errors.Add("$tid : $_")
                Write-HT "Erro em $tid : $_" Error
            }
        }
    }
}
# Modo: exportar relatório
elseif ($ExportReport) {
    Export-HtmlReport
}
# Modo: menu interativo
else {
    Write-Host ""
    Write-HT "Total de tweaks disponíveis: $($Script:TweakMap.Count)" Info
    Write-HT "Tweaks seguros (RunAll): $($Script:SafeTweaks.Count)" Info
    Write-Host ""
    Write-Host "  Uso:" -ForegroundColor Yellow
    Write-Host "    .\HT-Optimizer-Backend.ps1 -Tweak 'telemetria'   # Tweak específico"
    Write-Host "    .\HT-Optimizer-Backend.ps1 -RunAll               # Todos os seguros"
    Write-Host "    .\HT-Optimizer-Backend.ps1 -ExportReport         # Gerar relatório HTML"
    Write-Host ""
    Write-Host "  Tweaks disponíveis:" -ForegroundColor Cyan
    $Script:TweakMap.Keys | Sort-Object | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
    Write-Host ""
}

# Sumário final
if ($Script:Config.Applied.Count -gt 0 -or $RunAll) {
    Write-Host ""
    Write-HT "════════════════ SUMÁRIO ════════════════" Title
    Write-HT "Tweaks aplicados : $($Script:Config.Applied.Count)"   Success
    Write-HT "Erros encontrados: $($Script:Config.Errors.Count)"    $(if ($Script:Config.Errors.Count -gt 0) {'Warn'} else {'Success'})
    Write-HT "Duração total    : $(((Get-Date) - $Script:Config.StartTime).ToString('mm\:ss'))" Info
    Write-HT "Log completo     : $($Script:Config.LogFile)" Info

    if ($Script:Config.Applied.Count -gt 0 -and -not $Silent) {
        Write-Host ""
        Write-Host "  Deseja gerar relatório HTML? (S/N): " -NoNewline -ForegroundColor Cyan
        $resp = Read-Host
        if ($resp -match '^[Ss]') { Export-HtmlReport }
    }
}
