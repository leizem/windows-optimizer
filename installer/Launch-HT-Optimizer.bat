@echo off
:: HT Technology — Windows Optimizer Pro
:: Launcher: abre o dashboard no navegador padrão
:: Launch: opens the dashboard in the default browser

setlocal
set "APPDIR=%~dp0"

:: Abre o dashboard no navegador padrão
:: Opens the dashboard in the default browser
start "" "%APPDIR%index.html"

endlocal
