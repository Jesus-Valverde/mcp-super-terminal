param (
    [string]$ProxyPath,
    [string]$ConfigPath
)

# Configuración inicial
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$esc = [char]27
$ready = [bool]$false
$servers = @()
$toolsMap = @{}
$totalTools = 0
$view = 'L'
$green = [char]::ConvertFromUtf32(0x1F7E2)
$red = [char]::ConvertFromUtf32(0x1F534)
$footer = "$($esc)[90m [L] Logs  [T] Tools List  [Q] Quit$esc[0m"

# Datos dinámicos para barras
$serversTotal = 2 # Detectado de config.json
$serversLoaded = 0
$toolsScanned = 0

# Función para limpiar y resetear
function Cleanup {
    Write-Host -NoNewline "$($esc)[r$($esc)[?25h" # Reset scrolling y mostrar cursor
    exit
}

# Animación de carga Premium (A prueba de errores de codificación)
function Show-Loading {
    $statuses = @(
        "INITIALIZING CORE...",
        "SYNCING CONFIG...",
        "STARTING PROXY...",
        "GETTING READY..."
    )

    for ($i = 0; $i -le 20; $i++) {
        cls
        $percent = [math]::Floor(($i / 20) * 100)
        $barWidth = 40
        $filled = [math]::Floor(($i / 20) * $barWidth)
        $empty = $barWidth - $filled
        
        $statusIdx = [math]::Min([math]::Floor($i / 5.1), 3)
        $status = $statuses[$statusIdx]

        Write-Host "`n`n`n"
        Write-Host "      $($esc)[1m$($esc)[96m--- MCP SUPER TERMINAL SYSTEM ---$($esc)[0m"
        Write-Host "`n"
        Write-Host "      $($esc)[90mSTATUS: $($esc)[37m$status$($esc)[0m"
        
        # Barra de progreso usando espacios con fondo de color
        Write-Host -NoNewline "      $($esc)[90m["
        if ($filled -gt 0) {
            Write-Host -NoNewline "$($esc)[46m$(" " * $filled)$($esc)[0m"
        }
        Write-Host -NoNewline "$(" " * $empty)$($esc)[90m] $($percent)%$($esc)[0m"
        Write-Host "`n`n"
        
        # Decoración técnica
        $dot = if ($i % 4 -eq 0) { "." } elseif ($i % 4 -eq 1) { ".." } elseif ($i % 4 -eq 2) { "..." } else { "" }
        Write-Host "      $($esc)[90mACCESSING ENCRYPTED GATEWAY$dot$($esc)[0m"
        
        Start-Sleep -m 60
    }
    Start-Sleep -m 300
}

# Helper para dibujar una barra pequeña en el dashboard
function Get-SmallBar ([int]$current, [int]$total, [int]$width = 15) {
    if ($total -eq 0) { return "$($esc)[90m" + (" " * $width) + "$($esc)[0m" }
    $ratio = [math]::Min($current / $total, 1.0)
    $filled = [math]::Floor($ratio * $width)
    $empty = $width - $filled
    return "$($esc)[46m" + (" " * $filled) + "$($esc)[40m" + (" " * $empty) + "$($esc)[0m"
}

# Dibujar el Header de la Super Terminal
function Show-MainHeader {
    cls
    Write-Host "`n   __  __  ____ ____    ____   _____              _             _ "
    Write-Host "  |  \/  |/ ___|  _ \  / ___| |_   _|__ _ __ _ __(_)_ __   __ _| |"
    Write-Host "  | |/\| | |   | |_/ | \___ \   | |/ _ \ '__| '_ \ | '_ \ / _` | |"
    Write-Host "  | |  | | |___|  __/   ___) |  | |  __/ |  | | | | | | | | (_| | |"
    Write-Host "  |_|  |_|\____|_|     |____/   |_|\___|_|  |_| |_|_|_| |_|\__,_|_|"
    Write-Host "`n                  Created by jesval"
    Write-Host "  ========================================================================="
    # Row 9: Status Line
    Write-Host -NoNewline "   Servidor: $($green)    SuperAssistant: $($red)    Tools Found: $totalTools"
    # Row 10: Servers
    Write-Host -NoNewline "$($esc)[10;4HServers: [...]"
    # Row 11: Progress Bars (Initially empty)
    Write-Host -NoNewline "$($esc)[11;4H"
    Update-Dashboard
    Write-Host "`n  ========================================================================="
    Write-Host "   Last logs:`n"
}

