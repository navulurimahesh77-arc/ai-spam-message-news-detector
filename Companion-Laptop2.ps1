<#
.SYNOPSIS
    AI Spam & News Detector - Second Windows Laptop Companion Server
.DESCRIPTION
    A dedicated, highly configurable Windows Companion server tailored for secondary
    Windows laptops. Supports configurable ports, automatic permission opening,
    diagnostics status reporting, and strict privacy redaction in console logs.
    
    Zero third-party dependencies. Zero external cloud telemetry.
#>

param(
    [int]$Port = 8765,
    [string]$BindHost = "127.0.0.1",
    [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  AI Spam & News Detector - Companion Server (Laptop 2)  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Check Windows Version and WinRT Notification Listener availability
$WinRTOk = $false
$AccessStatus = "Unsupported"
$Listener = $null

try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop
    [Windows.UI.Notifications.Management.UserNotificationListener, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    $Listener = [Windows.UI.Notifications.Management.UserNotificationListener]::Current
    $WinRTOk = ($Listener -ne $null)
    if ($WinRTOk) {
        $AccessStatus = $Listener.GetAccessStatus().ToString()
    }
} catch {
    $WinRTOk = $false
    $AccessStatus = "WinRT Load Error: $_"
}

Write-Host "[INFO] WinRT Notification Listener: " -NoNewline
if ($WinRTOk) {
    Write-Host "Available" -ForegroundColor Green
    Write-Host "[INFO] Windows Notification Access Status: " -NoNewline
    if ($AccessStatus -eq "Allowed") {
        Write-Host "Allowed (Monitoring Active)" -ForegroundColor Green
    } elseif ($AccessStatus -eq "Denied") {
        Write-Host "Denied (Action required in Windows Settings)" -ForegroundColor Yellow
        Write-Host "       Run 'Diagnose-Laptop2.ps1' or enable in Settings > Privacy > Notifications" -ForegroundColor Yellow
    } else {
        Write-Host "$AccessStatus" -ForegroundColor Yellow
    }
} else {
    Write-Host "Unavailable (Requires Windows 10 Build 14393+ or Windows 11)" -ForegroundColor Red
}

$GlobalSequence = 0
$NotificationHistory = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
$SeenNotificationIds = [System.Collections.Generic.HashSet[string]]::new()

function Sanitize-LogSnippet($text) {
    if ([string]::IsNullOrEmpty($text)) { return "(empty)" }
    return "[Length: $($text.Length) chars, Hash: $([Math]::Abs($text.GetHashCode()))]"
}

function Get-NotificationDetails($notif) {
    $id = "$($notif.Id)"
    $app = "Windows App"
    $title = ""
    $body = ""
    $isUnavailable = $false

    try {
        if ($notif.AppInfo -and $notif.AppInfo.DisplayInfo) {
            $appName = $notif.AppInfo.DisplayInfo.DisplayName
            if (-not [string]::IsNullOrWhiteSpace($appName)) {
                $app = [string]$appName
            }
        }
    } catch {}

    try {
        $visual = $notif.Notification.Visual
        $bindings = $visual.GetBinding([Windows.UI.Notifications.KnownNotificationBindings]::ToastGeneric)
        if ($bindings) {
            $textList = @($bindings.GetTextElements())
            if ($textList.Length -gt 0) {
                $t = $textList[0].Text
                if ($t) { $title = [string]$t }
            }
            if ($textList.Length -gt 1) {
                $bodyParts = @()
                for ($i = 1; $i -lt $textList.Length; $i++) {
                    $bt = $textList[$i].Text
                    if ($bt) { $bodyParts += [string]$bt }
                }
                $body = [string]($bodyParts -join " ")
            }
        }
    } catch {
        $isUnavailable = $true
    }

    # Filter internal loops
    if ($title -match "AI (?:Alert|Shield|Spam)" -or $body -match "AI (?:Alert|Shield|Spam)" -or $title -match "Test Pop-up" -or $app -match "ai-spam-message-news-detector" -or $app -match "Antigravity") {
        return $null
    }

    # WhatsApp recognition
    try {
        $aumid = ""
        if ($notif.AppInfo -and $notif.AppInfo.AppUserModelId) { $aumid = [string]$notif.AppInfo.AppUserModelId }
        if ($aumid -match "WhatsApp" -or $aumid -match "5319275A" -or $aumid -eq "Chrome.5AQTQITLTALIS66JT7RCRTTDYQ" -or $app -match "WhatsApp" -or ($title -eq "web.whatsapp.com") -or ($body -match "^~.*:" -and $app -match "Chrome|Edge")) {
            $app = "WhatsApp"
        }
    } catch {}

    if ([string]::IsNullOrWhiteSpace($title) -and [string]::IsNullOrWhiteSpace($body)) {
        $isUnavailable = $true
        $body = "[Content Unavailable: Omitted by Windows privacy settings]"
    }

    return @{
        id = [string]$id
        sourceApp = [string]$app
        title = [string]$title
        body = [string]$body
        isUnavailable = [bool]$isUnavailable
        timestamp = (Get-Date).ToString("o")
    }
}

function Sync-WindowsNotifications {
    if (-not $WinRTOk -or -not $Listener) { return }
    try {
        $currentStatus = $Listener.GetAccessStatus().ToString()
        if ($currentStatus -ne "Allowed") { return }

        $op = $Listener.GetNotificationsAsync([Windows.UI.Notifications.NotificationKinds]::Toast)
        $method = $Listener.GetType().GetMethod('GetNotificationsAsync', [Type[]]@([Windows.UI.Notifications.NotificationKinds]))
        $genericArg = $method.ReturnType.GetGenericArguments()[0]

        $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
            $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetGenericArguments().Count -eq 1 -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -like 'IAsyncOperation*'
        }[0]

        if ($asTask -and $genericArg) {
            $boundAsTask = $asTask.MakeGenericMethod(@($genericArg))
            $task = $boundAsTask.Invoke($null, @($op))
            $task.Wait(1200)
            if ($task.IsCompleted -and -not $task.IsFaulted -and $task.Result) {
                $notifs = $task.Result
                foreach ($n in $notifs) {
                    $nId = "$($n.Id)"
                    if (-not $SeenNotificationIds.Contains($nId)) {
                        [void]$SeenNotificationIds.Add($nId)
                        $item = Get-NotificationDetails($n)
                        if ($null -eq $item) { continue }
                        $seq = [System.Threading.Interlocked]::Increment([ref]$GlobalSequence)
                        $item["sequence"] = $seq
                        [void]$NotificationHistory.Add($item)
                        while ($NotificationHistory.Count -gt 200) {
                            $NotificationHistory.RemoveAt(0)
                        }
                        # Redacted Privacy Log
                        Write-Host "[TOAST DETECTED] App: $($item.sourceApp) | Title: $(Sanitize-LogSnippet $item.title) | Body: $(Sanitize-LogSnippet $item.body)" -ForegroundColor DarkCyan
                    }
                }
            }
        }
    } catch {}
}

# Bind TCP Server
$ListenIp = if ($BindHost -eq "0.0.0.0" -or $BindHost -eq "*") { [System.Net.IPAddress]::Any } else { [System.Net.IPAddress]::Parse($BindHost) }
$TcpServer = New-Object System.Net.Sockets.TcpListener($ListenIp, $Port)

$ServerUrl = "http://${BindHost}:$Port"

try {
    $TcpServer.Start()
} catch {
    Write-Host "[ERROR] Could not start server on $ServerUrl : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try running with a different port: .\Companion-Laptop2.ps1 -Port 8766" -ForegroundColor Yellow
    exit 1
}

Write-Host "[SUCCESS] Laptop 2 Companion running at $ServerUrl" -ForegroundColor Green
Write-Host "[SECURITY] Privacy-compliant redaction active. Zero private text logged." -ForegroundColor Gray
Write-Host ""

if (-not $NoBrowser) {
    try {
        # Check if index.html is available in project root
        $localIndex = Join-Path $ProjectRoot "index.html"
        if (Test-Path $localIndex) {
            Start-Process "http://127.0.0.1:$Port"
        } else {
            Start-Process "https://ai-spam-message-news-detector.vercel.app/"
        }
    } catch {}
}

try {
    while ($true) {
        if ($TcpServer.Pending()) {
            $client = $TcpServer.AcceptTcpClient()
            try {
                $stream = $client.GetStream()
                $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)

                $reqLine = $reader.ReadLine()
                if ([string]::IsNullOrEmpty($reqLine)) { continue }

                $parts = $reqLine.Split(' ')
                $method = $parts[0]
                $urlPath = if ($parts.Length -gt 1) { $parts[1] } else { "/" }
                $route = $urlPath.Split('?')[0]

                $headers = @{}
                $contentLength = 0
                while ($line = $reader.ReadLine()) {
                    if ($line -eq "") { break }
                    $headerParts = $line.Split(':', 2)
                    if ($headerParts.Length -eq 2) {
                        $key = $headerParts[0].Trim().ToLower()
                        $val = $headerParts[1].Trim()
                        $headers[$key] = $val
                        if ($key -eq "content-length") {
                            [int]::TryParse($val, [ref]$contentLength) | Out-Null
                        }
                    }
                }

                $body = ""
                if ($contentLength -gt 0) {
                    $buffer = New-Object char[] $contentLength
                    $totalRead = 0
                    while ($totalRead -lt $contentLength) {
                        $read = $reader.Read($buffer, $totalRead, $contentLength - $totalRead)
                        if ($read -le 0) { break }
                        $totalRead += $read
                    }
                    $body = New-Object string($buffer, 0, $totalRead)
                }

                # CORS preflight
                if ($method -eq "OPTIONS") {
                    $cors = "HTTP/1.1 204 No Content`r`nAccess-Control-Allow-Origin: *`r`nAccess-Control-Allow-Methods: GET, POST, OPTIONS`r`nAccess-Control-Allow-Headers: Content-Type, Accept`r`nAccess-Control-Allow-Private-Network: true`r`nConnection: close`r`n`r`n"
                    $cBytes = [System.Text.Encoding]::UTF8.GetBytes($cors)
                    $stream.Write($cBytes, 0, $cBytes.Length)
                    $stream.Flush()
                    $client.Close()
                    continue
                }

                # Status endpoint
                if ($route -eq "/api/status" -or $route -eq "/status") {
                    Sync-WindowsNotifications
                    $curStatus = if ($Listener) { $Listener.GetAccessStatus().ToString() } else { "Unsupported" }
                    $statusPayload = @{
                        companion = "running"
                        version = "2.0.0-laptop2"
                        winrtAvailable = $WinRTOk
                        winrtPermission = $curStatus
                        platform = "Windows"
                        osVersion = [System.Environment]::OSVersion.VersionString
                        port = $Port
                        timestamp = (Get-Date).ToString("o")
                        guidance = if ($curStatus -ne "Allowed") { "Grant notification access in Windows Settings > Privacy & security > Notifications" } else { "Fully authorized and monitoring" }
                    } | ConvertTo-Json

                    $respBytes = [System.Text.Encoding]::UTF8.GetBytes($statusPayload)
                    $header = "HTTP/1.1 200 OK`r`nContent-Type: application/json`r`nContent-Length: $($respBytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nAccess-Control-Allow-Private-Network: true`r`nConnection: close`r`n`r`n"
                    $hBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                    $stream.Write($hBytes, 0, $hBytes.Length)
                    $stream.Write($respBytes, 0, $respBytes.Length)
                    $stream.Flush()
                    $client.Close()
                    continue
                }

                # Request permission endpoint
                if (($route -eq "/api/request-permission" -or $route -eq "/api/notifications/request-access") -and $method -eq "POST") {
                    $opened = $false
                    try {
                        Start-Process "ms-settings:privacy-notifications"
                        $opened = $true
                    } catch {}

                    $respData = @{
                        success = $opened
                        winrtPermission = if ($Listener) { $Listener.GetAccessStatus().ToString() } else { "Unsupported" }
                        message = if ($opened) { "Opened Windows notification privacy settings." } else { "Please open Settings > Privacy > Notifications manually." }
                    } | ConvertTo-Json

                    $respBytes = [System.Text.Encoding]::UTF8.GetBytes($respData)
                    $header = "HTTP/1.1 200 OK`r`nContent-Type: application/json`r`nContent-Length: $($respBytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nAccess-Control-Allow-Private-Network: true`r`nConnection: close`r`n`r`n"
                    $hBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                    $stream.Write($hBytes, 0, $hBytes.Length)
                    $stream.Write($respBytes, 0, $respBytes.Length)
                    $stream.Flush()
                    $client.Close()
                    continue
                }

                # Poll notifications
                if (($route -eq "/api/notifications" -or $route -eq "/api/notifications/poll") -and $method -eq "GET") {
                    Sync-WindowsNotifications
                    $sinceSeq = 0
                    if ($urlPath -match "[\?&]since=(\d+)") {
                        [int]::TryParse($matches[1], [ref]$sinceSeq) | Out-Null
                    }

                    $snapshot = [System.Object[]]$NotificationHistory.ToArray()
                    $batch = @()
                    if ($sinceSeq -gt 0) {
                        $batch = @($snapshot | Where-Object { $_.sequence -gt $sinceSeq })
                    } else {
                        $batch = @($snapshot | Select-Object -Last 50)
                    }

                    $maxSeq = if ($batch.Count -gt 0) { $batch[-1].sequence } else { $sinceSeq }
                    if (-not $maxSeq -or $maxSeq -eq 0) { $maxSeq = $GlobalSequence }

                    $respData = @{
                        success = $true
                        notifications = @($batch)
                        count = $batch.Count
                        sequence = $maxSeq
                    } | ConvertTo-Json -Depth 4

                    $respBytes = [System.Text.Encoding]::UTF8.GetBytes($respData)
                    $header = "HTTP/1.1 200 OK`r`nContent-Type: application/json`r`nContent-Length: $($respBytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nAccess-Control-Allow-Private-Network: true`r`nConnection: close`r`n`r`n"
                    $hBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                    $stream.Write($hBytes, 0, $hBytes.Length)
                    $stream.Write($respBytes, 0, $respBytes.Length)
                    $stream.Flush()
                    $client.Close()
                    continue
                }

                # Simulate endpoint for pipeline testing
                if ($route -eq "/api/notifications/simulate" -and $method -eq "POST") {
                    $simObj = @{
                        id = "msg_" + (Get-Date).Ticks
                        sourceApp = "WhatsApp"
                        title = "WhatsApp (Test User)"
                        body = "Hello! This is a test notification on Laptop 2."
                        isUnavailable = $false
                        timestamp = (Get-Date).ToString("o")
                    }
                    if (-not [string]::IsNullOrEmpty($body)) {
                        try {
                            $p = $body | ConvertFrom-Json
                            if ($p.sourceApp) { $simObj.sourceApp = [string]$p.sourceApp }
                            if ($p.title) { $simObj.title = [string]$p.title }
                            if ($p.body) { $simObj.body = [string]$p.body }
                        } catch {}
                    }
                    $seq = [System.Threading.Interlocked]::Increment([ref]$GlobalSequence)
                    $simObj["sequence"] = $seq
                    [void]$NotificationHistory.Add($simObj)

                    $respData = @{ success = $true; simulated = $simObj } | ConvertTo-Json
                    $respBytes = [System.Text.Encoding]::UTF8.GetBytes($respData)
                    $header = "HTTP/1.1 200 OK`r`nContent-Type: application/json`r`nContent-Length: $($respBytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nAccess-Control-Allow-Private-Network: true`r`nConnection: close`r`n`r`n"
                    $hBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                    $stream.Write($hBytes, 0, $hBytes.Length)
                    $stream.Write($respBytes, 0, $respBytes.Length)
                    $stream.Flush()
                    $client.Close()
                    continue
                }

                # Serve local static assets if requested
                $filePath = ""
                if ($route -eq "/" -or $route -eq "") {
                    $filePath = Join-Path $ProjectRoot "index.html"
                } else {
                    $cleanRel = $route.TrimStart("/").Replace("/", "\")
                    $filePath = Join-Path $ProjectRoot $cleanRel
                }

                if (Test-Path $filePath -PathType Leaf) {
                    $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                    $mime = switch ($ext) {
                        ".html" { "text/html; charset=utf-8" }
                        ".css"  { "text/css; charset=utf-8" }
                        ".js"   { "application/javascript; charset=utf-8" }
                        ".json" { "application/json; charset=utf-8" }
                        ".png"  { "image/png" }
                        ".jpg"  { "image/jpeg" }
                        ".ico"  { "image/x-icon" }
                        default { "application/octet-stream" }
                    }
                    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
                    $header = "HTTP/1.1 200 OK`r`nContent-Type: $mime`r`nContent-Length: $($fileBytes.Length)`r`nConnection: close`r`n`r`n"
                    $hBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
                    $stream.Write($hBytes, 0, $hBytes.Length)
                    $stream.Write($fileBytes, 0, $fileBytes.Length)
                    $stream.Flush()
                } else {
                    $notFound = "HTTP/1.1 404 Not Found`r`nContent-Length: 0`r`nConnection: close`r`n`r`n"
                    $nfBytes = [System.Text.Encoding]::UTF8.GetBytes($notFound)
                    $stream.Write($nfBytes, 0, $nfBytes.Length)
                    $stream.Flush()
                }
                $client.Close()
            } catch {
                if ($client) { $client.Close() }
            }
        } else {
            Start-Sleep -Milliseconds 150
        }
    }
} finally {
    $TcpServer.Stop()
}
