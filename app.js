/**
 * HT Technology — Windows Optimizer Pro  |  app.js  |  v2.2
 * v2.2: Perfis de Otimização, novos tweaks Win11 2026, busca, histórico localStorage
 * Security: todo texto inserido via textContent (XSS-safe)
 * TODO(security): Se implantado como web app, adicionar CSP nonce
 */

'use strict';

/* ════════════════════════════════════════════════
   ESTADO GLOBAL
════════════════════════════════════════════════ */
const State = {
  theme:    localStorage.getItem('ht-theme') || 'dark',
  selected: new Set(),
  applied:  new Set(),
  running:  null,
  pending:  null,
};

/* ════════════════════════════════════════════════
   REGISTRO DE TWEAKS — id → label + script PS
════════════════════════════════════════════════ */
const TWEAKS = {
  // ── Diagnóstico
  reparo_rapido:       { label:'Reparo Rápido Completo',            safe:true,  ps:`sfc /scannow; DISM /Online /Cleanup-Image /RestoreHealth` },
  sfc_dism:            { label:'SFC / DISM Completo',               safe:true,  ps:`sfc /scannow; DISM /Online /Cleanup-Image /RestoreHealth` },
  chkdsk:              { label:'Corrigir Erros de Disco (ChkDsk)',   safe:false, ps:`echo y | chkdsk C: /f /r /x` },
  limpeza_cache:       { label:'Limpeza Total (Cache e VSS)',        safe:true,  ps:`Remove-Item "$env:TEMP\\*" -Recurse -Force -EA SilentlyContinue; Remove-Item "C:\\Windows\\Temp\\*" -Recurse -Force -EA SilentlyContinue; Write-Host "[OK] Cache limpo" -ForegroundColor Green` },
  reparar_wmi:         { label:'Reparar Repositório WMI',            safe:false, ps:`Stop-Service winmgmt -Force; Start-Process winmgmt -ArgumentList "/resetrepository" -Wait; Start-Service winmgmt` },
  reset_wupdate:       { label:'Reset Estrutural Windows Update',   safe:false, ps:`Stop-Service wuauserv,bits -Force -EA SilentlyContinue; Remove-Item "C:\\Windows\\SoftwareDistribution" -Recurse -Force -EA SilentlyContinue; Start-Service bits,wuauserv` },
  otimizar_rede:       { label:'Otimização e Reset de Rede',        safe:true,  ps:`netsh int ip reset; netsh winsock reset; ipconfig /flushdns; ipconfig /release; ipconfig /renew` },
  trim_defrag:         { label:'Otimizar Armazenamento (TRIM)',      safe:true,  ps:`Optimize-Volume -DriveLetter C -Verbose` },
  limpar_drivers:      { label:'Limpar Drivers Antigos',             safe:false, ps:`pnputil /enum-drivers` },
  diagnostico_energia: { label:'Diagnóstico de Energia/Bateria',    safe:true,  ps:`powercfg /batteryreport /output "$env:USERPROFILE\\Desktop\\battery-report.html"; powercfg /energy /output "$env:USERPROFILE\\Desktop\\energy-report.html"` },
  event_log:           { label:'Limpar Log de Eventos',              safe:true,  ps:`Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log }` },
  prefetch:            { label:'Limpar Prefetch e Superfetch',       safe:true,  ps:`Remove-Item "C:\\Windows\\Prefetch\\*" -Force -EA SilentlyContinue` },
  // ── Performance
  perf_fso:            { label:'Tweaks de Performance e FSO',        safe:true,  ps:`powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; powercfg -setactive SCHEME_MIN; Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\GraphicsDrivers" -Name HwSchMode -Value 2 -Force` },
  latencia_rede:       { label:'Otimizar Latência e Rede (Jogos)',   safe:true,  ps:`Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile" -Name NetworkThrottlingIndex -Value 0xffffffff -Force` },
  plano_max:           { label:'Injetar Plano Desempenho Máximo',    safe:true,  ps:`powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61; powercfg -setactive SCHEME_MIN; Write-Host "[OK] Ultimate Performance ativado" -ForegroundColor Green` },
  bloatwares:          { label:'Remover Bloatwares (Apps Inúteis)',   safe:false, ps:`Get-AppxPackage | Where-Object {$_.Name -match "BingNews|Xbox|Solitaire|Disney|Teams|ZuneMusic|ZuneVideo"} | Remove-AppxPackage -EA SilentlyContinue` },
  inicializacao:       { label:'Mitigar Apps de Inicialização',      safe:true,  ps:`Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Format-Table` },
  config_maquina:      { label:'Configuração da Máquina (msconfig)', safe:false, ps:`$c=(Get-CimInstance Win32_Processor).NumberOfLogicalProcessors; bcdedit /set numproc $c; bcdedit /set useplatformtick yes` },
  efeitos_visuais:     { label:'Opções de Desempenho Visual',        safe:true,  ps:`Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects" -Name VisualFXSetting -Value 2 -Force` },
  sysmain:             { label:'Desativar SysMain (Superfetch)',      safe:false, ps:`Stop-Service SysMain -Force; Set-Service SysMain -StartupType Disabled; Write-Host "[OK] SysMain desativado" -ForegroundColor Green` },
  cache_ram:           { label:'Otimizar Cache da Memória RAM',       safe:true,  ps:`Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management" -Name LargeSystemCache -Value 0 -Force` },
  energy_throttle:     { label:'Desativar Energy Throttling Global',  safe:false, ps:`Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power\\PowerThrottling" -Name PowerThrottlingOff -Value 1 -Force` },
  irq_affinity:        { label:'Afinidade de IRQ e MSI Mode',         safe:false, ps:`Write-Host "[INFO] Configure MSI Mode via Device Manager > Properties > Resources" -ForegroundColor Cyan` },
  timer_resolution:    { label:'Timer Resolution Global (0.5ms)',     safe:false, ps:`bcdedit /set useplatformtick yes; bcdedit /set disabledynamictick yes; Write-Host "[OK] Timer resolution configurado. Reinicie." -ForegroundColor Green` },
  // ── Privacidade
  telemetria:          { label:'Desativar Telemetria Completa',       safe:true,  ps:`Stop-Service DiagTrack,dmwappushservice -Force -EA SilentlyContinue; Set-Service DiagTrack,dmwappushservice -StartupType Disabled -EA SilentlyContinue; Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection" -Name AllowTelemetry -Value 0 -Force` },
  experiencia_usuario: { label:'Desativar Experiência e Promos',      safe:true,  ps:`Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager" -Name SilentInstalledAppsEnabled -Value 0 -Force; Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager" -Name SystemPaneSuggestionsEnabled -Value 0 -Force` },
  copilot_bing:        { label:'Remover Copilot e Buscas no Bing',    safe:true,  ps:`Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Search" -Name BingSearchEnabled -Value 0 -Force; Get-AppxPackage -Name "Microsoft.Copilot" | Remove-AppxPackage -EA SilentlyContinue` },
  widgets:             { label:'Remover Widgets e Clima',             safe:true,  ps:`Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name TaskbarDa -Value 0 -Force; Get-AppxPackage "MicrosoftWindows.Client.WebExperience" | Remove-AppxPackage -EA SilentlyContinue` },
  smartscreen:         { label:'Desativar SmartScreen Local',         safe:false, ps:`Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System" -Name EnableSmartScreen -Value 0 -Force` },
  protecao_disco:      { label:'Ativar Proteção do Disco C:',         safe:true,  ps:`Enable-ComputerRestore -Drive "C:\\" -EA SilentlyContinue; Write-Host "[OK] System Protection ativado no C:" -ForegroundColor Green` },
  restauracao_sistema: { label:'Abrir Restauração do Sistema',        safe:true,  ps:`Start-Process rstrui.exe` },
  hibernacao_ssd:      { label:'Desativar Hibernação (Liberar SSD)',  safe:true,  ps:`powercfg -h off; Write-Host "[OK] Hibernação desativada. hiberfil.sys removido." -ForegroundColor Green` },
  historico_atividade: { label:'Bloquear Histórico de Atividades',    safe:true,  ps:`Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System" -Name EnableActivityFeed -Value 0 -Force; Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System" -Name PublishUserActivities -Value 0 -Force` },
  advertising_id:      { label:'Desativar ID de Anúncios e Técnico',  safe:true,  ps:`Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\AdvertisingInfo" -Name Enabled -Value 0 -Force` },
  recall_ai:           { label:'Desativar Windows Recall e AI',       safe:true,  ps:`$p="HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsAI"; if(!(Test-Path $p)){New-Item $p -Force|Out-Null}; Set-ItemProperty $p -Name DisableAIDataAnalysis -Value 1 -Force; Set-ItemProperty $p -Name AllowRecallEnablement -Value 0 -Force` },
  location_cam:        { label:'Bloquear Localização, Câmera e Mic',  safe:true,  ps:`Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\LocationAndSensors" -Name DisableLocation -Value 1 -Force; Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\AppPrivacy" -Name LetAppsAccessCamera -Value 2 -Force` },
  // ── Limpeza
  temp_system:         { label:'Limpeza Profunda Arquivos Temporários',safe:true, ps:`$paths=@("$env:TEMP","C:\\Windows\\Temp","C:\\Windows\\SoftwareDistribution\\Download"); foreach($p in $paths){if(Test-Path $p){Remove-Item "$p\\*" -Recurse -Force -EA SilentlyContinue; Write-Host "[LIMPO] $p" -ForegroundColor Yellow}}` },
  winsxs:              { label:'Compactar WinSxS e ComponentStore',   safe:true,  ps:`DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase` },
  recycle_bin:         { label:'Esvaziar Lixeira e Thumbnails',       safe:true,  ps:`Clear-RecycleBin -Force -EA SilentlyContinue; Write-Host "[OK] Lixeira esvaziada." -ForegroundColor Green` },
  browser_cache:       { label:'Limpar Cache de Navegadores',         safe:true,  ps:`$c=@("$env:LOCALAPPDATA\\Google\\Chrome\\User Data\\Default\\Cache","$env:LOCALAPPDATA\\Microsoft\\Edge\\User Data\\Default\\Cache"); foreach($b in $c){if(Test-Path $b){Remove-Item "$b\\*" -Recurse -Force -EA SilentlyContinue; Write-Host "[LIMPO] $b" -ForegroundColor Yellow}}` },
  update_cache:        { label:'Limpar Cache do Windows Update',      safe:true,  ps:`Stop-Service wuauserv -Force; Remove-Item "C:\\Windows\\SoftwareDistribution\\Download\\*" -Recurse -Force -EA SilentlyContinue; Start-Service wuauserv` },
  font_cache:          { label:'Reconstruir Cache de Fontes',         safe:true,  ps:`Stop-Service FontCache -Force -EA SilentlyContinue; Remove-Item "C:\\Windows\\ServiceProfiles\\LocalService\\AppData\\Local\\FontCache*" -Force -EA SilentlyContinue; Start-Service FontCache -EA SilentlyContinue` },
  // ── Rede & DNS
  dns_doh:             { label:'DNS Seguro (DoH) - Cloudflare/Google', safe:true, ps:`Set-DnsClientServerAddress -InterfaceAlias (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1 -ExpandProperty InterfaceAlias) -ServerAddresses ("1.1.1.1","1.0.0.1"); Clear-DnsClientCache; Write-Host "[OK] DNS Cloudflare configurado." -ForegroundColor Green` },
  tcp_autotuning:      { label:'TCP Auto-Tuning e Receive Window',    safe:true,  ps:`netsh int tcp set global autotuninglevel=normal; netsh int tcp set global rss=enabled; netsh int tcp set global ecncapability=enabled` },
  ipv6_disable:        { label:'Desativar IPv6 (Apenas IPv4)',         safe:false, ps:`Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -EA SilentlyContinue; Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters" -Name DisabledComponents -Value 0xff -Force` },
  network_adapter:     { label:'Tweaks Avançados de Adaptador de Rede',safe:false,ps:`$a=(Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1); Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword "InterruptModeration" -RegistryValue 0 -EA SilentlyContinue` },
  firewall_rules:      { label:'Regras de Firewall Anti-Telemetria',   safe:true, ps:`$hosts=@("vortex.data.microsoft.com","watson.telemetry.microsoft.com","telemetry.microsoft.com"); foreach($h in $hosts){try{$ip=[System.Net.Dns]::GetHostAddresses($h)|Select-Object -First 1 -ExpandProperty IPAddressToString; New-NetFirewallRule -DisplayName "HT-Block-$h" -Direction Outbound -Action Block -RemoteAddress $ip -Protocol Any -EA SilentlyContinue; Write-Host "[BLOQUEADO] $h ($ip)" -ForegroundColor Yellow}catch{}}` },
  // ── Gaming
  game_mode:           { label:'Game Mode + HAGS Completo',           safe:true,  ps:`Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\GameBar" -Name AutoGameModeEnabled -Value 1 -Force; Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\GraphicsDrivers" -Name HwSchMode -Value 2 -Force; Write-Host "[OK] Game Mode e HAGS ativados." -ForegroundColor Green` },
  dx_shader:           { label:'Limpar Cache de Shaders DirectX',      safe:true,  ps:`Remove-Item "$env:LOCALAPPDATA\\D3DSCache\\*" -Recurse -Force -EA SilentlyContinue; Write-Host "[OK] Shader cache limpo." -ForegroundColor Green` },
  xbox_services:       { label:'Remover Serviços Xbox Desnecessários', safe:false, ps:`@("Microsoft.Xbox.TCUI","Microsoft.XboxApp","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay","Microsoft.XboxIdentityProvider") | ForEach-Object { Get-AppxPackage -Name $_ | Remove-AppxPackage -EA SilentlyContinue; Write-Host "[REMOVIDO] $_" -ForegroundColor Yellow }` },
  nvidia_tweaks:       { label:'Tweaks de Registro NVIDIA/AMD',        safe:false, ps:`$p="HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}\\0000"; if(Test-Path $p){Set-ItemProperty $p -Name PerfLevelSrc -Value 0x3322 -Force; Write-Host "[OK] NVIDIA tweak aplicado." -ForegroundColor Green} else {Write-Host "[INFO] NVIDIA não detectado no caminho padrão." -ForegroundColor Cyan}` },
  cpu_priority:        { label:'Prioridade de CPU para Jogos',         safe:true,  ps:`Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\PriorityControl" -Name Win32PrioritySeparation -Value 38 -Force; Write-Host "[OK] CPU foreground priority maximizada." -ForegroundColor Green` },
  disable_fullscreen_opt:{ label:'Desativar Fullscreen Optimizations', safe:true,  ps:`Set-ItemProperty -Path "HKCU:\\System\\GameConfigStore" -Name GameDVR_Enabled -Value 0 -Force; Set-ItemProperty -Path "HKCU:\\System\\GameConfigStore" -Name GameDVR_FSEBehaviorMode -Value 2 -Force` },
  // ── Segurança
  defender_update:     { label:'Atualizar Definições do Defender',    safe:true,  ps:`Update-MpSignature; Start-MpScan -ScanType QuickScan; Write-Host "[OK] Defender atualizado e varredura iniciada." -ForegroundColor Green` },
  uac_level:           { label:'Configurar Nível de UAC',             safe:true,  ps:`Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System" -Name ConsentPromptBehaviorAdmin -Value 5 -Force; Write-Host "[OK] UAC configurado para nível recomendado." -ForegroundColor Green` },
  exploit_protection:  { label:'Habilitar Exploit Protection',        safe:true,  ps:`Set-Processmitigation -System -Enable DEP,SEHOP -EA SilentlyContinue; Write-Host "[OK] DEP e SEHOP habilitados." -ForegroundColor Green` },
  rdp_disable:         { label:'Desativar RDP',                       safe:true,  ps:`Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server" -Name fDenyTSConnections -Value 1 -Force; Disable-NetFirewallRule -DisplayGroup "Remote Desktop" -EA SilentlyContinue; Write-Host "[OK] RDP desativado." -ForegroundColor Green` },
  // ── Sistema
  dark_mode:           { label:'Forçar Modo Escuro Global',           safe:true,  ps:`Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize" -Name AppsUseLightTheme -Value 0 -Force; Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize" -Name SystemUsesLightTheme -Value 0 -Force; Stop-Process -Name explorer -Force; Start-Process explorer` },
  taskbar_clean:       { label:'Limpar e Centralizar Barra de Tarefas',safe:true, ps:`Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name TaskbarMn -Value 0 -Force; Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name ShowTaskViewButton -Value 0 -Force; Stop-Process -Name explorer -Force; Start-Process explorer` },
  context_menu:        { label:'Menu de Contexto Clássico (Win 10)',  safe:true,  ps:`$p="HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\\InprocServer32"; New-Item -Path $p -Force | Set-ItemProperty -Name "(Default)" -Value "" -Force; Stop-Process -Name explorer -Force; Start-Process explorer` },
  num_lock:            { label:'NumLock Ativo na Inicialização',       safe:true,  ps:`Set-ItemProperty -Path "HKCU:\\Control Panel\\Keyboard" -Name InitialKeyboardIndicators -Value 2 -Force; Write-Host "[OK] NumLock ativado no boot." -ForegroundColor Green` },
  show_extensions:     { label:'Exibir Extensões de Arquivo e Ocultas',safe:true, ps:`Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name HideFileExt -Value 0 -Force; Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced" -Name Hidden -Value 1 -Force; Stop-Process -Name explorer -Force; Start-Process explorer` },
  auto_updates:        { label:'Configurar Atualizações Automáticas', safe:true,  ps:`$p="HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU"; if(!(Test-Path $p)){New-Item $p -Force|Out-Null}; Set-ItemProperty $p -Name AUOptions -Value 2 -Force; Write-Host "[OK] Windows Update: notificar antes de baixar." -ForegroundColor Green` },
  // ── Perfis / Novos Tweaks Windows 11 2026 (v2.2)
  vbs_disable:         { label:'Desativar VBS / Memory Integrity',     safe:false, ps:`$r="HKLM:\\SYSTEM\\CurrentControlSet\\Control\\DeviceGuard"; Set-ItemProperty $r -Name EnableVirtualizationBasedSecurity -Value 0 -Force -EA SilentlyContinue; Set-ItemProperty $r -Name RequirePlatformSecurityFeatures -Value 0 -Force -EA SilentlyContinue; Write-Host "[OK] VBS desativado. Reinicie para aplicar." -ForegroundColor Green` },
  low_latency_profile: { label:'Low Latency Profile (Win11 2026)',      safe:true,  ps:`Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Executive" -Name AdditionalCriticalWorkerThreads -Value 4 -Force -EA SilentlyContinue; Write-Host "[OK] Low Latency Profile aplicado (fallback sem ViVeTool)." -ForegroundColor Cyan` },
  winget_update:       { label:'Atualizar Todos Apps via Winget',       safe:true,  ps:`Write-Host "[INFO] Atualizando todos os apps via winget..." -ForegroundColor Cyan; winget upgrade --all --silent --accept-source-agreements --accept-package-agreements; Write-Host "[OK] Atualização via winget concluída!" -ForegroundColor Green` },
  copilot_sidebar:     { label:'Desativar Copilot Sidebar (2026)',      safe:true,  ps:`$p="HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced"; Set-ItemProperty $p -Name ShowCopilotButton -Value 0 -Force -EA SilentlyContinue; $p2="HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsCopilot"; if(!(Test-Path $p2)){New-Item $p2 -Force|Out-Null}; Set-ItemProperty $p2 -Name TurnOffWindowsCopilot -Value 1 -Force; Write-Host "[OK] Copilot Sidebar desativado." -ForegroundColor Green` },
  cpu_boost:           { label:'CPU Boost Mode Agressivo',              safe:false, ps:`powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2; powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2; powercfg -setactive SCHEME_CURRENT; Write-Host "[OK] CPU Boost Aggressive ativo." -ForegroundColor Green` },
  pagefile_auto:       { label:'Otimizar PageFile Automaticamente',     safe:true,  ps:`$cs=Get-WmiObject Win32_ComputerSystem; $cs.AutomaticManagedPagefile=$true; $cs.Put(); Write-Host "[OK] PageFile configurado como Gerenciado Automaticamente." -ForegroundColor Green` },
};

