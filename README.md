<div align="center">

<img src="https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="Windows 10 | 11"/>
<img src="https://img.shields.io/badge/vers%C3%A3o-3.2-1877F2?style=for-the-badge" alt="v3.2"/>
<img src="https://img.shields.io/badge/licen%C3%A7a-MIT-7c3aed?style=for-the-badge" alt="MIT"/>
<img src="https://img.shields.io/badge/gratuito-%E2%9D%A4%EF%B8%8F-ef4444?style=for-the-badge" alt="Gratuito"/>

# 🖥️ HT Technology — Windows Optimizer Pro

**Uma ferramenta gratuita, segura e feita com carinho para a comunidade Windows.**  
*A free, safe tool made with care for the Windows community.*

[🇧🇷 Português](#-sobre-o-projeto) · [🇺🇸 English](#-about-the-project) · [📥 Download](#-como-usar--how-to-use)

</div>

---

## 🇧🇷 Sobre o Projeto

O **Windows Optimizer Pro** nasceu de uma necessidade simples: deixar o Windows mais rápido, mais privado e mais limpo — sem precisar ser um especialista em informática.

Desenvolvido pela **HT Technology**, este projeto é **100% gratuito e de código aberto**. Não vendemos nada, não coletamos dados, não instalamos nada no seu computador. É apenas uma página HTML que gera scripts PowerShell que você mesmo revisa e executa.

### ✨ Para quem é esse app?

- 🎮 **Gamers** que querem extrair cada frame possível do seu hardware
- 💼 **Profissionais** que precisam de mais privacidade e menos distrações
- 🧹 **Usuários comuns** que querem um Windows mais limpo e responsivo
- 🛠️ **Técnicos de TI** que precisam padronizar configurações em múltiplas máquinas

### 🔒 É seguro?

Sim. Todos os tweaks são exibidos em tela antes de serem executados. Tweaks avançados pedem confirmação. O app cria um **Ponto de Restauração** antes de qualquer alteração. Você sempre pode voltar atrás.

### 🚀 O que você pode fazer

| Módulo | O que faz |
|--------|-----------|
| 🔧 **Diagnóstico** | Reparo do sistema, SFC/DISM, ChkDsk, limpeza de cache |
| ⚡ **Performance** | Plano Ultimate Performance, HAGS, Timer Resolution, visual otimizado |
| 🔒 **Privacidade** | Desativa telemetria, Recall AI, Copilot, rastreamento e anúncios |
| 🧹 **Limpeza** | Remove arquivos temporários, WinSxS, cache de navegadores |
| 🌐 **Rede & DNS** | DNS Cloudflare (DoH), TCP Auto-Tuning, firewall anti-telemetria |
| 🎮 **Gaming** | Game Mode, DirectX, GPU tweaks, FSO, prioridade de CPU |
| 🛡️ **Segurança** | UAC, Exploit Protection, Defender, desativa RDP |
| ⚙️ **Sistema** | Modo escuro, menu clássico, barra de tarefas limpa, extensões visíveis |
| 🎯 **Perfis** | Aplique um conjunto de tweaks com 1 clique: Gaming, Office ou Servidor |
| 📦 **Winget Store** | Instale seus apps favoritos diretamente pelo dashboard |
| 📊 **Análise** | Score de saúde do sistema com recomendações personalizadas |
| 🗓️ **Agendador** | Configure limpezas automáticas semanais, mensais ou diárias |

---

## 🇺🇸 About the Project

**Windows Optimizer Pro** was born from a simple need: make Windows faster, more private, and cleaner — without needing to be a tech expert.

Built by **HT Technology**, this project is **100% free and open-source**. We don't sell anything, don't collect your data, and don't install anything on your computer. It's just an HTML page that generates PowerShell scripts you can review and run yourself.

### ✨ Who is this app for?

- 🎮 **Gamers** who want to squeeze every frame out of their hardware
- 💼 **Professionals** who need more privacy and fewer distractions
- 🧹 **Regular users** who want a cleaner, more responsive Windows
- 🛠️ **IT Technicians** who need to standardize settings across multiple machines

### 🔒 Is it safe?

Yes. All tweaks are shown on screen before being executed. Advanced tweaks require confirmation. The app creates a **System Restore Point** before any changes. You can always go back.

### 🚀 What you can do

| Module | What it does |
|--------|-------------|
| 🔧 **Diagnostics** | System repair, SFC/DISM, ChkDsk, cache cleanup |
| ⚡ **Performance** | Ultimate Performance plan, HAGS, Timer Resolution, visual tweaks |
| 🔒 **Privacy** | Disable telemetry, Recall AI, Copilot, tracking and ads |
| 🧹 **Cleanup** | Remove temp files, WinSxS, browser cache |
| 🌐 **Network & DNS** | Cloudflare DNS (DoH), TCP Auto-Tuning, anti-telemetry firewall |
| 🎮 **Gaming** | Game Mode, DirectX, GPU tweaks, FSO, CPU priority |
| 🛡️ **Security** | UAC, Exploit Protection, Defender update, disable RDP |
| ⚙️ **System** | Dark mode, classic context menu, clean taskbar, file extensions |
| 🎯 **Profiles** | Apply a full set of tweaks in 1 click: Gaming, Office or Server |
| 📦 **Winget Store** | Install your favorite apps directly from the dashboard |
| 📊 **Analysis** | System health score with personalized recommendations |
| 🗓️ **Scheduler** | Set up automatic weekly, monthly or daily cleanups |

---

## 📥 Como Usar / How to Use

```
1. Clone ou baixe este repositório / Clone or download this repository
2. Abra o arquivo index.html no navegador / Open index.html in your browser
3. Selecione os tweaks desejados / Select the desired tweaks
4. Clique em "Executar Agora" ou "Exportar .ps1" / Click "Run Now" or "Export .ps1"
5. Execute o script como Administrador / Run the script as Administrator
```

> **Dica / Tip:** Sempre crie um Ponto de Restauração antes de tweaks avançados.  
> *Always create a System Restore Point before advanced tweaks.*

---

## 🏗️ Estrutura / Structure

```
windows-optimizer/
├── index.html              ← Dashboard principal / Main dashboard
├── style.css               ← Estilos do dashboard / Dashboard styles
├── app.js                  ← Lógica do dashboard / Dashboard logic
├── HT-Optimizer-Backend.ps1 ← Backend PowerShell com todos os tweaks
├── backend/                ← Módulos e scripts auxiliares
├── README.md               ← Este arquivo / This file
├── README.pt-br.md         ← Documentação completa em PT-BR
└── README.en.md            ← Full documentation in English
```

---

## 🤝 Contribuindo / Contributing

Contribuições são muito bem-vindas! / Contributions are very welcome!

1. Faça um fork do projeto / Fork the project
2. Crie sua branch de feature / Create your feature branch (`git checkout -b feature/NomeDaFeature`)
3. Commit suas mudanças / Commit your changes (`git commit -m 'feat: descrição'`)
4. Push para a branch / Push to the branch (`git push origin feature/NomeDaFeature`)
5. Abra um Pull Request / Open a Pull Request

---

## 📖 Documentação Completa / Full Documentation

- 🇧🇷 [Documentação em Português](README.pt-br.md)
- 🇺🇸 [English Documentation](README.en.md)

---

## ⚖️ Licença / License

MIT License — use, modifique e distribua à vontade, com créditos.  
*MIT License — use, modify and distribute freely, with credits.*

---

<div align="center">

**Feito com dedicação pela HT Technology para a comunidade Windows**  
*Made with dedication by HT Technology for the Windows community*

[![GitHub Stars](https://img.shields.io/github/stars/leizem/windows-optimizer?style=social)](https://github.com/leizem/windows-optimizer)

</div>
