# Uninstall Coralogix OTel Collector Windows Service
#Requires -RunAsAdministrator

$SERVICE_NAME = "CoralogixOtelCollector"

Write-Host "Stopping and removing $SERVICE_NAME service..."

if (Get-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue) {
    Stop-Service -Name $SERVICE_NAME -Force -ErrorAction SilentlyContinue
    sc.exe delete $SERVICE_NAME | Out-Null
    Write-Host "Service removed." -ForegroundColor Green
} else {
    Write-Host "Service not found - nothing to remove."
}