/* ════════════════════════════════════════════════
   PERFIS DE OTIMIZAÇÃO (v2.2)
════════════════════════════════════════════════ */
const PROFILES = {
  gaming: {
    label: 'Gaming Pro',
    tweaks: ['game_mode','perf_fso','timer_resolution','cpu_priority','vbs_disable','nvidia_tweaks','dx_shader','energy_throttle','low_latency_profile','plano_max','disable_fullscreen_opt','latencia_rede'],
  },
  office: {
    label: 'Office & Produtividade',
    tweaks: ['telemetria','recall_ai','bloatwares','inicializacao','cache_ram','efeitos_visuais','dark_mode','taskbar_clean','show_extensions','advertising_id'],
  },
  server: {
    label: 'Servidor & Headless',
    tweaks: ['plano_max','sysmain','hibernacao_ssd','auto_updates','efeitos_visuais','rdp_disable','energy_throttle','tcp_autotuning'],
  },
};

/* ════════════════════════════════════════════════
   HISTÓRICO (v2.2) — localStorage
════════════════════════════════════════════════ */
function saveHistory(id, label) {
  try {
    const hist = JSON.parse(localStorage.getItem('ht-history') || '[]');
    hist.unshift({ id, label, ts: new Date().toISOString() });
    if (hist.length > 50) hist.pop();
    localStorage.setItem('ht-history', JSON.stringify(hist));
  } catch(e) { /* silently fail */ }
}

