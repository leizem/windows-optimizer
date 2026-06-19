# 🖥️ HT Technology — Windows Optimizer Pro

> **Premium All-in-One Optimization Dashboard for Windows 10 & 11**
> Version 2.1 · Developed by HT Technology · June 19, 2026

[🇧🇷 Versão em Português](README.pt-br.md)

---

## 📋 Table of Contents

- [About](#-about)
- [Screenshots](#-screenshots)
- [Features](#-features)
- [Architecture](#-architecture)
- [Requirements](#-requirements)
- [Installation & Usage](#-installation--usage)
- [Tweak Modules](#-tweak-modules)
- [PowerShell Backend](#-powershell-backend--cli-api)
- [Python Backend](#-python-backend--rest-api)
- [Security](#-security)
- [File Structure](#-file-structure)
- [Roadmap](#-roadmap)
- [License](#-license)

---

## 🚀 About

**HT Technology Windows Optimizer Pro** is a premium, all-in-one optimization dashboard for Windows 10 and 11. Built with a modern glassmorphism UI featuring light/dark mode, it brings together **50+ carefully selected tweaks** across 8 categories — all in a single, clean interface — to maximize your system's performance, privacy, security, and user experience.

### Why use it?

| Problem | Solution |
|---|---|
| Slow or stuttering Windows | Performance tweaks, Ultimate Power Plan, HAGS |
| Microsoft telemetry & tracking | Full telemetry disable, Recall AI off, firewall rules |
| Disk full of junk | Deep automated clean across multiple paths |
| High latency in games | Nagle off, Game Mode, HAGS, Timer Resolution 0.5ms |
| Pre-installed bloatware | Removal via AppxPackage with safe fallback |
| Corrupted system files | Integrated SFC, DISM, and WMI repair tools |
| Privacy exposure | Camera, mic, location, advertising ID, activity history blocked |

---

## 📸 Screenshots

> Dashboard running in dark mode (default)

```
╔══════════════════════════════════════════════════════════════════╗
║  HT Technology │ Diagnostics │ Performance │ Privacy │  ...  🌙  ║
╠══════════════════════════════════════════════════════════════════╣
║  ✓ Applied: 0  │ ⏱ Pending: 0  │ ⚡ Score: 0%  │ ⚠ Selected: 0 ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  [Quick Repair ●]  [SFC/DISM ○]  [ChkDsk ○]  [Cache VSS ○]     ║
║  [WMI Repair ○]    [WU Reset ○]  [Network ○]  [TRIM ○]          ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║  Terminal ──────────────────────────────── [Copy] [Clear]       ║
║  ❯ HT Technology Optimizer Pro v2.1 | 06/19/2026               ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## ✨ Features

### Dashboard
- 🎨 **Light / Dark Theme** — toggle with moon 🌙 / sun ☀️ icon, saved via localStorage
- 📊 **Live Stats** — applied, pending, overall score, selected count
- 📈 **Progress Bar** — real-time percentage of applied optimizations
- 💻 **System Monitor** — CPU%, RAM%, OS version (updates every 3s)
- 🖥️ **Technical Terminal** — live log of all actions
- 🔔 **Toast Notifications** — success, error, warning, info feedback

### Tweaks
- ☑️ **Per-Tweak Toggle** — select exactly which tweaks to apply
- ⚡ **Run Individually** — "Run Now" button per tweak card
- 🚀 **Run All Selected** — batch execution with confirmation modal
- 📋 **Select All / Clear** — quick shortcuts per category panel
- 💾 **Export .ps1** — generates a runnable PowerShell script
- 🔒 **Restore Point** — automatically created before advanced tweaks

### Security
- ⚠️ **Confirmation Modal** — advanced tweaks require explicit user consent
- 🛡️ **Risk Badge per Tweak** — `Recommended` | `Safe` | `Advanced` | `Caution`
- 🔄 **System Restore** — quick shortcut to rstrui.exe
- 📝 **Audit Log** — all actions recorded in the terminal

---

## 🏗️ Architecture

```
WINDOWS OPTIMIZER/
│
├── frontend/                   ← Web UI (HTML/CSS/JS)
│   ├── index.html              ← Dashboard structure (8 panels, 50+ cards)
│   ├── style.css               ← Premium dark/light theme, glassmorphism
│   └── app.js                  ← UI logic, tab switching, API calls
│
├── backend/                    ← Python (Flask) API + PS1 scripts
│   ├── server.py               ← REST API with SSE streaming
│   ├── tweaks_runner.py        ← PowerShell process executor
│   ├── sysinfo.py              ← System metrics (psutil + WMI)
│   ├── requirements.txt        ← Python dependencies
│   └── scripts/                ← PS1 scripts per category
│       ├── diagnostics.ps1
│       ├── performance.ps1
│       ├── privacy.ps1
│       ├── cleanup.ps1
│       ├── network.ps1
│       ├── gaming.ps1
│       ├── security.ps1
│       └── system.ps1
│
├── HT-Optimizer-Backend.ps1    ← Standalone PowerShell backend
├── launcher.py                 ← Starts server and opens browser
├── run.bat                     ← One-click launcher (Admin)
├── index.html                  ← Root alias → frontend/index.html
├── style.css
├── app.js
└── README.md
```

### Data Flow

```
User clicks "Run Now"
        │
        ▼
  frontend/app.js
  Is Python server running?
        │
   ┌────┴────┐
  YES        NO
   │          │
   ▼          ▼
POST /api/  JS local
run/<id>    simulation
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
(line-by-line output)
   │
   ▼
Dashboard Terminal
```

---

## 🔧 Requirements

### Minimum
| Component | Version |
|---|---|
| Windows | 10 (21H2+) or 11 |
| PowerShell | 5.1+ (built-in) |
| Browser | Chrome 90+ / Edge 90+ / Firefox 88+ |

### Python Backend (optional)
| Component | Version |
|---|---|
| Python | 3.9+ |
| pip | Included with Python |

### Permissions
> ⚠️ **Required for system tweaks:** Run as **Administrator**

---

## ⚙️ Installation & Usage

### Mode 1 — Direct Frontend (simplest)

```bash
# 1. Open index.html directly in your browser
# 2. Select desired tweaks using the toggle switches
# 3. Click "Export .ps1" to generate a script
# 4. Run the generated .ps1 as Administrator in PowerShell
```

```powershell
# In PowerShell (Run as Administrator):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\HT-Optimizer-<timestamp>.ps1
```

### Mode 2 — Standalone PowerShell Backend

```powershell
# Run directly in PowerShell as Administrator:

# List all available tweaks
.\HT-Optimizer-Backend.ps1

# Run a specific tweak
.\HT-Optimizer-Backend.ps1 -Tweak "telemetry"
.\HT-Optimizer-Backend.ps1 -Tweak "perf_fso"
.\HT-Optimizer-Backend.ps1 -Tweak "game_mode"

# Run all 38 safe tweaks at once
.\HT-Optimizer-Backend.ps1 -RunAll

# Export an HTML report to the Desktop
.\HT-Optimizer-Backend.ps1 -ExportReport

# Skip Restore Point creation
.\HT-Optimizer-Backend.ps1 -RunAll -SkipRestorePoint

# Silent mode (log only, no console output)
.\HT-Optimizer-Backend.ps1 -Tweak "dark_mode" -Silent
```

### Mode 3 — Python Backend + Full Dashboard

```bash
# 1. Install Python 3.9+
# 2. Open a terminal as Administrator

# Install dependencies
pip install flask flask-cors psutil wmi pywin32

# Start the server
python launcher.py

# Or simply double-click:
run.bat   # (Run as Administrator)

# Dashboard auto-opens at:
# http://localhost:5050
```

---

## 📦 Tweak Modules

### 🔬 Diagnostics & Repair (12 tweaks)

| Tweak | Level | Description |
|---|---|---|
| Quick Full Repair | ✅ Recommended | SFC + DISM RestoreHealth in sequence |
| SFC / DISM Full | 🟢 Safe | System integrity check and restore |
| Fix Disk Errors | 🟡 Advanced | ChkDsk /f /r /x scheduled on next boot |
| Full Cache / VSS Cleanup | 🟢 Safe | %TEMP%, Windows\Temp, SoftDist\Download |
| Repair WMI Repository | 🟡 Advanced | winmgmt /resetrepository |
| Reset Windows Update | 🟡 Advanced | Stops services, clears SoftwareDistribution |
| Network Reset | 🟢 Safe | ip reset, winsock reset, flushdns |
| TRIM / Defrag | 🟢 Safe | Optimize-Volume per drive |
| Clean Old Drivers | 🟡 Advanced | pnputil /delete-driver |
| Energy / Battery Report | 🟢 Safe | batteryreport + energy report HTML |
| Clear Event Logs | 🟢 Safe | Clear-EventLog for all logs |
| Clear Prefetch | 🟢 Safe | Windows\Prefetch\ |

### ⚡ Hardware & Performance (12 tweaks)

| Tweak | Level | Description |
|---|---|---|
| Performance Tweaks + FSO | ✅ Recommended | HAGS + GameMode + SystemProfile |
| Network Latency Optimizer | 🟢 Safe | Nagle off + Network Throttling Index |
| Ultimate Performance Plan | 🟡 CPU Intensive | powercfg hidden SCHEME_MIN plan |
| Remove Bloatware | 🟡 Advanced | 29 pre-installed UWP apps |
| Startup Apps Audit | 🟢 Safe | Run keys audit and mitigation |
| Machine Config (msconfig) | 🟡 Advanced | bcdedit numproc + useplatformtick |
| Visual Effects | 🟢 Safe | VisualFXSetting=2, animations off |
| Disable SysMain | 🟡 SSD Recommended | Stop + Disable SysMain service |
| RAM Cache Optimizer | ✅ Recommended | LargeSystemCache + DisablePagingExec |
| Disable Energy Throttling | 🟡 Battery Impact | PowerThrottlingOff=1 |
| IRQ Affinity + MSI Mode | 🟡 Advanced | MSI Mode for GPU via registry |
| Timer Resolution 0.5ms | 🟡 Advanced Gaming | bcdedit disabledynamictick |

### 🔒 Privacy (12 tweaks)

| Tweak | Level | Description |
|---|---|---|
| Disable Full Telemetry | 🟢 Safe | 8 services + 8 registry keys |
| Disable Promotions/UX | 🟢 Safe | ContentDeliveryManager off |
| Remove Copilot + Bing | 🟢 Safe | Bing search off + AppxPackage removal |
| Remove Widgets | 🟢 Safe | TaskbarDa=0 + WebExperience removal |
| Disable SmartScreen | 🟡 Advanced | EnableSmartScreen=0 |
| Enable Disk C: Protection | 🟢 Safe | Enable-ComputerRestore |
| Open System Restore | 🟢 Safe | Launches rstrui.exe |
| Disable Hibernation | 🟢 Safe | powercfg -h off (frees SSD space) |
| Block Activity History | 🟢 Safe | EnableActivityFeed=0 |
| Disable Advertising ID | 🟢 Safe | AdvertisingInfo.Enabled=0 |
| Disable Windows Recall AI | 🟢 Safe | DisableAIDataAnalysis=1 |
| Block Camera/Mic/GPS | 🟢 Safe | AppPrivacy policies |

### 🧹 Cleanup (6 tweaks)

| Tweak | Level | Description |
|---|---|---|
| Deep Temp File Cleanup | 🟢 Safe | 6 temporary file paths |
| Compact WinSxS | 🟢 Safe | DISM StartComponentCleanup /ResetBase |
| Empty Recycle Bin | 🟢 Safe | Clear-RecycleBin + Thumbs.db |
| Browser Cache Cleanup | 🟢 Safe | Chrome, Edge, Firefox, Brave, Opera |
| Windows Update Cache | 🟢 Safe | SoftwareDistribution\Download |
| Font Cache Rebuild | 🟢 Safe | FontCache service rebuild |

### 🌐 Network & DNS (5 tweaks)

| Tweak | Level | Description |
|---|---|---|
| Secure DNS (DoH) — Cloudflare | 🟢 Safe | 1.1.1.1 + 1.0.0.1 on all adapters |
| TCP Auto-Tuning | 🟢 Safe | autotuninglevel + RSS + ECN |
| Disable IPv6 | 🟡 Advanced | ms_tcpip6 binding off |
| Advanced Network Adapter | 🟡 Advanced | InterruptModeration off |
| Anti-Telemetry Firewall Rules | 🟢 Safe | Block outbound to 10 Microsoft hosts |

### 🎮 Gaming & FPS (6 tweaks)

| Tweak | Level | Description |
|---|---|---|
| Game Mode + HAGS | 🟢 Safe | AutoGameModeEnabled + HwSchMode=2 |
| Clear DirectX Shaders | 🟢 Safe | D3DSCache + NVIDIA/AMD cache |
| Remove Xbox Services | 🟡 Advanced | 5 Xbox AppxPackages |
| NVIDIA/AMD Registry Tweaks | 🟡 Advanced | PerfLevelSrc + PowerMizer |
| CPU Priority for Games | 🟢 Safe | Win32PrioritySeparation=38 |
| Disable Fullscreen Opt. | 🟢 Safe | GameDVR_FSEBehaviorMode=2 |

### 🛡️ Security (4 tweaks)

| Tweak | Level | Description |
|---|---|---|
| Update Defender Definitions | 🟢 Safe | Update-MpSignature + QuickScan |
| Configure UAC Level | 🟢 Safe | ConsentPromptBehaviorAdmin=5 |
| Enable Exploit Protection | 🟢 Safe | DEP + SEHOP via Set-Processmitigation |
| Disable RDP | 🟢 Safe | fDenyTSConnections=1 + Firewall rule |

### 🖥️ System & UI (6 tweaks)

| Tweak | Level | Description |
|---|---|---|
| Force Global Dark Mode | 🟢 Safe | AppsUseLightTheme=0 + explorer restart |
| Clean Taskbar | 🟢 Safe | TaskbarMn + ShowTaskViewButton off |
| Classic Context Menu | 🟢 Safe | CLSID InprocServer32 Win11 fix |
| NumLock on Startup | 🟢 Safe | InitialKeyboardIndicators=2 |
| Show File Extensions | 🟢 Safe | HideFileExt=0 + Hidden=1 |
| Configure Auto Updates | 🟢 Safe | AUOptions=2 (notify before download) |

---

## 🔌 PowerShell Backend — CLI API

`HT-Optimizer-Backend.ps1` is a full standalone execution engine:

```powershell
# Available parameters:
-Tweak         <string>   # Specific tweak ID to run
-RunAll                   # Run all 38 safe tweaks
-ExportReport             # Generate HTML report on Desktop
-SkipRestorePoint         # Skip automatic restore point creation
-Silent                   # No console output (log to file only)

# Available tweak IDs:
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

### Output Logs
```
%TEMP%\HT-Optimizer-Log.txt
%USERPROFILE%\Desktop\HT-Optimizer-Relatorio.html
```

---

## 🐍 Python Backend — REST API

```
Base URL: http://localhost:5050

GET  /                        → Serve dashboard (frontend/index.html)
GET  /api/health              → {"status": "ok", "version": "2.1"}
GET  /api/tweaks              → List all available tweaks
GET  /api/sysinfo             → CPU%, RAM%, disk, OS, uptime
POST /api/run/<tweak_id>      → Execute a tweak, returns JSON
GET  /api/stream/<tweak_id>   → SSE — real-time line-by-line PS output
POST /api/restore-point       → Create system restore point
GET  /api/history             → Execution history (SQLite)
```

### Python Dependencies

```
flask>=3.0.0
flask-cors>=4.0.0
psutil>=5.9.0
wmi>=1.5.1
pywin32>=306
```

---

## 🔐 Security

### Implemented Measures

| Area | Measure |
|---|---|
| XSS Frontend | All text inserted via `textContent` (never `innerHTML`) |
| Command Injection | Tweak IDs validated against a whitelist before execution |
| Privilege Escalation | Admin check before any system-level tweak |
| System Restore Point | Automatically created before advanced tweaks |
| PowerShell Execution | Scripts use `-NonInteractive -NoProfile` |
| No External Dependencies | Frontend loads no scripts from external CDNs |
| Audit Log | Every execution recorded with timestamp |

### Tweak Risk Levels

```
✅ Recommended  → Completely safe, easily reversible
🟢 Safe         → No negative impact in normal use
🟡 Advanced     → May affect system behavior, reversible via restore point
🔴 Danger       → (None — excluded by design for safety)
```

> **Never included:** disk formatting, system file deletion,
> main firewall disabling, or tweaks requiring safe mode.

---

## 📁 File Structure

```
WINDOWS OPTIMIZER/
│
├── 📄 README.md                        ← Portuguese documentation
├── 📄 README.en.md                     ← This file (English)
├── 🌐 index.html                       ← Main dashboard (1580+ lines)
├── 🎨 style.css                        ← Premium dark/light theme (800+ lines)
├── ⚙️  app.js                           ← Frontend logic (600+ lines)
├── 🔷 HT-Optimizer-Backend.ps1         ← PS standalone backend (750+ lines)
├── 🚫 .gitignore
│
├── 📂 frontend/
│   ├── index.html
│   ├── style.css
│   └── app.js
│
└── 📂 backend/
    ├── server.py                       ← Flask API server
    ├── tweaks_runner.py                ← PS executor + SSE streaming
    ├── sysinfo.py                      ← psutil + WMI metrics
    ├── requirements.txt
    └── 📂 scripts/
        ├── diagnostics.ps1
        ├── performance.ps1
        ├── privacy.ps1
        ├── cleanup.ps1
        ├── network.ps1
        ├── gaming.ps1
        ├── security.ps1
        └── system.ps1
```

---

## 🗺️ Roadmap

### v2.1 (Current)
- [x] Premium dashboard with 8 modules
- [x] 50+ tweaks organized by category
- [x] Light/dark theme with persistence (🌙/☀️ icon toggle)
- [x] Real-time technical terminal
- [x] Export .ps1 script
- [x] Full standalone PowerShell backend
- [x] Confirmation modal for advanced tweaks
- [x] Automatic restore point creation
- [x] Frontend / backend folder separation
- [x] Full bilingual documentation (PT + EN)

### v2.2 (Planned)
- [ ] Python Flask backend with real SSE streaming
- [ ] Real-time CPU/RAM/Disk via psutil
- [ ] Execution history log (SQLite)
- [ ] Optimization profiles (Gaming, Office, Server)
- [ ] Scheduled automatic cleanup
- [ ] Before/after benchmark comparison

### v3.0 (Future)
- [ ] Packaged as Electron or PyWebView desktop app
- [ ] Auto-update tweaks from GitHub
- [ ] Multi-machine support (LAN mode)
- [ ] Custom tweak plugin system

---

## 📊 Research & Sources

This project was built based on research from:

- **Chris Titus Tech WinUtil** — Registry tweaks and Windows services
- **Awesome Windows Tweaks (GitHub)** — Curated optimization compilation
- **CTT Tech Toolbox** — PowerShell optimization scripts 2025/2026
- **Microsoft Docs** — Win32 APIs, bcdedit, netsh, powercfg
- **FPS Benchmarks Community** — Gaming tweaks (HAGS, Timer Resolution)
- **Privacy Guides** — Telemetry removal and Recall AI opt-out
- **Bleeping Computer** — Cleanup and maintenance scripts
- **SS64.com PowerShell Reference** — Cmdlet syntax and parameters

---

## ⚖️ License

```
HT Technology — Windows Optimizer Pro
Copyright © 2026 HT Technology. All rights reserved.

This software is proprietary and intended for internal use by HT Technology.
Unauthorized redistribution is prohibited.
```

---

## 👨‍💻 Developed by

```
  ╔══════════════════════════════════╗
  ║       HT Technology              ║
  ║   Windows Optimizer Pro v2.1     ║
  ║      June 19, 2026               ║
  ╚══════════════════════════════════╝
```

> **Always create a System Restore Point before applying advanced tweaks.**
> If anything goes wrong, use `rstrui.exe` to roll back all changes.
