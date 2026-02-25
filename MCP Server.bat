@echo off
setlocal enabledelayedexpansion
title MCP Super Terminal (Launching...)

:: Port Cleanup
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :4003') do taskkill /f /pid %%a >nul 2>&1

:: Launch Node TUI using tsx
npx tsx src/mcp_terminal.js
pause