function loadHistory() {
  try {
    return JSON.parse(localStorage.getItem('ht-history') || '[]');
  } catch(e) { return []; }
}


/* ════════════════════════════════════════════════
   HELPERS DE DOM
════════════════════════════════════════════════ */
const $ = id => document.getElementById(id);
const $$ = sel => [...document.querySelectorAll(sel)];

/* ════════════════════════════════════════════════
   TEMA CLARO / ESCURO
════════════════════════════════════════════════ */
function setTheme(t) {
  State.theme = t;
  // Aplica o atributo data-theme no <html> — o CSS cuida dos ícones e cores
  document.documentElement.setAttribute('data-theme', t);
  localStorage.setItem('ht-theme', t);

  const btn = $('btnTheme');
  if (!btn) return;

  if (t === 'dark') {
    btn.title = 'Mudar para Tema Claro ☀️';
    btn.setAttribute('aria-label', 'Ativar tema claro');
  } else {
    btn.title = 'Mudar para Tema Escuro 🌙';
    btn.setAttribute('aria-label', 'Ativar tema escuro');
  }
}

/* ════════════════════════════════════════════════
   TROCA DE ABAS  ← ponto mais crítico
════════════════════════════════════════════════ */
function switchTab(tabId) {
  // Desativa todas as abas
  $$('.nav-tab').forEach(t => t.classList.remove('active'));
  // Oculta todos os painéis
  $$('.tab-panel').forEach(p => p.classList.remove('active'));
  // Ativa a aba selecionada
  const tab = $('tab-' + tabId);
  if (tab) tab.classList.add('active');
  // Exibe o painel correspondente
  const panel = $('panel-' + tabId);
  if (panel) panel.classList.add('active');
  // Log
  log('Painel: ' + tabId, 'info');
}

