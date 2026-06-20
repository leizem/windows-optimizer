# 🛡️ Política de Segurança / Security Policy

## 🇧🇷 Reportar uma Vulnerabilidade

Se você encontrou um problema de segurança neste projeto, por favor **não** abra uma Issue pública. Em vez disso, entre em contato diretamente pelo GitHub.

**O que consideramos como vulnerabilidade:**
- Script PowerShell que cause dano não documentado ao sistema
- Injeção de comandos através da interface
- Comportamento destrutivo sem aviso prévio ao usuário

**O que fazemos quando recebemos um relatório:**
- Confirmamos o recebimento em até 48h
- Investigamos e corrigimos na próxima versão de patch
- Creditamos o pesquisador (se desejar)

---

## 🇺🇸 Reporting a Vulnerability

If you found a security issue in this project, please **do not** open a public Issue. Instead, contact us directly through GitHub.

**What we consider a vulnerability:**
- A PowerShell script that causes undocumented damage to the system
- Command injection through the interface
- Destructive behavior without prior user warning

**What we do when we receive a report:**
- We confirm receipt within 48 hours
- We investigate and fix in the next patch version
- We credit the researcher (if desired)

---

## ✅ Design de Segurança / Security Design

Este projeto foi projetado com segurança em mente:

- **XSS-safe**: todo texto inserido na UI usa `textContent` (nunca `innerHTML`)
- **Confirmação obrigatória**: tweaks avançados sempre pedem confirmação do usuário
- **Ponto de Restauração**: criado automaticamente antes de alterações
- **Código aberto**: todos os scripts PowerShell são visíveis e auditáveis
- **Sem servidor**: roda inteiramente offline, sem enviar dados para nenhum servidor
- **Sem instalação**: apenas abra `index.html` no navegador

*This project was designed with security in mind. All PowerShell scripts are fully visible and auditable. No data is ever sent to any server.*
