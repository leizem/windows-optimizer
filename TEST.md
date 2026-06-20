# 🧪 HT Technology — Windows Optimizer Pro v3.0
## Guia de Testes em VM com Windows 11 Instalação Limpa
### Test Guide on a Clean Windows 11 VM

**Versão do documento / Document version:** 1.0 · 20/06/2026  
**Aplicável a / Applies to:** `HT-Technology-WindowsOptimizer-Pro-v3.0.msi`  
**Ambiente alvo / Target environment:** Windows 11 22H2 ou superior (instalação limpa)

---

## 📋 Índice / Table of Contents

1. [Pré-requisitos da VM](#1-pré-requisitos-da-vm--vm-prerequisites)
2. [Preparação do Ambiente](#2-preparação-do-ambiente--environment-preparation)
3. [Testes do Instalador (.msi)](#3-testes-do-instalador-msi--installer-tests)
4. [Testes Funcionais do Dashboard](#4-testes-funcionais-do-dashboard--dashboard-functional-tests)
5. [Testes de Tweaks por Categoria](#5-testes-de-tweaks-por-categoria--tweaks-tests-by-category)
6. [Testes de Segurança e Estabilidade](#6-testes-de-segurança-e-estabilidade--security--stability-tests)
7. [Testes de Desinstalação](#7-testes-de-desinstalação--uninstall-tests)
8. [Checklist Final de Release](#8-checklist-final-de-release--final-release-checklist)

---

## 1. Pré-requisitos da VM / VM Prerequisites

### Especificações Mínimas da VM / Minimum VM Specs

| Componente | Mínimo | Recomendado |
|---|---|---|
| **CPU** | 2 vCPU | 4 vCPU |
| **RAM** | 4 GB | 8 GB |
| **Disco** | 60 GB (sistema) | 80 GB |
| **GPU** | Qualquer / Any | NVIDIA/AMD para testes de gaming |
| **Rede** | Conectada | Conectada (para winget) |
| **Hipervisor** | VMware / Hyper-V / VirtualBox | VMware Workstation 17+ |

### Sistema Operacional / Operating System

```
Windows 11 Pro ou Home (instalação limpa / clean install)
Versão mínima: 22H2 (Build 22621)
Versão recomendada: 23H2 ou 24H2 (Build 22631+)
Idioma: Português (Brasil) OU English (United States)
Conta: Conta local de Administrador (sem conta Microsoft)
```

> **⚠️ IMPORTANTE:** Use sempre uma **snapshot limpa antes de cada bateria de testes**.  
> *Always use a **clean snapshot before each test battery**.*

### Ferramentas necessárias na VM / Required tools in VM

- [ ] Windows PowerShell 5.1 (nativo no Windows 11)
- [ ] Microsoft Edge ou Chrome instalado
- [ ] `winget` disponível (nativo no Windows 11 22H2+)
- [ ] UAC **Habilitado** (nível padrão)

---

## 2. Preparação do Ambiente / Environment Preparation

### 2.1 Criar Snapshot Limpa / Create Clean Snapshot

```
1. Instale o Windows 11 na VM (instalação limpa)
2. Finalize o OOBE (primeira configuração)
3. Instale as VMware Tools / Guest Additions
4. Execute Windows Update e reinicie
5. CRIE UMA SNAPSHOT: "Base Limpa v3.0 - Pre-Install"
```

### 2.2 Copiar o MSI para a VM / Copy MSI to VM

```
Origem (Host): dist\HT-Technology-WindowsOptimizer-Pro-v3.0.msi
Destino (VM) : C:\Users\<usuario>\Downloads\
```

### 2.3 Verificar integridade do arquivo / Verify file integrity

Abra o PowerShell na VM e execute:

```powershell
# Verifica o hash SHA256 do MSI
Get-FileHash "C:\Users\$env:USERNAME\Downloads\HT-Technology-WindowsOptimizer-Pro-v3.0.msi" -Algorithm SHA256
```

> **Anote o hash** e compare com o hash publicado no GitHub Releases.  
> *Note the hash and compare with the hash published on GitHub Releases.*

---

## 3. Testes do Instalador (.msi) / Installer Tests

### TC-INST-01 — Instalação Padrão (Caminho Default)

**Objetivo:** Verificar que o instalador funciona com todas as configurações padrão.

```
1. Dê duplo clique em HT-Technology-WindowsOptimizer-Pro-v3.0.msi
2. Clique em "Próximo" na tela de boas-vindas
3. Leia e aceite o contrato de licença (MIT)
4. NA TELA DE PASTA: deixe o caminho padrão (C:\Program Files\...)
5. Clique em "Próximo" → "Instalar"
6. Aguarde a instalação completar
7. Verifique se a checkbox "Abrir guia de boas-vindas" está marcada
8. Clique em "Concluir"
```

**Resultados Esperados:**

- [ ] Diálogos PT-BR exibidos corretamente (ou EN se sistema em inglês)
- [ ] Banner e imagem lateral do instalador exibidos corretamente
- [ ] Licença MIT exibida no diálogo de EULA
- [ ] Campo de pasta destino editável com caminho padrão: `C:\Program Files\HT Technology\Windows Optimizer Pro\`
- [ ] Barra de progresso avança sem erros
- [ ] **Welcome.html abre automaticamente no navegador ao concluir**
- [ ] Atalho criado na Área de Trabalho: "Windows Optimizer Pro"
- [ ] Grupo criado no Menu Iniciar: "HT Technology Windows Optimizer Pro"
- [ ] App aparece em: Configurações → Aplicativos → "HT Technology Windows Optimizer Pro"

---

### TC-INST-02 — Instalação em Pasta Personalizada ⭐

**Objetivo:** Garantir que o usuário pode instalar em qualquer pasta.

```
1. Inicie a instalação do MSI
2. Aceite a licença
3. NA TELA DE PASTA: clique em "Alterar..."
4. Navegue até: D:\MinhaPastaCustom\HT-Optimizer\
   (crie a pasta se necessário)
5. Confirme e clique em "Próximo" → "Instalar"
6. Conclua a instalação
```

**Resultados Esperados:**

- [ ] Campo "Pasta de Destino" é editável
- [ ] Botão "Alterar..." abre seletor de pasta do Windows
- [ ] Instalação ocorre em `D:\MinhaPastaCustom\HT-Optimizer\`
- [ ] Atalho no Desktop aponta para o caminho correto
- [ ] Welcome.html abre da pasta correta
- [ ] Registro `HKLM\SOFTWARE\HTTechnology\WindowsOptimizerPro\InstallPath` contém o caminho personalizado

```powershell
# Verificar no registro
Get-ItemProperty "HKLM:\SOFTWARE\HTTechnology\WindowsOptimizerPro" | Select InstallPath
```

---

### TC-INST-03 — Instalação via Linha de Comando (Silent)

**Objetivo:** Verificar instalação silenciosa para cenários corporativos.

```powershell
# Instalação silenciosa (sem UI) na pasta padrão
msiexec /i "HT-Technology-WindowsOptimizer-Pro-v3.0.msi" /qn

# Instalação silenciosa em pasta personalizada
msiexec /i "HT-Technology-WindowsOptimizer-Pro-v3.0.msi" /qn INSTALLDIR="C:\HT-Optimizer\"

# Instalação com log detalhado
msiexec /i "HT-Technology-WindowsOptimizer-Pro-v3.0.msi" /l*v "C:\install-log.txt"
```

**Resultados Esperados:**

- [ ] Instalação silenciosa conclui sem janelas
- [ ] Arquivos instalados no caminho correto
- [ ] Atalhos criados
- [ ] Log gerado sem erros FATAL

---

### TC-INST-04 — Upgrade de Versão Anterior

**Objetivo:** Verificar que a instalação sobre uma versão anterior funciona.

```
1. Instale uma versão anterior (se disponível) ou reinstale a v3.0
2. Execute o MSI v3.0 novamente
3. O instalador deve remover a versão anterior e instalar a nova
```

**Resultados Esperados:**

- [ ] Não exige desinstalação manual da versão anterior
- [ ] Arquivos novos sobrescrevem os antigos
- [ ] Registro atualizado com nova versão

---

## 4. Testes Funcionais do Dashboard / Dashboard Functional Tests

### TC-DASH-01 — Abertura do Dashboard

```
1. Clique no atalho "Windows Optimizer Pro" na Área de Trabalho
2. Aguarde o navegador abrir index.html
```

**Resultados Esperados:**

- [ ] Dashboard carrega completamente em < 3 segundos
- [ ] Sem erros no console do navegador (F12 → Console)
- [ ] Logo "HT Technology" e badge "v3.0" visíveis
- [ ] Sidebar com todas as abas: Início, Tweaks, Perfis, Winget Store, Análise, Agendador
- [ ] Tema escuro aplicado corretamente

---

### TC-DASH-02 — Navegação entre Abas

```
Clique em cada aba e verifique:
- Início (Home)
- Tweaks
- Perfis
- Winget Store
- Análise do Sistema
- Agendador
```

**Resultados Esperados:**

- [ ] Todas as 6 abas respondem ao clique
- [ ] Conteúdo de cada aba carrega sem erro
- [ ] Animações de transição funcionam
- [ ] Sem travamentos ou erros visuais

---

### TC-DASH-03 — Busca de Tweaks

```
1. Vá para a aba "Tweaks"
2. Digite "telemetria" no campo de busca
3. Verifique que os tweaks relacionados aparecem
4. Limpe o campo e verifique que todos os tweaks voltam a aparecer
```

**Resultados Esperados:**

- [ ] Filtro funciona em tempo real (sem precisar apertar Enter)
- [ ] Resultados mostram tweaks com nome/descrição/tags correspondentes
- [ ] Limpar o campo restaura a lista completa

---

### TC-DASH-04 — Exportar Script PowerShell

```
1. Selecione 3 tweaks de categorias diferentes
2. Clique em "Exportar .ps1"
3. Salve o arquivo gerado
4. Abra o arquivo no Notepad e verifique o conteúdo
```

**Resultados Esperados:**

- [ ] Arquivo `.ps1` é gerado corretamente
- [ ] Script contém os tweaks selecionados
- [ ] Encoding UTF-8 BOM (abre sem caracteres estranhos)
- [ ] Comentários PT-BR no script

---

### TC-DASH-05 — Changelog Interativo

```
1. Clique no botão "Changelog" no header
2. Verifique o modal com histórico de versões
```

**Resultados Esperados:**

- [ ] Modal abre com animação
- [ ] Versões v2.1, v2.2 e v3.0 listadas
- [ ] Botão fechar (X) funciona

---

## 5. Testes de Tweaks por Categoria / Tweaks Tests by Category

> **⚠️ IMPORTANTE:** Sempre use a snapshot "Base Limpa" antes deste bloco.  
> Execute os tweaks via "Executar Agora" e verifique o resultado.

### TC-TWEAK-01 — Tweaks de Sistema (Safe)

| Tweak | Comando de verificação | Resultado Esperado |
|---|---|---|
| **Dark Mode** | `Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme` | `0` |
| **Menu Clássico** | `Get-ItemProperty "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(default)"` | `""` (vazio) |
| **NumLock on** | `Get-ItemProperty "HKCU:\Control Panel\Keyboard" -Name InitialKeyboardIndicators` | `2` |
| **Mostrar extensões** | `Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt` | `0` |

### TC-TWEAK-02 — Tweaks de Privacidade

| Tweak | Verificação | Resultado Esperado |
|---|---|---|
| **Telemetria** | `Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry` | `0` |
| **Recall AI** | `Get-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name DisableAIDataAnalysis` | `1` |
| **Advertising ID** | `Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled` | `0` |

### TC-TWEAK-03 — Tweaks de Performance

```powershell
# Verificar Plano de Energia
powercfg /getactivescheme

# Verificar SysMain (Superfetch)
Get-Service SysMain | Select-Object Status, StartType
```

**Resultados Esperados:**

- [ ] Plano "Alto desempenho" ou "Ultimate Performance" ativo
- [ ] SysMain: `Status=Stopped, StartType=Disabled`

### TC-TWEAK-04 — Tweaks Lentos (Limpeza e Reparo)

> Esses tweaks podem levar 5–30 minutos. Execute individualmente.

| Tweak | Duração Esperada | Resultado |
|---|---|---|
| `reparo_rapido` | 3–10 min | Libera espaço em disco |
| `sfc_dism` | 3–8 min | "Proteção de Recursos do Windows não encontrou nenhuma violação de integridade" |
| `winsxs` | 1–5 min | Limpa componentes obsoletos |
| `defender_update` | ⚠️ Requer internet com MS Update | Pode expirar em VMs sem acesso direto |

### TC-TWEAK-05 — Perfis de Otimização

```
1. Vá para aba "Perfis"
2. Selecione "Gaming Pro"
3. Clique em "Aplicar Perfil"
4. Verifique que os tweaks correspondentes foram aplicados
```

**Resultados Esperados:**

- [ ] Perfil Gaming: Game Mode, HAGS, CPU Priority, FSO ativados
- [ ] Perfil Office: Privacidade, tema, fonte de sistema otimizados
- [ ] Perfil Servidor: serviços desnecessários desativados

---

## 6. Testes de Segurança e Estabilidade / Security & Stability Tests

### TC-SEC-01 — Ponto de Restauração

```
1. Execute o tweak "Criar Ponto de Restauração"
2. Verifique no Painel de Controle → Recuperação → Restaurar o Sistema
```

**Resultados Esperados:**

- [ ] Ponto de restauração "HT Optimizer" criado com data/hora atual

---

### TC-SEC-02 — Verificação Pós-Reboot

```
1. Reinicie a VM (não restore — reinicialização normal)
2. Após login, abra o PowerShell e verifique os tweaks aplicados:
```

```powershell
# Script de verificação pós-reboot
$checks = @(
    @{ Name="Dark Mode";       Key="HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Prop="AppsUseLightTheme"; Expected=0 },
    @{ Name="IPv6 Disable";    Key="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"; Prop="DisabledComponents"; Expected=255 },
    @{ Name="GameMode";        Key="HKCU:\Software\Microsoft\GameBar"; Prop="AllowAutoGameMode"; Expected=1 },
    @{ Name="Telemetria Off";  Key="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Prop="AllowTelemetry"; Expected=0 }
)
foreach ($c in $checks) {
    try {
        $val = (Get-ItemProperty $c.Key -Name $c.Prop -EA Stop).$($c.Prop)
        $ok  = if ($val -eq $c.Expected) { "OK" } else { "FALHOU (valor=$val)" }
        Write-Host "[$ok] $($c.Name)"
    } catch {
        Write-Host "[ERRO] $($c.Name) — chave nao encontrada"
    }
}
```

**Resultados Esperados:**

- [ ] Todos os tweaks persistem após reboot
- [ ] Nenhum BSOD durante o boot
- [ ] Sistema inicia normalmente em < 60 segundos

---

### TC-SEC-03 — Verificação de BSOD

```powershell
# Verificar dumps de BSOD
$dumps = Get-ChildItem "C:\Windows\Minidump" -ErrorAction SilentlyContinue
if ($dumps) {
    Write-Host "DUMPS ENCONTRADOS:" -ForegroundColor Red
    $dumps | Select FullName, LastWriteTime
} else {
    Write-Host "[OK] Nenhum dump de BSOD encontrado." -ForegroundColor Green
}

# Verificar eventos de crash
Get-WinEvent -FilterHashtable @{LogName='System'; Level=1; StartTime=(Get-Date).AddDays(-1)} -EA SilentlyContinue |
    Select TimeCreated, Id, Message | Format-Table -Wrap
```

**Resultado Esperado:**

- [ ] `Nenhum dump de BSOD encontrado`
- [ ] Nenhum evento de nível Critical no log do sistema

---

### TC-SEC-04 — Segurança do Dashboard (XSS)

```
1. Abra o Dashboard no navegador
2. Na busca de tweaks, tente injetar: <script>alert('xss')</script>
3. Verifique que nenhum alert aparece
```

**Resultado Esperado:**

- [ ] O texto é exibido como literal, sem execução de script (proteção via `textContent`)

---

## 7. Testes de Desinstalação / Uninstall Tests

### TC-UNINST-01 — Desinstalação via Configurações

```
1. Configurações → Aplicativos → "HT Technology Windows Optimizer Pro"
2. Clique em "Desinstalar"
3. Confirme
```

**Resultados Esperados:**

- [ ] Processo de desinstalação inicia sem erros
- [ ] Barra de progresso avança normalmente
- [ ] App removido de Configurações → Aplicativos
- [ ] Atalho removido da Área de Trabalho
- [ ] Pasta do Menu Iniciar removida
- [ ] Pasta de instalação removida (ou vazia se o usuário criou arquivos)

---

### TC-UNINST-02 — Desinstalação via Linha de Comando

```powershell
# Obtém o ProductCode do registro
$productCode = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" |
    Get-ItemProperty | Where-Object { $_.DisplayName -like "*Windows Optimizer Pro*" }).PSChildName

# Desinstalação silenciosa
msiexec /x $productCode /qn

Write-Host "ProductCode: $productCode"
```

**Resultados Esperados:**

- [ ] Desinstalação silenciosa funciona
- [ ] Chaves de registro `HKLM\SOFTWARE\HTTechnology` removidas
- [ ] Nenhum arquivo residual em `C:\Program Files\HT Technology\`

---

## 8. Checklist Final de Release / Final Release Checklist

Use esta lista antes de tornar o repositório público:

### ✅ Instalador

- [ ] TC-INST-01: Instalação padrão — PASSOU
- [ ] TC-INST-02: Pasta personalizada — PASSOU
- [ ] TC-INST-03: Instalação silenciosa — PASSOU
- [ ] TC-INST-04: Upgrade — PASSOU
- [ ] Checksum SHA256 publicado no GitHub Releases

### ✅ Dashboard

- [ ] TC-DASH-01: Abertura — PASSOU
- [ ] TC-DASH-02: Navegação — PASSOU
- [ ] TC-DASH-03: Busca — PASSOU
- [ ] TC-DASH-04: Exportar .ps1 — PASSOU
- [ ] TC-DASH-05: Changelog — PASSOU

### ✅ Tweaks

- [ ] TC-TWEAK-01: Sistema — PASSOU
- [ ] TC-TWEAK-02: Privacidade — PASSOU
- [ ] TC-TWEAK-03: Performance — PASSOU
- [ ] TC-TWEAK-04: Tweaks lentos — PASSOU (exceto `defender_update` em VM)
- [ ] TC-TWEAK-05: Perfis — PASSOU

### ✅ Segurança e Estabilidade

- [ ] TC-SEC-01: Ponto de Restauração — PASSOU
- [ ] TC-SEC-02: Persistência pós-reboot — PASSOU
- [ ] TC-SEC-03: Zero BSODs — PASSOU
- [ ] TC-SEC-04: Proteção XSS — PASSOU

### ✅ Desinstalação

- [ ] TC-UNINST-01: Via Configurações — PASSOU
- [ ] TC-UNINST-02: Silenciosa — PASSOU

---

## 📝 Registro de Resultados / Results Log

Preencha durante os testes:

| Data | Testador | VM | OS Build | TC | Resultado | Observação |
|---|---|---|---|---|---|---|
| | | | | | | |

---

## 🐛 Reportar Problemas / Report Issues

Encontrou um problema durante os testes?

- **GitHub Issues:** https://github.com/leizem/windows-optimizer/issues
- **Template:** Informe o TC#, OS Build, mensagem de erro e passos para reproduzir

---

*HT Technology Windows Optimizer Pro v3.0*  
*Feito com dedicação para a comunidade Windows — Made with dedication for the Windows community*  
*github.com/leizem/windows-optimizer*
