@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title MCP Super Terminal

:: Configuración de rutas
set "PROXY_PATH=C:\Users\jesus\AppData\Roaming\npm\mcp-superassistant-proxy.cmd"
set "CONFIG_PATH=C:\Users\jesus\AppData\Roaming\SuperAssistant\config\config.json"
set "PS_SCRIPT=%~dp0mcp_terminal.ps1"

:: Limpiar puerto 4003 antes de iniciar
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :4003 ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
)

:: Lanzar el script de PowerShell
powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -ProxyPath "%PROXY_PATH%" -ConfigPath "%CONFIG_PATH%"

echo.
echo ==========================================
echo    EL PROCESO SE HA DETENIDO
echo ==========================================
pause
