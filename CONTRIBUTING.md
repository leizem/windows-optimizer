# 🤝 Como Contribuir / How to Contribute

Obrigado pelo interesse em contribuir com o **HT Technology Windows Optimizer Pro**!  
*Thank you for your interest in contributing to **HT Technology Windows Optimizer Pro**!*

---

## 🇧🇷 Guia de Contribuição

### Tipos de contribuição bem-vindos

- 🐛 **Bug reports** — Encontrou algo errado? Abra uma Issue!
- 💡 **Novos tweaks** — Conhece um tweak seguro e útil? Proponha via PR!
- 🌍 **Traduções** — Quer adicionar suporte a outro idioma?
- 📝 **Documentação** — Melhorias no README e na documentação são sempre bem-vindas
- 🎨 **Design** — Sugestões de UI/UX são muito apreciadas

### Antes de abrir um PR

1. Verifique se já existe uma Issue ou PR com o mesmo tema
2. Para novos tweaks, descreva: **o que faz**, **por que é útil**, **qual é o risco** e **como reverter**
3. Mantenha o estilo de código existente (JavaScript vanilla, sem dependências externas)
4. Teste localmente abrindo `index.html` no navegador

### Padrão de commit

```
feat: adiciona tweak de X
fix: corrige comportamento de Y
docs: atualiza README com Z
style: melhora visual do painel W
```

### Tweaks: regras de ouro

- ✅ Todo tweak deve ter `label`, `safe` (boolean) e `ps` (script PowerShell)
- ✅ Tweaks `safe: false` sempre mostram modal de confirmação
- ✅ Scripts devem usar `-EA SilentlyContinue` para não quebrar em erros menores
- ✅ Sempre incluir `Write-Host "[OK]..."` no final para feedback visual
- ❌ Não adicione tweaks irreversíveis sem documentar como desfazer

---

## 🇺🇸 Contribution Guide

### Welcome contributions

- 🐛 **Bug reports** — Found something wrong? Open an Issue!
- 💡 **New tweaks** — Know a safe and useful tweak? Propose it via PR!
- 🌍 **Translations** — Want to add support for another language?
- 📝 **Documentation** — README improvements are always welcome
- 🎨 **Design** — UI/UX suggestions are greatly appreciated

### Before opening a PR

1. Check if there is already an Issue or PR on the same topic
2. For new tweaks, describe: **what it does**, **why it's useful**, **what the risk is**, and **how to revert it**
3. Keep the existing code style (vanilla JavaScript, no external dependencies)
4. Test locally by opening `index.html` in your browser

### Commit standard

```
feat: adds X tweak
fix: corrects Y behavior
docs: updates README with Z
style: improves W panel visuals
```

### Tweaks: golden rules

- ✅ Every tweak must have `label`, `safe` (boolean) and `ps` (PowerShell script)
- ✅ `safe: false` tweaks always show a confirmation modal
- ✅ Scripts must use `-EA SilentlyContinue` to not break on minor errors
- ✅ Always include `Write-Host "[OK]..."` at the end for visual feedback
- ❌ Do not add irreversible tweaks without documenting how to undo them

---

*HT Technology — feito com ❤️ para a comunidade / made with ❤️ for the community*