/* ════════════════════════════════════════════════
   TERMINAL
════════════════════════════════════════════════ */
function log(msg, type = 'default') {
  const terminal = $('terminalLog');
  if (!terminal) return;
  const line = document.createElement('div');
  line.className = 'term-line';
  const prompt = document.createElement('span');
  prompt.className = 'term-prompt';
  prompt.textContent = '❯';
  const text = document.createElement('span');
  text.className = 'term-text ' + type;
  text.textContent = msg;   // ← textContent: XSS-safe
  line.appendChild(prompt);
  line.appendChild(text);
  terminal.appendChild(line);
  terminal.scrollTop = terminal.scrollHeight;
}

/* ════════════════════════════════════════════════
   TOASTS
════════════════════════════════════════════════ */
function toast(title, msg, type = 'info', ms = 4000) {
  const container = $('toastContainer');
  if (!container) return;

  const t = document.createElement('div');
  t.className = 'toast ' + type;

  const iconMap = { success: '✓', error: '✕', info: 'ℹ', warn: '⚠' };
  const iconBox = document.createElement('div');
  iconBox.className = 'toast-icon';
  iconBox.textContent = iconMap[type] || 'ℹ';

  const body = document.createElement('div');
  body.className = 'toast-body';
  const ttl = document.createElement('div');
  ttl.className = 'toast-title';
  ttl.textContent = title;
  const dsc = document.createElement('div');
  dsc.className = 'toast-msg';
  dsc.textContent = msg;
  body.appendChild(ttl);
  body.appendChild(dsc);

  const cls = document.createElement('button');
  cls.className = 'toast-close';
  cls.textContent = '×';
  cls.setAttribute('aria-label', 'Fechar');
  cls.onclick = () => dismissToast(t);

  t.appendChild(iconBox);
  t.appendChild(body);
  t.appendChild(cls);
  container.appendChild(t);
  if (ms > 0) setTimeout(() => dismissToast(t), ms);
}

