# Azure Virtual Desktop Demo - Cleanup Script
# Removes all deployed resources

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-avd-demo",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "🗑️  Azure Virtual Desktop Demo - Cleanup" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Check if resource group exists
Write-Host "🔍 Checking for resource group '$ResourceGroupName'..." -ForegroundColor Yellow

$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

if (-not $rg) {
    Write-Host "✅ Resource group does not exist. Nothing to clean up." -ForegroundColor Green
    exit 0
}

# Show resources
Write-Host ""
Write-Host "📋 Resources to be deleted:" -ForegroundColor Cyan
Get-AzResource -ResourceGroupName $ResourceGroupName | 
    Format-Table Name, ResourceType -AutoSize

# Confirm deletion
if (-not $Force) {
    Write-Host ""
    Write-Host "⚠️  WARNING: This will delete ALL resources in the resource group!" -ForegroundColor Yellow
    $confirmation = Read-Host "Are you sure you want to continue? (yes/no)"
    
    if ($confirmation -ne 'yes') {
        Write-Host "Cleanup cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Delete resource group
Write-Host ""
Write-Host "🗑️  Deleting resource group..." -ForegroundColor Red
try {
    Remove-AzResourceGroup -Name $ResourceGroupName -Force
    Write-Host "✅ Resource group deleted successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "💰 Billing has stopped for all resources" -ForegroundColor Green
} catch {
    Write-Host "❌ Error deleting resource group:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
