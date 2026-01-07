# Azure Virtual Desktop Demo - Deployment Script
# PowerShell Version

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "../parameters/avd-demo.parameters.json",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westeurope"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Azure Virtual Desktop Demo - Deployment" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow

if (-not (Get-Module -ListAvailable -Name Az.Resources)) {
    Write-Host "❌ Az.Resources module not found" -ForegroundColor Red
    Write-Host "Install with: Install-Module -Name Az -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Module -ListAvailable -Name Az.DesktopVirtualization)) {
    Write-Host "⚠️  Az.DesktopVirtualization module not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Az.DesktopVirtualization -Scope CurrentUser -Force
}

# Check Azure login
Write-Host "🔐 Checking Azure login..." -ForegroundColor Yellow
try {
    $context = Get-AzContext
    if (-not $context) {
        throw "Not logged in"
    }
    Write-Host "✅ Logged in as: $($context.Account)" -ForegroundColor Green
} catch {
    Write-Host "❌ Not logged in. Running Connect-AzAccount..." -ForegroundColor Red
    Connect-AzAccount
    $context = Get-AzContext
}

Write-Host "📋 Subscription: $($context.Subscription.Name)" -ForegroundColor Cyan
Write-Host ""

# Confirm deployment
$confirmation = Read-Host "Deploy to this subscription? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

# Check for existing resource group
$rgName = "rg-avd-demo"
$rgExists = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue

if ($rgExists) {
    Write-Host "⚠️  Resource group '$rgName' already exists" -ForegroundColor Yellow
    $deleteConfirm = Read-Host "Delete and redeploy? (y/n)"
    if ($deleteConfirm -eq 'y') {
        Write-Host "🗑️  Deleting resource group..." -ForegroundColor Yellow
        Remove-AzResourceGroup -Name $rgName -Force
        Write-Host "⏳ Waiting 30 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    } else {
        Write-Host "❌ Deployment cancelled" -ForegroundColor Red
        exit 1
    }
}

# Validate template
Write-Host "🔍 Validating Bicep template..." -ForegroundColor Yellow
$deploymentName = "avd-demo-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

try {
    Test-AzSubscriptionDeployment `
        -Location $Location `
        -TemplateFile "../bicep/main.bicep" `
        -TemplateParameterFile $ParametersFile `
        -ErrorAction Stop | Out-Null
    
    Write-Host "✅ Template validation successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Template validation failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Deploy
Write-Host ""
Write-Host "🚀 Starting deployment..." -ForegroundColor Cyan
Write-Host "⏱️  This will take 10-15 minutes. Please wait..." -ForegroundColor Yellow
Write-Host ""

try {
    $deployment = New-AzSubscriptionDeployment `
        -Location $Location `
        -TemplateFile "../bicep/main.bicep" `
        -TemplateParameterFile $ParametersFile `
        -Name $deploymentName `
        -ErrorAction Stop
    
    Write-Host ""
    Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Outputs:" -ForegroundColor Cyan
    $deployment.Outputs | Format-Table -AutoSize
    
} catch {
    Write-Host ""
    Write-Host "❌ Deployment failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Post-deployment instructions
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣  Wait 5-10 minutes for session hosts to become 'Available'" -ForegroundColor White
Write-Host ""
Write-Host "2️⃣  Assign users to the application group:" -ForegroundColor White
Write-Host '   $appGroupId = (Get-AzWvdApplicationGroup -Name "avddemo-dag" -ResourceGroupName "rg-avd-demo").Id' -ForegroundColor Gray
Write-Host '   New-AzRoleAssignment -SignInName user@domain.com -RoleDefinitionName "Desktop Virtualization User" -Scope $appGroupId' -ForegroundColor Gray
Write-Host ""
Write-Host "3️⃣  Assign VM login permissions:" -ForegroundColor White
Write-Host '   $vm = Get-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-0"' -ForegroundColor Gray
Write-Host '   New-AzRoleAssignment -SignInName user@domain.com -RoleDefinitionName "Virtual Machine User Login" -Scope $vm.Id' -ForegroundColor Gray
Write-Host ""
Write-Host "4️⃣  Connect at: https://client.wvd.microsoft.com" -ForegroundColor White
Write-Host ""
Write-Host "📝 For detailed instructions, see docs/DEPLOYMENT-GUIDE.md" -ForegroundColor Cyan
Write-Host ""
