# Install macOS host metrics -> Coralogix (Windows)
# Run in PowerShell as Administrator:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\install-windows.ps1

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$VERSION = "0.112.0"
$SERVICE_NAME = "CoralogixOtelCollector"
$INSTALL_DIR = "$PSScriptRoot"
$BINARY = "$INSTALL_DIR\otelcol-contrib.exe"
$CONFIG = "$INSTALL_DIR\config-windows.yaml"
$LOG_FILE = "$INSTALL_DIR\collector.log"

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Windows Host Metrics -> Coralogix  Installer" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Get machine name ───────────────────────────────
$defaultName = $env:COMPUTERNAME.ToLower() -replace '[^a-z0-9-]', '-'
Write-Host "Enter a name for this machine (used in Coralogix as application name)."
Write-Host "Press Enter to use the default: [$defaultName]"
$machineInput = Read-Host "Machine name"
if ([string]::IsNullOrWhiteSpace($machineInput)) {
    $CX_APP_NAME = $defaultName
} else {
    $CX_APP_NAME = $machineInput.ToLower() -replace '[^a-z0-9-]', '-'
}
Write-Host "Using application name: $CX_APP_NAME" -ForegroundColor Green

# ── 2. Get Coralogix private key ──────────────────────
if ($env:CORALOGIX_PRIVATE_KEY) {
    $CX_KEY = $env:CORALOGIX_PRIVATE_KEY
    Write-Host "Using CORALOGIX_PRIVATE_KEY from environment." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Enter your Coralogix Send-Your-Data API key (starts with cxtp_):"
    $secureKey = Read-Host -AsSecureString
    $CX_KEY = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    )
    if ([string]::IsNullOrWhiteSpace($CX_KEY)) {
        Write-Error "API key is required."
        exit 1
    }
}

# ── 3. Download binary if missing ────────────────────
if (-not (Test-Path $BINARY)) {
    Write-Host ""
    Write-Host "Downloading otelcol-contrib v$VERSION for Windows..."
    $tarUrl = "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v$VERSION/otelcol-contrib_${VERSION}_windows_amd64.tar.gz"
    $tarPath = "$INSTALL_DIR\otelcol-contrib.tar.gz"
    Invoke-WebRequest -Uri $tarUrl -OutFile $tarPath -UseBasicParsing
    Write-Host "Extracting..."
    # tar is built-in on Windows 10+
    & tar -xzf $tarPath -C $INSTALL_DIR otelcol-contrib.exe
    Remove-Item $tarPath
    Write-Host "Binary ready." -ForegroundColor Green
} else {
    Write-Host "otelcol-contrib binary already present." -ForegroundColor Green
}

# ── 4. Stop & remove existing service if present ─────
if (Get-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue) {
    Write-Host "Stopping existing service..."
    Stop-Service -Name $SERVICE_NAME -Force -ErrorAction SilentlyContinue
    sc.exe delete $SERVICE_NAME | Out-Null
    Start-Sleep -Seconds 2
}

# ── 5. Create Windows Service ─────────────────────────
Write-Host "Creating Windows Service..."
$binPath = "`"$BINARY`" --config `"$CONFIG`""
sc.exe create $SERVICE_NAME binPath= $binPath start= auto DisplayName= "Coralogix OTel Collector" | Out-Null
sc.exe description $SERVICE_NAME "Sends host metrics to Coralogix via OpenTelemetry" | Out-Null

# Set environment variables for the service via registry
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$SERVICE_NAME"
$envVars = @(
    "CORALOGIX_PRIVATE_KEY=$CX_KEY",
    "CX_APPLICATION_NAME=$CX_APP_NAME"
)
New-ItemProperty -Path $regPath -Name "Environment" -Value $envVars -PropertyType MultiString -Force | Out-Null

# Redirect stdout/stderr to log file via wrapper (sc.exe doesn't support this natively)
# Use AppendToLog via registry
New-ItemProperty -Path $regPath -Name "AppDirectory" -Value $INSTALL_DIR -PropertyType String -Force | Out-Null

# ── 6. Start the service ──────────────────────────────
Write-Host "Starting service..."
Start-Service -Name $SERVICE_NAME
Start-Sleep -Seconds 5

$svc = Get-Service -Name $SERVICE_NAME
if ($svc.Status -eq "Running") {
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host "  Installation complete!" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Metrics will appear in Coralogix within ~2 min"
    Write-Host "  Application name : $CX_APP_NAME"
    Write-Host "  Subsystem name   : host-metrics"
    Write-Host ""
    Write-Host "  Useful commands:"
    Write-Host "    Status:    Get-Service $SERVICE_NAME"
    Write-Host "    Stop:      Stop-Service $SERVICE_NAME"
    Write-Host "    Start:     Start-Service $SERVICE_NAME"
    Write-Host "    Uninstall: .\uninstall-windows.ps1"
    Write-Host ""
} else {
    Write-Warning "Service status: $($svc.Status). Check Event Viewer for errors."
    exit 1
}