function Update-Dashboard {
    $saStatus = if ($ready) { $green } else { $red }
    $list = ($servers -join ', ')
    if ($ready) { $list += ']' }
    
    # Guardar posición actual
    Write-Host -NoNewline "$($esc)[s"

    # 1. Row 9: SuperAssistant Status y Tools
    Write-Host -NoNewline "$($esc)[9;35H$saStatus$($esc)[9;64H$totalTools "

    # 2. Row 10: Servers
    Write-Host -NoNewline "$($esc)[10;13H$list                                        "

    # 3. Row 11: Progress Bars (Se ocultan al terminar)
    $barLine = ""
    if ($serversLoaded -lt $serversTotal) {
        $barLine += "Load: [$(Get-SmallBar $serversLoaded $serversTotal)]  "
    }
    if ($toolsScanned -lt $serversTotal) {
        $barLine += "Scan: [$(Get-SmallBar $toolsScanned $serversTotal)]  "
    }
    
    Write-Host -NoNewline "$($esc)[11;4H$barLine                                                  "

    # Restaurar posición
    Write-Host -NoNewline "$($esc)[u"
}

function Update-Footer {
    $h = $Host.UI.RawUI.WindowSize.Height
    Write-Host -NoNewline "$($esc)[s$($esc)[$h;1H$($esc)[48;5;235m$($esc)[2K$footer$($esc)[0m$($esc)[u"
}

function Set-ScrollingRegion {
    $h = $Host.UI.RawUI.WindowSize.Height
    $top = 14
    $bottom = $h - 1
    if ($bottom -le $top) { $bottom = $top + 1 }
    Write-Host -NoNewline "$($esc)[$top;$($bottom);r$($esc)[$top;1H"
}

# --- INICIO DEL PROGRAMA ---
Show-Loading
Show-MainHeader
Set-ScrollingRegion
Update-Footer

# Lanzar Proxy y procesar salida
& $ProxyPath --host 127.0.0.1 --port 4003 --config $ConfigPath --baseUrl http://127.0.0.1:4003 --logLevel info | ForEach-Object {
    $line = $_ -replace 'mcp-superassistant-proxy', 'MCP-SA-Proxy'
    $update = $false

    if ($line -match 'Connected to server: (.*)') {
        $s = $matches[1].Trim()
        if ($servers -notcontains $s) { 
            $servers += $s
            $serversLoaded++
        }
        $update = $true
    }
    if ($line -match 'Server (.*) has (\d+) tools') {
        $s = $matches[1].Trim()
        $c = [int]$matches[2]
        if (-not $toolsMap.ContainsKey($s)) { 
            $totalTools += $c
            $toolsMap[$s] = $c 
            $toolsScanned++
        }
        $update = $true
    }
    if ($line -match 'Config-to-SSE gateway ready' -or $line -match 'POST to SSE transport' -or $line -match 'SSE -> Servers') {
        $ready = $true
        $update = $true
    }

    if ($update) { Update-Dashboard }

    # Input handling
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').Character.ToString().ToUpper()
        if ($key -eq 'Q') { Cleanup }
        elseif ($key -eq 'T') {
            $view = 'T'
            Write-Host -NoNewline "$($esc)[14;1H$($esc)[J"
            Write-Host "$($esc)[96m--- TOOLS SUMMARY ---$($esc)[0m"
            $toolsMap.Keys | ForEach-Object { Write-Host " - $_`: $($toolsMap[$_]) tools" }
        }
        elseif ($key -eq 'L') {
            if ($view -eq 'T') { Write-Host -NoNewline "$($esc)[14;1H$($esc)[J" }
            $view = 'L'
        }
    }

    if ($view -eq 'L') {
        $time = Get-Date -Format 'HH:mm:ss'
        if ($line -match '\[(.*?)\]') {
            $tag = $matches[1]
            $fLine = $line -replace '\[.*?\]', "$($esc)[96m[$tag]$($esc)[0m"
            Write-Host "$($esc)[90m[$time]$($esc)[0m $fLine"
        } else {
            Write-Host "$($esc)[90m[$time]$($esc)[0m $line"
        }
    }
    Update-Footer
}
