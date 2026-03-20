# Deployment Guide

Complete step-by-step guide for deploying the AVD demo environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Pre-Deployment](#pre-deployment)
- [Deployment](#deployment)
- [Post-Deployment](#post-deployment)
- [Validation](#validation)
- [Next Steps](#next-steps)

## Prerequisites

### Required Software

| Tool | Version | Installation |
|------|---------|--------------|
| Azure PowerShell | Latest | `Install-Module -Name Az` |
| Azure CLI | 2.50+ | https://aka.ms/installazurecli |
| Bicep CLI | Latest | Auto-installed with Azure CLI |
| Git | Any | https://git-scm.com/downloads |

### Azure Requirements

- **Subscription**: Active Azure subscription with Contributor access
- **Quota**: Minimum 4 vCPUs for Standard_B2ms VMs in target region
- **Permissions**: 
  - Contributor on subscription (for resource creation)
  - User Access Administrator (for role assignments)

### Network Requirements

- Outbound internet connectivity from deployment machine
- No proxy restrictions for Azure management endpoints

## Pre-Deployment

### 1. Clone the Repository

```bash
git clone https://github.com/TychoLoke/Basic-AVD-Landing-Zone.git
cd avd-demo
```

### 2. Review Parameters

Open `parameters/avd-demo.parameters.json` and review all settings:

```json
{
  "location": "westeurope",          // Azure region
  "prefix": "avddemo",                // Resource name prefix
  "adminPassword": "CHANGE_THIS",     // 🔴 MUST CHANGE
  "sessionHostCount": 2,              // Number of VMs (1-3)
  "vmSize": "Standard_B2ms",          // VM size
  "maxSessionLimit": 10               // Max sessions per VM
}
```

**⚠️ CRITICAL**: Change `adminPassword` to a secure password:
- Minimum 12 characters
- Include uppercase, lowercase, numbers, special characters
- Example: `AVDDemo2024!Secure#Pass`

### 3. Choose Deployment Method

| Method | Best For | Complexity |
|--------|----------|------------|
| PowerShell | Windows users, automation | Medium |
| Bash/Azure CLI | Linux/Mac users, CI/CD | Medium |
| Azure Portal | First-time users, visual preference | Low |

## Deployment

### Method 1: PowerShell (Windows)

```powershell
# Navigate to scripts folder
cd scripts

# Login to Azure
Connect-AzAccount

# Select subscription (if you have multiple)
Set-AzContext -SubscriptionName "Your Subscription Name"

# Run deployment
.\deploy.ps1
```

**What to expect**:
- Prompts to confirm subscription
- Template validation (30 seconds)
- Deployment progress (10-15 minutes)
- Success message with outputs

### Method 2: Bash/Azure CLI (Linux/Mac)

```bash
# Navigate to scripts folder
cd scripts

# Make script executable
chmod +x deploy.sh

# Login to Azure
az login

# Select subscription (if you have multiple)
az account set --subscription "Your Subscription Name"

# Run deployment
./deploy.sh
```

### Method 3: Azure Portal

1. Click the "Deploy to Azure" button in README
2. Fill in the form:
   - **Subscription**: Select your subscription
   - **Location**: Select region (e.g., West Europe)
   - **Admin Password**: Enter secure password
3. Click "Review + create"
4. Click "Create"
5. Wait 10-15 minutes

### Monitoring Deployment Progress

#### PowerShell
```powershell
# Get latest deployment
$deployment = Get-AzSubscriptionDeployment | Sort-Object Timestamp -Descending | Select-Object -First 1

# Watch status
$deployment | Format-List Name, ProvisioningState, Timestamp

# Get detailed status
$deployment.Properties.Dependencies | Format-Table ResourceType, ResourceName
```

#### Azure CLI
```bash
# Get latest deployment
DEPLOYMENT_NAME=$(az deployment sub list --query "[0].name" -o tsv)

# Watch status
az deployment sub show --name $DEPLOYMENT_NAME --query 'properties.provisioningState'

# Get detailed status
az deployment sub show --name $DEPLOYMENT_NAME --query 'properties.outputResources'
```

#### Azure Portal
1. Go to https://portal.azure.com
2. Search "Subscriptions"
3. Click your subscription
4. Click "Deployments" on the left
5. Click the deployment name
6. Monitor "Template", "Outputs", "Deployment details"

## Post-Deployment

### 1. Wait for Session Hosts (5-10 minutes)

Session hosts need time to complete Azure AD join and register.

```powershell
# Check status every 2 minutes
while ($true) {
    Get-AzWvdSessionHost -HostPoolName "avddemo-hp" -ResourceGroupName "rg-avd-demo" |
        Format-Table Name, Status
    Start-Sleep -Seconds 120
}
```

**Expected progression**:
- 0-5 min: "Unavailable" or "Upgrading"
- 5-10 min: Status changes to "Available" ✅

### 2. Assign Users

#### Assign Application Group Access

```powershell
# Get application group ID
$appGroupId = (Get-AzWvdApplicationGroup -Name "avddemo-dag" -ResourceGroupName "rg-avd-demo").Id

# Assign users (repeat for each user)
New-AzRoleAssignment `
  -SignInName "user1@domain.com" `
  -RoleDefinitionName "Desktop Virtualization User" `
  -Scope $appGroupId

New-AzRoleAssignment `
  -SignInName "user2@domain.com" `
  -RoleDefinitionName "Desktop Virtualization User" `
  -Scope $appGroupId
```

#### Assign VM Login Permissions

```powershell
# Get VM IDs
$vm1 = Get-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-0"
$vm2 = Get-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-1"

# Assign to all VMs (repeat for each user)
New-AzRoleAssignment `
  -SignInName "user1@domain.com" `
  -RoleDefinitionName "Virtual Machine User Login" `
  -Scope $vm1.Id

New-AzRoleAssignment `
  -SignInName "user1@domain.com" `
  -RoleDefinitionName "Virtual Machine User Login" `
  -Scope $vm2.Id
```

**💡 Tip**: For admin users, use "Virtual Machine Administrator Login" instead

#### Bulk User Assignment

```powershell
# Define users
$users = @(
    "user1@domain.com",
    "user2@domain.com",
    "user3@domain.com"
)

$appGroupId = (Get-AzWvdApplicationGroup -Name "avddemo-dag" -ResourceGroupName "rg-avd-demo").Id
$vm1 = Get-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-0"
$vm2 = Get-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-1"

# Assign all users
foreach ($user in $users) {
    # App group access
    New-AzRoleAssignment `
        -SignInName $user `
        -RoleDefinitionName "Desktop Virtualization User" `
        -Scope $appGroupId `
        -ErrorAction SilentlyContinue
    
    # VM login
    New-AzRoleAssignment `
        -SignInName $user `
        -RoleDefinitionName "Virtual Machine User Login" `
        -Scope $vm1.Id `
        -ErrorAction SilentlyContinue
    
    New-AzRoleAssignment `
        -SignInName $user `
        -RoleDefinitionName "Virtual Machine User Login" `
        -Scope $vm2.Id `
        -ErrorAction SilentlyContinue
    
    Write-Host "✅ Assigned: $user"
}
```

### 3. Verify Deployment

```powershell
# Complete verification script
Write-Host "=== Deployment Verification ===" -ForegroundColor Cyan

# Check host pool
$hp = Get-AzWvdHostPool -ResourceGroupName "rg-avd-demo" -Name "avddemo-hp"
Write-Host "`n✅ Host Pool: $($hp.Name)" -ForegroundColor Green
Write-Host "   Type: $($hp.HostPoolType)"
Write-Host "   Load Balancer: $($hp.LoadBalancerType)"
Write-Host "   Start VM on Connect: $($hp.StartVMOnConnect)"

# Check session hosts
$hosts = Get-AzWvdSessionHost -HostPoolName "avddemo-hp" -ResourceGroupName "rg-avd-demo"
Write-Host "`n✅ Session Hosts: $($hosts.Count)" -ForegroundColor Green
$hosts | Format-Table Name, Status, Sessions

# Check VMs
$vms = Get-AzVM -ResourceGroupName "rg-avd-demo" -Status
Write-Host "✅ VMs:" -ForegroundColor Green
$vms | Format-Table Name, PowerState

# Check users
$appGroupId = (Get-AzWvdApplicationGroup -Name "avddemo-dag" -ResourceGroupName "rg-avd-demo").Id
$users = Get-AzRoleAssignment -Scope $appGroupId | Where-Object {$_.RoleDefinitionName -eq "Desktop Virtualization User"}
Write-Host "`n✅ Assigned Users: $($users.Count)" -ForegroundColor Green
$users | Format-Table DisplayName, SignInName

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
```

## Validation

### Test Connection

#### Web Client
1. Open https://client.wvd.microsoft.com
2. Login with assigned user account
3. Click "SessionDesktop"
4. Should connect and show Windows 11 desktop

#### Windows Desktop Client
1. Download from https://aka.ms/wvd/clients/windows
2. Install and open
3. Click "Subscribe"
4. Login with assigned user account
5. Desktop appears - click to connect

### Expected Results

✅ Session host status: "Available"  
✅ Desktop icon appears in client  
✅ Connection establishes in < 60 seconds  
✅ Windows 11 desktop loads  
✅ SSO works (no password prompt)  
✅ User profile loads correctly  

### Health Check Verification

```powershell
# Get session host health (PowerShell)
$hosts = Get-AzWvdSessionHost -HostPoolName "avddemo-hp" -ResourceGroupName "rg-avd-demo"
$hosts | Select-Object Name, Status, UpdateState, @{Name="HealthChecks";Expression={$_.HealthCheckResult}}
```

**In Azure Portal**:
1. Azure Virtual Desktop → Host pools → avddemo-hp
2. Session hosts → Click a host
3. Scroll to "Health checks"
4. All should be green except DomainJoinedCheck (expected)

## Next Steps

### For Development/Testing

- [ ] Install applications on session hosts
- [ ] Configure FSLogix profile containers
- [ ] Set up Azure Files for file shares
- [ ] Create custom image with applications

### For Production

- [ ] Enable Azure Monitor for AVD
- [ ] Configure autoscale
- [ ] Set up disaster recovery
- [ ] Implement conditional access policies
- [ ] Enable MFA for all users
- [ ] Configure backup and retention

### Cost Optimization

```powershell
# Set up cost alerts
# (Do this in Azure Portal → Cost Management)

# Enable auto-shutdown (optional)
# (Do this manually per VM in Portal)

# Monitor costs
az consumption usage list --start-date 2024-01-01 --end-date 2024-01-31 | ConvertFrom-Json
```

## Troubleshooting

If you encounter issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Common issues:
- Session hosts stuck in "Unavailable" → See troubleshooting guide
- Can't connect → Check user roles and VM status
- SSO not working → Verify RDP properties and VM login roles

## Cleanup

When done with the demo:

```powershell
# Run cleanup script
cd scripts
.\cleanup.ps1

# Or manually delete
Remove-AzResourceGroup -Name "rg-avd-demo" -Force
```

**This stops all billing immediately**

## Support

- **Documentation**: See other files in /docs
- **Issues**: Create GitHub issue
- **Discussions**: Use GitHub Discussions
- **Azure Support**: For production issues

---

**🎉 Deployment complete! Your AVD environment is ready to use.**