function dismissToast(t) {
  t.classList.add('fade-out');
  setTimeout(() => t.remove(), 300);
}

/* ════════════════════════════════════════════════
   MODAL
════════════════════════════════════════════════ */
function showModal(icon, title, body, onConfirm) {
  $('modalIcon').textContent   = icon;
  $('modalTitle').textContent  = title;
  $('modalBody').textContent   = body;
  State.pending = onConfirm;
  $('modalOverlay').hidden = false;
  $('modalConfirm').focus();
}

function closeModal() {
  $('modalOverlay').hidden = true;
  State.pending = null;
}

/* ════════════════════════════════════════════════
   STATS
════════════════════════════════════════════════ */
function updateStats() {
  const total  = Object.keys(TWEAKS).length;
  const applied = State.applied.size;
  const sel    = State.selected.size;
  const score  = Math.round((applied / total) * 100);

  const s = id => { const e = $(id); if (e) e.textContent = e._v = arguments[1]; };
  if ($('statApplied'))  $('statApplied').textContent  = applied;
  if ($('statPending'))  $('statPending').textContent  = Math.max(0, sel - applied);
  if ($('statScore'))    $('statScore').textContent    = score + '%';
  if ($('statSelected')) $('statSelected').textContent = sel;

  const fill  = $('progressFill');
  const label = $('progressLabel');
  const pct   = $('progressPct');
  if (fill)  fill.style.width = score + '%';
  if (label) label.textContent = score > 0 ? 'Otimizações aplicadas' : 'Pronto';
  if (pct)   pct.textContent  = score > 0 ? score + '%' : '';
}

