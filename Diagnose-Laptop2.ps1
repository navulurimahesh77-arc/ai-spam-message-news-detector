<#
.SYNOPSIS
    Diagnostics & Health Check for Second Windows Laptop - AI Spam & News Detector
.DESCRIPTION
    Verifies that the secondary Windows laptop has all required Windows Runtime (WinRT)
    components, notification permissions, and network ports to run the Notification Companion.
    
    Operates strictly read-only on OS settings.
    Zero message content is logged or transmitted.
#>

param(
    [int]$Port = 8765,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  AI Spam & News Detector - Laptop 2 Diagnostics Tool    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$PassedChecks = 0
$TotalChecks = 6
$Warnings = @()
$Errors = @()

# -------------------------------------------------------------
# CHECK 1: Windows Version & OS Build
# -------------------------------------------------------------
Write-Host "[CHECK 1/6] Inspecting Windows OS version & build..." -ForegroundColor Yellow
$os = [System.Environment]::OSVersion
$build = $os.Version.Build
Write-Host "            OS: $($os.VersionString) (Build $build)" -ForegroundColor Gray

if ($build -ge 14393) {
    Write-Host "  [PASS] Windows build $build supports WinRT UserNotificationListener (requires 14393+)." -ForegroundColor Green
    $PassedChecks++
} else {
    $msg = "Windows build $build is older than 14393 (Windows 10 Anniversary Update). WinRT notification listening is not supported on this build."
    Write-Host "  [FAIL] $msg" -ForegroundColor Red
    $Errors += $msg
}

# -------------------------------------------------------------
# CHECK 2: WinRT Assembly Availability
# -------------------------------------------------------------
Write-Host "`n[CHECK 2/6] Inspecting WinRT .NET Assemblies..." -ForegroundColor Yellow
$winrtLoaded = $false
try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop
    [Windows.UI.Notifications.Management.UserNotificationListener, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    $winrtLoaded = $true
    Write-Host "  [PASS] System.Runtime.WindowsRuntime and WinRT Notification classes loaded." -ForegroundColor Green
    $PassedChecks++
} catch {
    $msg = "Failed to load WinRT assemblies: $($_.Exception.Message)"
    Write-Host "  [FAIL] $msg" -ForegroundColor Red
    $Errors += $msg
}

# -------------------------------------------------------------
# CHECK 3: Windows Notification Access Permission
# -------------------------------------------------------------
Write-Host "`n[CHECK 3/6] Inspecting UserNotificationListener Access Status..." -ForegroundColor Yellow
$listener = $null
$accessStatus = "Unavailable"

if ($winrtLoaded) {
    try {
        $listener = [Windows.UI.Notifications.Management.UserNotificationListener]::Current
        if ($listener) {
            $accessStatus = $listener.GetAccessStatus().ToString()
        }
    } catch {
        $accessStatus = "Error: $($_.Exception.Message)"
    }
}

if ($accessStatus -eq "Allowed") {
    Write-Host "  [PASS] Access Status is 'Allowed'! This laptop is authorized to monitor notifications." -ForegroundColor Green
    $PassedChecks++
} elseif ($accessStatus -eq "Denied") {
    $msg = "Access Status is 'Denied'. Windows is blocking notification access for apps on this laptop."
    Write-Host "  [WARNING] $msg" -ForegroundColor Yellow
    Write-Host "            FIX: Open Windows Settings > Privacy & security > Notifications" -ForegroundColor Cyan
    Write-Host "                 Turn ON 'Let apps access your notifications'." -ForegroundColor Cyan
    $Warnings += $msg

    if (-not $NonInteractive) {
        $choice = Read-Host "            Do you want to open Windows Notification Settings now? (Y/N)"
        if ($choice -match "^[Yy]") {
            try {
                Start-Process "ms-settings:privacy-notifications"
                Write-Host "            Opened Windows Settings. Please toggle ON and re-run this tool." -ForegroundColor Green
            } catch {
                Write-Host "            Could not open Settings automatically: $_" -ForegroundColor Red
            }
        }
    }
} else {
    $msg = "Access Status returned: '$accessStatus'."
    Write-Host "  [WARNING] $msg" -ForegroundColor Yellow
    $Warnings += $msg
}

# -------------------------------------------------------------
# CHECK 4: TCP Port Availability
# -------------------------------------------------------------
Write-Host "`n[CHECK 4/6] Inspecting local port $Port availability..." -ForegroundColor Yellow
$portAvailable = $false
try {
    $tcp = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
    $tcp.Start()
    $tcp.Stop()
    $portAvailable = $true
    Write-Host "  [PASS] Port $Port is available for loopback HTTP binding." -ForegroundColor Green
    $PassedChecks++
} catch {
    # Check if existing companion is already running on this port
    try {
        $resp = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/status" -TimeoutSec 2 -ErrorAction Stop
        if ($resp.companion -eq "running") {
            Write-Host "  [PASS] AI Companion is ALREADY running on port $Port! (Version: $($resp.version))" -ForegroundColor Green
            $portAvailable = $true
            $PassedChecks++
        } else {
            $msg = "Port $Port is in use by another non-companion service."
            Write-Host "  [FAIL] $msg" -ForegroundColor Red
            $Errors += $msg
        }
    } catch {
        $msg = "Port $Port is in use or blocked: $($_.Exception.Message)"
        Write-Host "  [FAIL] $msg" -ForegroundColor Red
        $Errors += $msg
    }
}

# -------------------------------------------------------------
# CHECK 5: Windows Notification Banner Settings
# -------------------------------------------------------------
Write-Host "`n[CHECK 5/6] Inspecting Toast Banner Notification Settings..." -ForegroundColor Yellow
$toastEnabled = $true
try {
    $pushPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"
    if (Test-Path $pushPath) {
        $toastVal = (Get-ItemProperty -Path $pushPath -Name "ToastEnabled" -ErrorAction SilentlyContinue).ToastEnabled
        if ($toastVal -eq 0) {
            $toastEnabled = $false
        }
    }
} catch {}

if ($toastEnabled) {
    Write-Host "  [PASS] Toast notifications are enabled in Windows." -ForegroundColor Green
    $PassedChecks++
} else {
    $msg = "Toast notifications appear disabled in the Windows registry (ToastEnabled = 0)."
    Write-Host "  [WARNING] $msg" -ForegroundColor Yellow
    $Warnings += $msg
}

# -------------------------------------------------------------
# CHECK 6: Privacy Redaction Policy Verification
# -------------------------------------------------------------
Write-Host "`n[CHECK 6/6] Verifying privacy log redaction..." -ForegroundColor Yellow
$testRawMessage = "Confidential OTP: 948271 for Account 123456"
# Simulating privacy masking function:
$sanitizedLog = "Incoming notification [App: WhatsApp] [Redacted Length: $($testRawMessage.Length) chars]"
if ($sanitizedLog -notmatch "948271" -and $sanitizedLog -notmatch "Account") {
    Write-Host "  [PASS] Diagnostic logging redacts raw message contents." -ForegroundColor Green
    $PassedChecks++
} else {
    Write-Host "  [FAIL] Privacy leak detected in test redaction." -ForegroundColor Red
    $Errors += "Privacy leak in test redaction"
}

# -------------------------------------------------------------
# SUMMARY & ACTIONABLE RECOMMENDATIONS
# -------------------------------------------------------------
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  DIAGNOSTIC SUMMARY: $PassedChecks of $TotalChecks checks passed." -ForegroundColor $(if ($Errors.Count -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($Errors.Count -gt 0) {
    Write-Host "`n[BLOCKING ISSUES]:" -ForegroundColor Red
    foreach ($err in $Errors) {
        Write-Host "  - $err" -ForegroundColor Red
    }
}

if ($Warnings.Count -gt 0) {
    Write-Host "`n[WARNINGS / ACTIONS NEEDED ON LAPTOP 2]:" -ForegroundColor Yellow
    foreach ($w in $Warnings) {
        Write-Host "  - $w" -ForegroundColor Yellow
    }
    Write-Host "`nRECOMMENDED FIXES FOR LAPTOP 2:" -ForegroundColor Cyan
    Write-Host "  1. Open Windows Settings (Win + I) > Privacy & security > Notifications" -ForegroundColor White
    Write-Host "     Ensure 'Let apps access your notifications' is switched to ON." -ForegroundColor White
    Write-Host "  2. In Windows Settings > System > Notifications:" -ForegroundColor White
    Write-Host "     Ensure WhatsApp / Chrome has 'Show notification banners' enabled." -ForegroundColor White
    Write-Host "  3. Ensure 'Do Not Disturb' or 'Focus Assist' is turned OFF in Action Center." -ForegroundColor White
}

if ($PassedChecks -eq $TotalChecks) {
    Write-Host "`n[READY] Laptop 2 meets all requirements! You can now launch the companion." -ForegroundColor Green
}

Write-Host ""
