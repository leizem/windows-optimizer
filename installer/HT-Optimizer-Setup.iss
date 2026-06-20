; ============================================================
;  HT Technology — Windows Optimizer Pro v3.0
;  Inno Setup Script
;  Bilingual: Portuguese (Brazil) + English
; ============================================================

#define AppName      "Windows Optimizer Pro"
#define AppVersion   "3.0.0"
#define AppPublisher "HT Technology"
#define AppURL       "https://github.com/leizem/windows-optimizer"
#define AppExeName   "Launch-HT-Optimizer.bat"
#define AppGUID      "{A7B3C2D1-E4F5-6789-ABCD-EF1234567890}"

[Setup]
; ── Identidade ────────────────────────────────────────────
AppId                     = {{#AppGUID}
AppName                   = {#AppName}
AppVersion                = {#AppVersion}
AppVerName                = {#AppPublisher} {#AppName} v{#AppVersion}
AppPublisher              = {#AppPublisher}
AppPublisherURL           = {#AppURL}
AppSupportURL             = {#AppURL}/issues
AppUpdatesURL             = {#AppURL}/releases
VersionInfoVersion        = 3.0.0.0
VersionInfoCompany        = HT Technology
VersionInfoDescription    = HT Technology Windows Optimizer Pro — Dashboard de otimizacao para Windows 10/11
VersionInfoCopyright      = Copyright (C) 2026 HT Technology

; ── Instalação ────────────────────────────────────────────
DefaultDirName            = {autopf}\HT Technology\Windows Optimizer Pro
DefaultGroupName          = HT Technology\Windows Optimizer Pro
AllowNoIcons              = no
DisableProgramGroupPage   = auto
OutputDir                 = ..\dist
OutputBaseFilename        = HT-Technology-WindowsOptimizer-Pro-v3.0-Setup
SetupIconFile             = assets\icon.ico
Compression               = lzma2/ultra64
SolidCompression          = yes
InternalCompressLevel     = ultra64
WizardStyle               = modern
WizardResizable           = yes

; ── Requisitos ────────────────────────────────────────────
MinVersion                = 10.0.17763
; Requer Windows 10 1809 ou superior / Requires Windows 10 1809 or later
ArchitecturesAllowed      = x64compatible
ArchitecturesInstallIn64BitMode = x64compatible
PrivilegesRequired        = admin
PrivilegesRequiredOverridesAllowed = dialog

; ── Aparência ─────────────────────────────────────────────
WizardImageFile           = assets\wizard-sidebar.bmp
WizardSmallImageFile      = assets\wizard-header.bmp

; ── Desinstalação ─────────────────────────────────────────
UninstallDisplayIcon      = {app}\Launch-HT-Optimizer.bat
UninstallDisplayName      = {#AppPublisher} {#AppName} v{#AppVersion}
CreateUninstallRegKey     = yes

[Languages]
; Português (Brasil) como padrão, inglês como alternativa
Name: "ptbr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "en";   MessagesFile: "compiler:Default.isl"

[CustomMessages]
; ── Português ─────────────────────────────────────────────
ptbr.WelcomeLabel1=Bem-vindo ao instalador do%n{#AppPublisher} {#AppName} v{#AppVersion}
ptbr.WelcomeLabel2=Este assistente instalará o {#AppName} no seu computador.%n%nUma ferramenta gratuita e segura para otimizar, limpar e melhorar a privacidade do seu Windows 10 ou 11.%n%nFechando outros aplicativos antes de continuar é recomendável.
ptbr.FinishedLabel=O {#AppName} foi instalado com sucesso no seu computador!%n%nClique em Concluir para fechar este assistente e ver o guia de boas-vindas com instruções de uso em Português e Inglês.
ptbr.DesktopIconLabel=Criar atalho na Área de Trabalho
ptbr.LaunchAppLabel=Abrir guia de boas-vindas ao finalizar
ptbr.AppDescLabel=Dashboard premium de otimizacao para Windows 10 e 11

; ── English ───────────────────────────────────────────────
en.WelcomeLabel1=Welcome to the {#AppPublisher}%n{#AppName} v{#AppVersion} Setup Wizard
en.WelcomeLabel2=This wizard will install {#AppName} on your computer.%n%nA free and safe tool to optimize, clean, and improve the privacy of your Windows 10 or 11.%n%nIt is recommended that you close all other applications before continuing.
en.FinishedLabel={#AppName} has been successfully installed on your computer!%n%nClick Finish to close this wizard and view the welcome guide with usage instructions in Portuguese and English.
en.DesktopIconLabel=Create a Desktop shortcut
en.LaunchAppLabel=Open welcome guide when done
en.AppDescLabel=Premium optimization dashboard for Windows 10 and 11

[Tasks]
; Atalho na Área de Trabalho — ativado por padrão
Name: "desktopicon"; Description: "{cm:DesktopIconLabel}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
; ── Arquivos principais do app ────────────────────────────
Source: "..\index.html";                DestDir: "{app}"; Flags: ignoreversion
Source: "..\style.css";                 DestDir: "{app}"; Flags: ignoreversion
Source: "..\app.js";                    DestDir: "{app}"; Flags: ignoreversion
Source: "..\HT-Optimizer-Backend.ps1";  DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.md";                 DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.pt-br.md";           DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.en.md";              DestDir: "{app}"; Flags: ignoreversion
Source: "..\SECURITY.md";               DestDir: "{app}"; Flags: ignoreversion
Source: "..\CONTRIBUTING.md";           DestDir: "{app}"; Flags: ignoreversion

; ── Launcher ──────────────────────────────────────────────
Source: "Launch-HT-Optimizer.bat";      DestDir: "{app}"; Flags: ignoreversion

; ── Welcome/README bilingue (aberto no final da instalação)
Source: "Welcome.html";                 DestDir: "{app}"; Flags: ignoreversion

; ── Backend e subpastas ───────────────────────────────────
Source: "..\backend\*";                 DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; ── Menu Iniciar ──────────────────────────────────────────
Name: "{group}\{#AppName}";            Filename: "{app}\Launch-HT-Optimizer.bat"; WorkingDir: "{app}"; Comment: "{cm:AppDescLabel}"
Name: "{group}\Boas-vindas (Welcome)"; Filename: "{app}\Welcome.html";            WorkingDir: "{app}"; Comment: "Guia de uso / Usage guide"
Name: "{group}\Desinstalar (Uninstall)"; Filename: "{uninstallexe}"

; ── Área de Trabalho ──────────────────────────────────────
Name: "{autodesktop}\{#AppName}";      Filename: "{app}\Launch-HT-Optimizer.bat"; WorkingDir: "{app}"; Tasks: desktopicon; Comment: "{cm:AppDescLabel}"

[Run]
; ── Abre o Welcome.html ao final da instalação ────────────
Filename: "{app}\Welcome.html"; Description: "{cm:LaunchAppLabel}"; Flags: nowait postinstall shellexec skipifsilent

[Registry]
; ── Registra o app no "Aplicativos instalados" ────────────
Root: HKLM; Subkey: "Software\HTTechnology\WindowsOptimizerPro"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\HTTechnology\WindowsOptimizerPro"; ValueType: string; ValueName: "Version";     ValueData: "{#AppVersion}"
Root: HKLM; Subkey: "Software\HTTechnology\WindowsOptimizerPro"; ValueType: string; ValueName: "Publisher";   ValueData: "{#AppPublisher}"

[UninstallDelete]
; ── Remove pasta residual ao desinstalar ──────────────────
Type: filesandordirs; Name: "{app}"

[Code]
// ──────────────────────────────────────────────────────────
//  Mensagens customizadas de boas-vindas e conclusão
// ──────────────────────────────────────────────────────────
function GetWelcomeLabel1(Default: String): String;
begin
  if ActiveLanguage = 'ptbr' then
    Result := ExpandConstant('Bem-vindo ao instalador do'#13#10'{#AppPublisher} {#AppName} v{#AppVersion}')
  else
    Result := ExpandConstant('Welcome to the {#AppPublisher}'#13#10'{#AppName} v{#AppVersion} Setup Wizard');
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Log de conclusão para rastreabilidade
    Log('HT Technology Windows Optimizer Pro v{#AppVersion} installed successfully.');
    Log('Install path: ' + ExpandConstant('{app}'));
  end;
end;