/* ════════════════════════════════════════════════
   EXECUÇÃO DE TWEAK
════════════════════════════════════════════════ */
function runTweak(id, btn) {
  const tweak = TWEAKS[id];
  if (!tweak || State.running === id) return;

  const doRun = () => {
    State.running = id;
    if (btn) { btn.textContent = '⟳ Executando...'; btn.classList.add('running'); }
    log('Executando: ' + tweak.label, 'info');
    // Simulação passo a passo das linhas do script PS
    const lines = tweak.ps.split(';').map(l => l.trim()).filter(Boolean);
    let i = 0;
    const iv = setInterval(() => {
      if (i < lines.length) { log('  ' + lines[i], 'default'); i++; }
      else {
        clearInterval(iv);
        State.running = null;
        State.applied.add(id);
        if (btn) {
          btn.classList.remove('running');
          btn.classList.add('done');
          btn.textContent = '✓ Concluído';
          setTimeout(() => { if (btn) { btn.classList.remove('done'); btn.textContent = '▶ Executar Agora'; } }, 3000);
        }
        const card = document.querySelector('[data-tweak="' + id + '"]');
        if (card) card.classList.add('is-active');
        log('[OK] ' + tweak.label + ' — concluído.', 'success');
        toast('Concluído', tweak.label, 'success');
        saveHistory(id, tweak.label);  // v2.2 histórico
        updateStats();
      }
    }, 90);
  };

  if (!tweak.safe) {
    showModal('⚠️', tweak.label, 'Este tweak é avançado e pode alterar o sistema. Crie um Ponto de Restauração antes. Deseja continuar?', doRun);
  } else {
    doRun();
  }
}

/* ════════════════════════════════════════════════
   EXPORTAR SCRIPT .PS1
════════════════════════════════════════════════ */
function exportScript() {
  const sel = [...State.selected];
  if (sel.length === 0) { toast('Nada selecionado', 'Ative os toggles dos tweaks desejados primeiro.', 'warn'); return; }

  let ps = '# HT Technology — Windows Optimizer Pro\n';
  ps += '# Script gerado em: ' + new Date().toLocaleString('pt-BR') + '\n';
  ps += '# Tweaks: ' + sel.length + '\n';
  ps += '# Execute como ADMINISTRADOR\n\n';
  ps += '# Criar Ponto de Restauração\nEnable-ComputerRestore -Drive "C:\\" -EA SilentlyContinue\nCheckpoint-Computer -Description "HT Optimizer Pre-Run" -RestorePointType MODIFY_SETTINGS\n\n';
  sel.forEach(id => {
    const tw = TWEAKS[id];
    if (!tw) return;
    ps += '# --- ' + tw.label + ' ---\n' + tw.ps.trim() + '\n\n';
  });

  const blob = new Blob([ps], { type: 'text/plain;charset=utf-8' });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href     = url;
  a.download = 'HT-Optimizer-' + Date.now() + '.ps1';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  log('Script exportado: ' + sel.length + ' tweaks — execute como Admin!', 'success');
  toast('Script Exportado!', sel.length + ' tweaks prontos. Execute como Administrador!', 'success', 6000);
}

