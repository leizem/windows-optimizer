# 🖥️ HT Technology — Windows Optimizer Pro

> **Dashboard Premium de Otimização para Windows 10 & 11**
> Versão 2.1 · Desenvolvido por HT Technology · 19/06/2026

[🇺🇸 English Version](README.en.md)

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Screenshots](#-screenshots)
- [Funcionalidades](#-funcionalidades)
- [Arquitetura](#-arquitetura)
- [Requisitos](#-requisitos)
- [Instalação e Uso](#-instalação-e-uso)
- [Módulos de Tweaks](#-módulos-de-tweaks)
- [Backend PowerShell](#-backend-powershell)
- [Segurança](#-segurança)
- [Estrutura de Arquivos](#-estrutura-de-arquivos)
- [Roadmap](#-roadmap)
- [Licença](#-licença)

---

## 🚀 Sobre o Projeto

O **HT Technology Windows Optimizer Pro** é um dashboard premium de otimização completo para Windows 10 e 11. Desenvolvido com design moderno (tema escuro/claro com glassmorphism), reúne em uma única interface mais de **50 tweaks e otimizações** cuidadosamente selecionados para maximizar performance, privacidade, segurança e experiência de uso do sistema.

### Por que usar?

| Problema | Solução |
|---|---|
| Windows lento ou travando | Tweaks de performance, plano Ultimate, HAGS |
| Telemetria e rastreamento Microsoft | Desativação completa de telemetria e Recall AI |
| Disco cheio de lixo | Limpeza profunda automatizada em múltiplos paths |
| Alta latência em jogos | Nagle off, Game Mode, HAGS, Timer Resolution |
| Bloatwares pré-instalados | Remoção via AppxPackage com fallback seguro |
| Sistema corrompido | SFC, DISM e reparação WMI integrados |

---

## 📸 Screenshots

> Dashboard rodando em tema escuro (padrão)

```
╔══════════════════════════════════════════════════════════════════╗
║   HT Technology  │ Diagnóstico │ Performance │ Privacidade │ ... ║
╠══════════════════════════════════════════════════════════════════╣
║  ✓ Aplicados: 0  │ ⏱ Pendentes: 0  │ ⚡ Score: 0%  │ ⚠ Sel: 0 ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [Reparo Rápido ●]  [SFC/DISM ○]  [ChkDsk ○]  [Cache VSS ○]    ║
║  [WMI Repair ○]     [WU Reset ○]  [Rede ○]     [TRIM ○]         ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║  Terminal ─────────────────────────────── [Copiar] [Limpar]     ║
║  ❯ HT Technology Optimizer Pro v2.1 | 19/06/2026               ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## ✨ Funcionalidades

### Dashboard
- 🎨 **Tema Claro / Escuro** — alternância com persistência via localStorage
- 📊 **Stats em tempo real** — aplicados, pendentes, score geral, selecionados
- 📈 **Barra de progresso** — percentual de otimizações aplicadas
- 💻 **Monitor de sistema** — CPU%, RAM%, versão do OS (atualiza a cada 3s)
- 🖥️ **Terminal técnico** — log em tempo real de todas as ações
- 🔔 **Toast notifications** — feedback visual de sucesso, erro, aviso, info

### Tweaks
- ☑️ **Toggle por tweak** — selecione individualmente quais aplicar
- ⚡ **Executar individualmente** — botão "Executar Agora" por card
- 🚀 **Executar todos marcados** — `Executar Marcados` com confirmação modal
- 📋 **Selecionar Todos / Limpar** — atalhos por painel/categoria
- 💾 **Exportar .ps1** — gera script PowerShell pronto para execução como Admin
- 🔒 **Ponto de Restauração** — criado automaticamente antes de tweaks avançados

### Segurança
- ⚠️ **Modal de confirmação** — tweaks avançados pedem confirmação explícita
- 🛡️ **Badge por nível de risco** — `Recomendado` | `Seguro` | `Avançado` | `Cuidado`
- 🔄 **Restauração do Sistema** — acesso rápido ao rstrui.exe
- 📝 **Log persistente** — tudo registrado no terminal técnico

---

## 🏗️ Arquitetura

```
WINDOWS OPTIMIZER/
│
├── frontend/                   ← Interface Web (HTML/CSS/JS)
│   ├── index.html              ← Estrutura do dashboard (8 painéis, 50+ cards)
│   ├── style.css               ← Tema premium dark/light, glassmorphism, animações
│   └── app.js                  ← Lógica de UI, tab switching, API calls
│
├── backend/                    ← Backend Python (Flask) + Scripts PS1
│   ├── server.py               ← API REST com SSE streaming
│   ├── tweaks_runner.py        ← Executor de scripts PowerShell
│   ├── sysinfo.py              ← Métricas de sistema (psutil + WMI)
│   ├── requirements.txt        ← Dependências Python
│   └── scripts/                ← Scripts PS1 por categoria
│       ├── diagnostico.ps1
│       ├── performance.ps1
│       ├── privacidade.ps1
│       ├── limpeza.ps1
│       ├── rede.ps1
│       ├── gaming.ps1
│       ├── seguranca.ps1
│       └── sistema.ps1
│
├── HT-Optimizer-Backend.ps1    ← Backend PowerShell standalone (execução direta)
├── launcher.py                 ← Inicia servidor e abre o browser
├── run.bat                     ← Launcher com duplo clique (Admin)
├── index.html                  ← Alias raiz para frontend/index.html
├── style.css                   ← Alias raiz para frontend/style.css
├── app.js                      ← Alias raiz para frontend/app.js
└── README.md                   ← Este arquivo
```

### Fluxo de Dados

```
Usuário clica "Executar"
        │
        ▼
  frontend/app.js
  detecta servidor Python?
        │
   ┌────┴────┐
  SIM       NÃO
   │         │
   ▼         ▼
POST /api/  Simulação
run/<id>    local JS
   │
   ▼
backend/server.py
   │
   ▼
tweaks_runner.py
subprocess.Popen([
  "powershell.exe",
  "-NonInteractive",
  "-File", "scripts/<cat>.ps1",
  "-Tweak", "<id>"
])
   │
   ▼
SSE streaming
(saída linha a linha)
   │
   ▼
Terminal do Dashboard
```

---

## 🔧 Requisitos

### Mínimos
| Componente | Versão |
|---|---|
| Windows | 10 (21H2+) ou 11 |
| PowerShell | 5.1+ (nativo) |
| Navegador | Chrome 90+ / Edge 90+ / Firefox 88+ |

### Para backend Python (opcional)
| Componente | Versão |
|---|---|
| Python | 3.9+ |
| pip | Incluído com Python |

### Permissões
> ⚠️ **Obrigatório para tweaks de sistema:** Execute como **Administrador**

---

## ⚙️ Instalação e Uso

### Modo 1 — Frontend direto (mais simples)

```bash
# 1. Abra index.html diretamente no navegador
# 2. Use o botão "Exportar .ps1" para gerar script
# 3. Execute o .ps1 gerado como Administrador no PowerShell
```

```powershell
# No PowerShell (Administrador):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\HT-Optimizer-<timestamp>.ps1
```

### Modo 2 — Backend PowerShell standalone

```powershell
# Execução direta (PowerShell como Admin):

# Listar todos os tweaks disponíveis
.\HT-Optimizer-Backend.ps1

# Executar um tweak específico
.\HT-Optimizer-Backend.ps1 -Tweak "telemetria"
.\HT-Optimizer-Backend.ps1 -Tweak "perf_fso"
.\HT-Optimizer-Backend.ps1 -Tweak "game_mode"

# Executar todos os tweaks seguros (38 tweaks)
.\HT-Optimizer-Backend.ps1 -RunAll

# Gerar relatório HTML na Área de Trabalho
.\HT-Optimizer-Backend.ps1 -ExportReport

# Pular criação de ponto de restauração
.\HT-Optimizer-Backend.ps1 -RunAll -SkipRestorePoint

# Modo silencioso (sem output no console)
.\HT-Optimizer-Backend.ps1 -Tweak "dark_mode" -Silent
```

### Modo 3 — Backend Python + Dashboard completo

```bash
# 1. Instalar Python 3.9+
# 2. Abrir terminal como Administrador

# Instalar dependências
pip install flask flask-cors psutil wmi pywin32

# Iniciar servidor
python launcher.py

# OU simplesmente:
run.bat  # (duplo clique como Admin)

# Dashboard abre automaticamente em:
# http://localhost:5050
```

---

## 📦 Módulos de Tweaks

### 🔬 Diagnóstico & Reparos (12 tweaks)

| Tweak | Nível | Descrição |
|---|---|---|
| Reparo Rápido Completo | ✅ Recomendado | SFC + DISM RestoreHealth em sequência |
| SFC / DISM Completo | 🟢 Seguro | Verificação e restauro de integridade |
| Corrigir Erros de Disco | 🟡 Avançado | ChkDsk /f /r /x agendado |
| Limpeza Total Cache/VSS | 🟢 Seguro | %TEMP%, Windows\Temp, SoftDist\Download |
| Reparar Repositório WMI | 🟡 Avançado | winmgmt /resetrepository |
| Reset Windows Update | 🟡 Avançado | Para serviços, limpa SoftwareDistribution |
| Reset de Rede | 🟢 Seguro | ip reset, winsock reset, flushdns |
| TRIM / Defrag | 🟢 Seguro | Optimize-Volume por drive |
| Limpar Drivers Antigos | 🟡 Avançado | pnputil /delete-driver |
| Diagnóstico de Energia | 🟢 Seguro | batteryreport + energy report HTML |
| Limpar Log de Eventos | 🟢 Seguro | Clear-EventLog todos os logs |
| Limpar Prefetch | 🟢 Seguro | Windows\Prefetch\ |

### ⚡ Hardware & Performance (12 tweaks)

| Tweak | Nível | Descrição |
|---|---|---|
| Tweaks Performance + FSO | ✅ Recomendado | HAGS + GameMode + SystemProfile |
| Otimizar Latência (Jogos) | 🟢 Seguro | Nagle off + Network Throttling Index |
| Plano Ultimate Performance | 🟡 CPU Intensivo | powercfg SCHEME_MIN oculto |
| Remover Bloatwares | 🟡 Avançado | 29 apps UWP pré-instalados |
| Apps de Inicialização | 🟢 Seguro | Auditoria Run keys |
| Config Máquina (msconfig) | 🟡 Avançado | bcdedit numproc + useplatformtick |
| Efeitos Visuais | 🟢 Seguro | VisualFXSetting=2, animações off |
| Desativar SysMain | 🟡 SSD Recom. | Stop + Disabled SysMain |
| Otimizar Cache RAM | ✅ Recomendado | LargeSystemCache + DisablePagingExec |
| Desativar Energy Throttling | 🟡 Bateria | PowerThrottlingOff=1 |
| IRQ Affinity + MSI Mode | 🟡 Avançado | MSI Mode para GPU via registro |
| Timer Resolution 0.5ms | 🟡 Gaming Adv | bcdedit disabledynamictick |

### 🔒 Privacidade (12 tweaks)

| Tweak | Nível | Descrição |
|---|---|---|
| Desativar Telemetria | 🟢 Seguro | 8 serviços + 8 chaves de registro |
| Desativar Promos/Exp | 🟢 Seguro | ContentDeliveryManager off |
| Remover Copilot + Bing | 🟢 Seguro | Busca Bing off + AppxPackage |
| Remover Widgets + Clima | 🟢 Seguro | TaskbarDa=0 + WebExperience |
| Desativar SmartScreen | 🟡 Avançado | EnableSmartScreen=0 |
| Ativar Proteção Disco C: | 🟢 Seguro | Enable-ComputerRestore |
| Restauração do Sistema | 🟢 Seguro | Abre rstrui.exe |
| Desativar Hibernação | 🟢 Seguro | powercfg -h off (libera SSD) |
| Bloquear Histórico | 🟢 Seguro | EnableActivityFeed=0 |
| Desativar ID de Anúncios | 🟢 Seguro | AdvertisingInfo.Enabled=0 |
| Desativar Recall AI | 🟢 Seguro | DisableAIDataAnalysis=1 |
| Bloquear Câmera/Mic/GPS | 🟢 Seguro | AppPrivacy políticas |

### 🧹 Limpeza (6 tweaks)

| Tweak | Nível | Descrição |
|---|---|---|
| Limpeza Profunda Temp | 🟢 Seguro | 6 paths de temporários |
| Compactar WinSxS | 🟢 Seguro | DISM StartComponentCleanup /ResetBase |
| Esvaziar Lixeira | 🟢 Seguro | Clear-RecycleBin + Thumbs.db |
| Cache Navegadores | 🟢 Seguro | Chrome, Edge, Firefox, Brave, Opera |
| Cache Windows Update | 🟢 Seguro | SoftwareDistribution\Download |
| Cache de Fontes | 🟢 Seguro | FontCache service rebuild |

### 🌐 Rede & DNS (5 tweaks)

| Tweak | Nível | Descrição |
|---|---|---|
| DNS DoH Cloudflare | 🟢 Seguro | 1.1.1.1 + 1.0.0.1 em todos adapts. |
| TCP Auto-Tuning | 🟢 Seguro | autotuninglevel + RSS + ECN |
| Desativar IPv6 | 🟡 Avançado | ms_tcpip6 binding off |
| Tweaks Adaptador de Rede | 🟡 Avançado | InterruptModeration off |
| Firewall Anti-Telemetria | 🟢 Seguro | Block outbound 10 hosts MS |

### 🎮 Gaming & FPS (6 tweaks)

| Tweak | Nível | Descrição |
|---|---|---|
| Game Mode + HAGS | 🟢 Seguro | AutoGameModeEnabled + HwSchMode=2 |
| Limpar Shaders DirectX | 🟢 Seguro | D3DSCache + NVIDIA/AMD cache |
| Remover Serviços Xbox | 🟡 Avançado | 5 AppxPackage Xbox |
| Tweaks NVIDIA/AMD | 🟡 Avançado | PerfLevelSrc + PowerMizer |
| Prioridade CPU Jogos | 🟢 Seguro | Win32PrioritySeparation=38 |
| Fullscreen Opt. Global Off | 🟢 Seguro | GameDVR_FSEBehaviorMode=2 |

### 🛡️ Segurança (4 tweaks)

| Tweak | Nível | Descrição |
|---|---|---|
| Atualizar Defender | 🟢 Seguro | Update-MpSignature + QuickScan |
| Configurar UAC | 🟢 Seguro | ConsentPromptBehaviorAdmin=5 |
| Exploit Protection | 🟢 Seguro | DEP + SEHOP via Set-Processmitigation |
| Desativar RDP | 🟢 Seguro | fDenyTSConnections=1 + Firewall |

### 🖥️ Sistema & Interface (6 tweaks)

| Tweak | Nível | Descrição |
|---|---|---|
| Forçar Modo Escuro | 🟢 Seguro | AppsUseLightTheme=0 + explorer |
| Limpar Barra de Tarefas | 🟢 Seguro | TaskbarMn + ShowTaskViewButton off |
| Menu Contexto Clássico | 🟢 Seguro | CLSID InprocServer32 hack Win11 |
| NumLock na Inicialização | 🟢 Seguro | InitialKeyboardIndicators=2 |
| Exibir Extensões/Ocultos | 🟢 Seguro | HideFileExt=0 + Hidden=1 |
| Configurar WU Automático | 🟢 Seguro | AUOptions=2 (notificar) |

---

## 🔌 Backend PowerShell — API de Linha de Comando

O arquivo `HT-Optimizer-Backend.ps1` é um motor autônomo completo:

```powershell
# Parâmetros disponíveis:
-Tweak         <string>   # ID do tweak específico
-RunAll                   # Executa todos os 38 tweaks seguros
-ExportReport             # Gera relatório HTML
-SkipRestorePoint         # Pula criação de ponto de restauração
-Silent                   # Sem output no console (apenas log em arquivo)

# IDs de tweaks disponíveis:
reparo_rapido, sfc_dism, chkdsk, limpeza_cache, reparar_wmi,
reset_wupdate, otimizar_rede, trim_defrag, event_log,
diagnostico_energia, perf_fso, latencia_rede, plano_max,
bloatwares, efeitos_visuais, sysmain, cache_ram, energy_throttle,
timer_resolution, telemetria, copilot_bing, widgets, smartscreen,
protecao_disco, hibernacao_ssd, historico_atividade, advertising_id,
recall_ai, location_cam, temp_system, winsxs, recycle_bin,
browser_cache, font_cache, dns_doh, tcp_autotuning, ipv6_disable,
firewall_rules, game_mode, dx_shader, cpu_priority, nvidia_tweaks,
disable_fullscreen_opt, defender_update, uac_level,
exploit_protection, rdp_disable, dark_mode, context_menu,
show_extensions, num_lock, auto_updates
```

### Log de execução
```
%TEMP%\HT-Optimizer-Log.txt
%USERPROFILE%\Desktop\HT-Optimizer-Relatorio.html
```

---

## 🐍 Backend Python — API REST

```
Base URL: http://localhost:5050

GET  /                        → Serve o dashboard (frontend/index.html)
GET  /api/health              → {"status": "ok", "version": "2.1"}
GET  /api/tweaks              → Lista todos os tweaks disponíveis
GET  /api/sysinfo             → CPU%, RAM%, disco, OS, uptime
POST /api/run/<tweak_id>      → Executa tweak, retorna JSON
GET  /api/stream/<tweak_id>   → SSE — stream linha a linha do PS
POST /api/restore-point       → Cria ponto de restauração
GET  /api/history             → Histórico de execuções (SQLite)
```

### Dependências Python

```
flask>=3.0.0
flask-cors>=4.0.0
psutil>=5.9.0
wmi>=1.5.1
pywin32>=306
```

---

## 🔐 Segurança

### Medidas implementadas

| Área | Medida |
|---|---|
| XSS Frontend | Todo texto inserido via `textContent` (nunca `innerHTML`) |
| Injeção de Comandos | IDs de tweaks validados contra whitelist antes de executar |
| Elevação de privilégio | Verificação de Admin antes de qualquer tweak de sistema |
| Ponto de Restauração | Criado automaticamente antes de tweaks avançados |
| Execução de Política PS | Scripts usam `-NonInteractive -NoProfile` |
| Sem dependências externas | Frontend não carrega scripts de CDN externos |
| Log de auditoria | Todas as execuções registradas com timestamp |

### Níveis de risco dos tweaks

```
✅ Recomendado  → Seguro, sem riscos, reversível facilmente
🟢 Seguro       → Sem impacto negativo em uso normal
🟡 Avançado     → Pode afetar comportamento, reversível via restauração
🔴 Perigo       → (Nenhum neste app — excluídos por segurança)
```

> **Nunca são incluídos:** formatações, exclusão de arquivos de sistema,
> desativação de firewall principal, tweaks que exigem modo de segurança.

---

## 📁 Estrutura de Arquivos Completa

```
WINDOWS OPTIMIZER/
│
├── 📄 README.md                        ← Este arquivo
├── 🌐 index.html                       ← Dashboard principal (1580 linhas)
├── 🎨 style.css                        ← Tema premium dark/light (800+ linhas)
├── ⚙️  app.js                           ← Lógica frontend (600+ linhas)
├── 🔷 HT-Optimizer-Backend.ps1         ← Backend PS standalone (750+ linhas)
│
├── 📂 frontend/
│   ├── index.html                      ← Cópia organizada do frontend
│   ├── style.css
│   └── app.js
│
└── 📂 backend/
    ├── server.py                       ← Flask API server
    ├── tweaks_runner.py                ← PS executor + SSE streaming
    ├── sysinfo.py                      ← psutil + WMI metrics
    ├── requirements.txt
    └── 📂 scripts/
        ├── diagnostico.ps1
        ├── performance.ps1
        ├── privacidade.ps1
        ├── limpeza.ps1
        ├── rede.ps1
        ├── gaming.ps1
        ├── seguranca.ps1
        └── sistema.ps1
```

---

## 🗺️ Roadmap

### v2.1 (Atual)
- [x] Dashboard premium com 8 módulos
- [x] 50+ tweaks organizados por categoria
- [x] Tema claro/escuro com persistência
- [x] Terminal técnico em tempo real
- [x] Exportação de script .ps1
- [x] Backend PowerShell standalone completo
- [x] Modal de confirmação para tweaks avançados
- [x] Ponto de restauração automático
- [x] Separação frontend / backend

### v2.2 (Planejado)
- [ ] Backend Python com SSE streaming real
- [ ] CPU/RAM/Disco em tempo real via psutil
- [ ] Histórico de execuções (SQLite)
- [ ] Perfis de otimização (Gaming, Office, Servidor)
- [ ] Agendador de limpeza automática
- [ ] Comparativo antes/depois (benchmark)

### v3.0 (Futuro)
- [ ] Empacotamento como app Electron ou PyWebView
- [ ] Atualização automática de tweaks via GitHub
- [ ] Suporte a múltiplas máquinas (modo rede local)
- [ ] Plugin de tweaks customizáveis

---

## 📊 Pesquisa e Fontes

Este projeto foi desenvolvido com base em pesquisa de:

- **Chris Titus Tech WinUtil** — tweaks de registro e serviços Windows
- **Awesome Windows Tweaks (GitHub)** — compilação de otimizações
- **CTT Tech Toolbox** — scripts PowerShell de otimização 2025/2026
- **Microsoft Docs** — APIs Win32, bcdedit, netsh, powercfg
- **FPS Benchmarks Community** — tweaks de gaming (HAGS, Timer Resolution)
- **Privacy Guides** — remoção de telemetria e Recall AI
- **Bleeping Computer** — scripts de limpeza e manutenção
- **SS64.com PowerShell Reference** — sintaxe e cmdlets

---

## ⚖️ Licença

```
HT Technology — Windows Optimizer Pro
Copyright © 2026 HT Technology. Todos os direitos reservados.

Este software é de uso interno / proprietário da HT Technology.
Redistribuição não autorizada é proibida.
```

---

## 👨‍💻 Desenvolvido por

```
  ╔══════════════════════════════════╗
  ║       HT Technology              ║
  ║   Windows Optimizer Pro v2.1     ║
  ║   19 de Junho de 2026            ║
  ╚══════════════════════════════════╝
```

> **Sempre crie um Ponto de Restauração antes de aplicar tweaks avançados.**
> Em caso de problemas, use `rstrui.exe` para reverter as alterações.