/* ════════════════════════════════════════════════
   SYS INFO (simulado — valores reais via PS)
════════════════════════════════════════════════ */
function startSysInfo() {
  const os = $('osVal');
  if (os) os.textContent = navigator.userAgent.includes('Windows NT 10') ? 'Win 10/11' : 'Windows';
  setInterval(() => {
    const cpu = $('cpuVal'), ram = $('ramVal');
    if (cpu) cpu.textContent = 'CPU ' + (Math.random() * 30 + 5 | 0) + '%';
    if (ram) ram.textContent = 'RAM ' + (Math.random() * 20 + 40 | 0) + '%';
  }, 3000);
}

/* ════════════════════════════════════════════════
   INIT — tudo centralizado aqui
════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', function () {

  // 1. Tema inicial
  setTheme(State.theme);

  // 2. Botão de tema (já está no HTML com id="btnTheme")
  const btnTheme = $('btnTheme');
  if (btnTheme) {
    btnTheme.addEventListener('click', function () {
      // Adiciona classe de animação de transição
      btnTheme.classList.add('switching');
      setTimeout(() => btnTheme.classList.remove('switching'), 500);

      const next = State.theme === 'dark' ? 'light' : 'dark';
      setTheme(next);
      log('Tema alterado para: ' + (next === 'dark' ? '🌙 Escuro' : '☀️ Claro'), 'info');
    });
  }

  // 3. ══ ABAS — event delegation no container pai (100% confiável) ══
  const navContainer = document.querySelector('.nav-tabs');
  if (navContainer) {
    navContainer.addEventListener('click', function (e) {
      const btn = e.target.closest('.nav-tab');
      if (btn && btn.dataset.tab) {
        switchTab(btn.dataset.tab);
      }
    });
  }

  // 4. Toggles de tweak
  document.addEventListener('change', function (e) {
    if (!e.target.classList.contains('tweak-toggle')) return;
    const id = e.target.dataset.tweak;
    if (!id) return;
    if (e.target.checked) {
      State.selected.add(id);
      e.target.closest('.tweak-card')?.classList.add('is-active');
      log('Selecionado: ' + (TWEAKS[id]?.label || id), 'info');
    } else {
      State.selected.delete(id);
      e.target.closest('.tweak-card')?.classList.remove('is-active');
    }
    updateStats();
  });

  // 5. Botões "Executar Agora" — event delegation
  document.addEventListener('click', function (e) {
    const btn = e.target.closest('.tweak-run-btn');
    if (btn) { runTweak(btn.dataset.tweak, btn); return; }

    // Selecionar Todos
    const selAll = e.target.closest('.btn-select-all');
    if (selAll) {
      const panelId = selAll.dataset.panel;
      const panel = $('panel-' + panelId);
      if (panel) {
        panel.querySelectorAll('.tweak-toggle').forEach(t => {
          t.checked = true;
          State.selected.add(t.dataset.tweak);
          t.closest('.tweak-card')?.classList.add('is-active');
        });
        updateStats();
        log('Todos os tweaks de "' + panelId + '" selecionados.', 'info');
      }
      return;
    }

    // Limpar Seleção
    const clrAll = e.target.closest('.btn-clear-all');
    if (clrAll) {
      const panelId = clrAll.dataset.panel;
      const panel = $('panel-' + panelId);
      if (panel) {
        panel.querySelectorAll('.tweak-toggle').forEach(t => {
          t.checked = false;
          State.selected.delete(t.dataset.tweak);
          t.closest('.tweak-card')?.classList.remove('is-active');
        });
        updateStats();
        log('Seleção de "' + panelId + '" limpa.', 'info');
      }
      return;
    }
  });

  // 6. Botão Restauração
  const btnRestore = $('btnRestorePoint');
  if (btnRestore) {
    btnRestore.addEventListener('click', function () {
      showModal('🔒', 'Criar Ponto de Restauração', 'Cria um ponto de restauração do sistema antes de aplicar tweaks. Recomendado! Deseja continuar?', function () {
        log('Criando Ponto de Restauração...', 'info');
        setTimeout(() => {
          State.applied.add('ponto_restauracao');
          log('[OK] Ponto de Restauração criado: HT Optimizer - ' + new Date().toLocaleString('pt-BR'), 'success');
          toast('Restauração', 'Ponto criado! Sistema protegido.', 'success');
          updateStats();
        }, 1000);
      });
    });
  }

  // 7. Botão Executar Marcados
  const btnRunAll = $('btnRunAll');
  if (btnRunAll) {
    btnRunAll.addEventListener('click', function () {
      const sel = [...State.selected];
      if (sel.length === 0) { toast('Nada selecionado', 'Ative os toggles dos tweaks desejados primeiro.', 'warn'); return; }
      showModal('🚀', 'Executar ' + sel.length + ' Tweaks', 'Você selecionou ' + sel.length + ' otimização(ões). Deseja executar todos agora?', function () {
        log('Iniciando ' + sel.length + ' tweaks...', 'warn');
        sel.forEach((id, idx) => {
          setTimeout(() => {
            const card = document.querySelector('[data-tweak="' + id + '"]');
            const btn = card?.querySelector('.tweak-run-btn');
            runTweak(id, btn);
          }, idx * 700);
        });
      });
    });
  }

  // 8. Botão Exportar .ps1 (já no HTML)
  const btnExport = $('btnExport');
  if (btnExport) btnExport.addEventListener('click', exportScript);

  // 9. Terminal — Copiar e Limpar
  $('btnCopyLog')?.addEventListener('click', function () {
    const lines = $$('#terminalLog .term-text').map(e => e.textContent).join('\n');
    navigator.clipboard.writeText(lines)
      .then(() => toast('Log Copiado', 'Conteúdo copiado para a área de transferência.', 'success'))
      .catch(() => toast('Erro', 'Não foi possível copiar.', 'error'));
  });
  $('btnClearLog')?.addEventListener('click', function () {
    const t = $('terminalLog');
    if (t) t.replaceChildren();
    log('Terminal limpo.', 'info');
  });

  // 10. Modal — confirmar e cancelar
  $('modalConfirm')?.addEventListener('click', function () { if (State.pending) State.pending(); closeModal(); });
  $('modalCancel')?.addEventListener('click', closeModal);
  $('modalOverlay')?.addEventListener('click', function (e) { if (e.target === this) closeModal(); });
  document.addEventListener('keydown', e => { if (e.key === 'Escape' && !$('modalOverlay')?.hidden) closeModal(); });

  // 11. Sys info
  startSysInfo();

  // 12. Stats iniciais
  updateStats();

  // 13. Logs de boas-vindas
  log('HT Technology Optimizer Pro v2.2 | ' + new Date().toLocaleDateString('pt-BR'), 'info');
  log('Total de tweaks disponíveis: ' + Object.keys(TWEAKS).length, 'info');
  log('NOVO v2.2: Perfis Gaming/Office/Servidor | VBS Toggle | Low Latency Profile | Busca de tweaks', 'success');
  log('Dica: Clique em "Exportar .ps1" para executar todos como Administrador!', 'warn');

  // 14. Perfis de Otimização (v2.2)
  document.querySelectorAll('.btn-profile-apply').forEach(btn => {
    btn.addEventListener('click', function() {
      const profileId = this.dataset.profile;
      const profile = PROFILES[profileId];
      if (!profile) return;
      showModal('🚀', 'Aplicar Perfil: ' + profile.label,
        'Isso irá selecionar e executar ' + profile.tweaks.length + ' tweaks otimizados para ' + profile.label + '. Deseja continuar?',
        function() {
          log('[PERFIL] Aplicando: ' + profile.label + ' (' + profile.tweaks.length + ' tweaks)', 'info');
          profile.tweaks.forEach((id, idx) => {
            setTimeout(() => {
              // Select the toggle
              const toggle = document.querySelector('.tweak-toggle[data-tweak="' + id + '"]');
              if (toggle && !toggle.checked) {
                toggle.checked = true;
                State.selected.add(id);
                toggle.closest('.tweak-card')?.classList.add('is-active');
              }
              // Run the tweak
              const card = document.querySelector('[data-tweak="' + id + '"]');
              const runBtn = card?.querySelector('.tweak-run-btn');
              if (TWEAKS[id]) runTweak(id, runBtn);
            }, idx * 500);
          });
          setTimeout(() => {
            toast('🎮 Perfil ' + profile.label, 'Todos os tweaks aplicados com sucesso!', 'success', 6000);
            log('[OK] Perfil ' + profile.label + ' aplicado!', 'success');
          }, profile.tweaks.length * 500 + 500);
        }
      );
    });
  });

  // 15. Busca de tweaks (v2.2)
  const searchInput = $('tweakSearch');
  if (searchInput) {
    searchInput.addEventListener('input', function() {
      const q = this.value.trim().toLowerCase();
      if (!q) {
        $$('.tweak-card').forEach(card => card.style.display = '');
        return;
      }
      $$('.tweak-card').forEach(card => {
        const title = card.querySelector('.tweak-title')?.textContent.toLowerCase() || '';
        const desc  = card.querySelector('.tweak-desc')?.textContent.toLowerCase() || '';
        const tags  = [...card.querySelectorAll('.tag')].map(t => t.textContent.toLowerCase()).join(' ');
        const match = title.includes(q) || desc.includes(q) || tags.includes(q);
        card.style.display = match ? '' : 'none';
      });
    });
    // Clear on Escape
    searchInput.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') { this.value = ''; this.dispatchEvent(new Event('input')); this.blur(); }
    });
  }

  // 16. Carregar histórico salvo (v2.2)
  const history = loadHistory();
  if (history.length > 0) {
    log('[HISTÓRICO] Últimos ' + Math.min(history.length, 3) + ' tweaks executados:', 'info');
    history.slice(0, 3).forEach(h => {
      const dt = new Date(h.ts).toLocaleDateString('pt-BR');
      log('  ✓ ' + h.label + ' (' + dt + ')', 'success');
    });
  }
});
