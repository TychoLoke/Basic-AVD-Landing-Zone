# Troubleshooting Guide

Common issues and solutions for the AVD demo environment.

## Table of Contents

- [Deployment Issues](#deployment-issues)
- [Session Host Issues](#session-host-issues)
- [Connection Issues](#connection-issues)
- [SSO Issues](#sso-issues)
- [Performance Issues](#performance-issues)

## Deployment Issues

### Error: "Conflict" when assigning roles

**Symptom**: Role assignment fails with "Conflict" error

**Cause**: Role is already assigned

**Solution**: This is not actually an error - the role already exists. You can ignore this message.

### Error: "Invalid template" during deployment

**Symptom**: Bicep validation or deployment fails

**Cause**: Usually a syntax error or incorrect parameter

**Solution**:
```powershell
# Validate template locally
az bicep build --file bicep/main.bicep

# Check parameter file
Get-Content parameters/avd-demo.parameters.json | ConvertFrom-Json
```

### Error: "Quota exceeded"

**Symptom**: VM deployment fails with quota error

**Cause**: Not enough quota for Standard_B2ms VMs in the region

**Solution**:
1. Request quota increase in Azure Portal
2. OR use a different region
3. OR use Standard_B2s (smaller VM)

## Session Host Issues

### Session hosts stuck in "Unavailable" status

**Symptom**: After deployment, session hosts show "Unavailable" for more than 15 minutes

**Cause**: Azure AD join or agent registration not complete

**Solution**:

```powershell
# Check VM status
Get-AzVM -ResourceGroupName "rg-avd-demo" -Status | 
  Format-Table Name, PowerState

# If VMs are running, check extensions
Get-AzVMExtension -ResourceGroupName "rg-avd-demo" -VMName "avddemo-sh-0" |
  Format-Table Name, ProvisioningState

# Restart VMs to complete registration
Restart-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-0"
Restart-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-1"

# Wait 5 minutes and check status again
Start-Sleep -Seconds 300
Get-AzWvdSessionHost -HostPoolName "avddemo-hp" -ResourceGroupName "rg-avd-demo" |
  Format-Table Name, Status
```

### Health checks failing

**Symptom**: Portal shows failed health checks

**Common failures and solutions**:

| Health Check | Cause | Solution |
|--------------|-------|----------|
| DomainJoinedCheck | Expected - using Azure AD | Ignore - we use Azure AD join instead |
| DomainTrustCheck | Expected - using Azure AD | Ignore - we use Azure AD join instead |
| AADJoinedHealthCheck | Azure AD join failed | Restart VMs, check AADLoginForWindows extension |
| SxSStackListenerCheck | AVD agent not running | Check DSC extension, restart VMs |
| UrlsAccessibleCheck | Network connectivity issue | Check NSG rules, outbound connectivity |

Check health in portal:
```
Azure Portal → Azure Virtual Desktop → Host pools → avddemo-hp → Session hosts → Click a host → Health checks
```

### VMs keep shutting down

**Symptom**: VMs stop automatically

**Cause**: Auto-shutdown policy or Start VM on Connect issues

**Solution**:
```powershell
# Check if auto-shutdown is configured
Get-AzResource -ResourceGroupName "rg-avd-demo" -ResourceType "Microsoft.DevTestLab/schedules"

# Disable auto-shutdown if found
Remove-AzResource -ResourceId "<schedule-resource-id>" -Force

# Verify Start VM on Connect is enabled
Get-AzWvdHostPool -Name "avddemo-hp" -ResourceGroupName "rg-avd-demo" |
  Select-Object StartVMOnConnect
```

## Connection Issues

### "We couldn't connect to the gateway"

**Symptom**: Connection fails immediately with gateway error

**Cause**: Network connectivity or incorrect workspace

**Solution**:
```powershell
# Verify workspace has correct application group
Get-AzWvdWorkspace -Name "avddemo-ws" -ResourceGroupName "rg-avd-demo" |
  Select-Object ApplicationGroupReference

# Should show: .../applicationgroups/avddemo-dag
```

### "Session timeout"

**Symptom**: Connection times out during establishment

**Cause**: VM is starting up (first connection) or stopped

**Solution**:
```powershell
# Start VMs manually
Start-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-0"
Start-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-1"

# Wait 2 minutes for VMs to start
Start-Sleep -Seconds 120

# Try connecting again
```

### "Sign in failed"

**Symptom**: Authentication fails at Windows login screen

**Cause**: User doesn't have VM login permissions

**Solution**:
```powershell
# Assign VM login role
$vm = Get-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-0"
New-AzRoleAssignment `
  -SignInName "user@domain.com" `
  -RoleDefinitionName "Virtual Machine User Login" `
  -Scope $vm.Id

# Repeat for second VM
$vm2 = Get-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-1"
New-AzRoleAssignment `
  -SignInName "user@domain.com" `
  -RoleDefinitionName "Virtual Machine User Login" `
  -Scope $vm2.Id
```

## SSO Issues

### SSO not working - prompted for password

**Symptom**: Windows login screen appears instead of automatic login

**Cause**: RDP property not set or VM login role missing

**Solution**:
```powershell
# Check if SSO is enabled
Get-AzWvdHostPool -ResourceGroupName "rg-avd-demo" -Name "avddemo-hp" |
  Select-Object CustomRdpProperty

# Should contain: enablerdsaadauth:i:1

# If missing, enable it:
Update-AzWvdHostPool `
  -ResourceGroupName "rg-avd-demo" `
  -Name "avddemo-hp" `
  -CustomRdpProperty "enablerdsaadauth:i:1"

# Ensure VM login role is assigned (see above)
```

### Wrong account selected for SSO

**Symptom**: SSO tries to use wrong account

**Cause**: Multiple accounts in Windows credential manager

**Solution**:
1. Open Windows Credential Manager
2. Remove all "Windows Virtual Desktop" credentials
3. Reconnect - will prompt to select correct account

## Performance Issues

### Slow desktop performance

**Symptom**: Desktop is laggy or unresponsive

**Cause**: Multiple possible causes

**Solutions**:

```powershell
# Check session host load
Get-AzWvdSessionHost -HostPoolName "avddemo-hp" -ResourceGroupName "rg-avd-demo" |
  Format-Table Name, Status, Session, @{Name="Load";Expression={$_.Sessions / 10 * 100}}

# If overloaded, add more session hosts or reduce max sessions
# Increase VM size if needed
Update-AzWvdHostPool `
  -ResourceGroupName "rg-avd-demo" `
  -Name "avddemo-hp" `
  -MaxSessionLimit 5  # Reduce from 10
```

**Optimize RDP properties**:
```powershell
$rdpProperties = @(
    "drivestoredirect:s:"
    "audiomode:i:0"
    "videoplaybackmode:i:1"
    "redirectclipboard:i:0"
    "redirectprinters:i:0"
    "devicestoredirect:s:*"
    "use multimon:i:1"
    "enablerdsaadauth:i:1"
) -join ";"

Update-AzWvdHostPool `
  -ResourceGroupName "rg-avd-demo" `
  -Name "avddemo-hp" `
  -CustomRdpProperty $rdpProperties
```

### Slow connection establishment

**Symptom**: Takes a long time to connect

**Cause**: VM is stopped and needs to start

**Expected**: First connection takes 2-3 minutes with Start VM on Connect

**Solution**: This is normal. Subsequent connections are faster.

## Diagnostic Commands

### Complete health check

```powershell
# Install AVD module
Install-Module -Name Az.DesktopVirtualization -Force

# Check all components
Write-Host "=== Host Pool ===" -ForegroundColor Cyan
Get-AzWvdHostPool -ResourceGroupName "rg-avd-demo" -Name "avddemo-hp" |
  Format-List HostPoolType, LoadBalancerType, MaxSessionLimit, StartVMOnConnect

Write-Host "`n=== Session Hosts ===" -ForegroundColor Cyan
Get-AzWvdSessionHost -HostPoolName "avddemo-hp" -ResourceGroupName "rg-avd-demo" |
  Format-Table Name, Status, Session, AllowNewSession

Write-Host "`n=== VMs ===" -ForegroundColor Cyan
Get-AzVM -ResourceGroupName "rg-avd-demo" -Status |
  Format-Table Name, PowerState

Write-Host "`n=== Application Group Users ===" -ForegroundColor Cyan
$appGroupId = (Get-AzWvdApplicationGroup -Name "avddemo-dag" -ResourceGroupName "rg-avd-demo").Id
Get-AzRoleAssignment -Scope $appGroupId |
  Where-Object {$_.RoleDefinitionName -eq "Desktop Virtualization User"} |
  Format-Table DisplayName, SignInName

Write-Host "`n=== VM Login Users ===" -ForegroundColor Cyan
$vm1Id = (Get-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-0").Id
Get-AzRoleAssignment -Scope $vm1Id |
  Where-Object {$_.RoleDefinitionName -like "*Virtual Machine*Login"} |
  Format-Table DisplayName, RoleDefinitionName, SignInName
```

## Getting Help

If you're still experiencing issues:

1. **Check Azure Service Health**: https://status.azure.com
2. **Review deployment logs** in Azure Portal
3. **Check VM boot diagnostics** (if enabled)
4. **Review extension logs** on the VM:
   - AADLoginForWindows: `C:\WindowsAzure\Logs\Plugins\Microsoft.Azure.ActiveDirectory.AADLoginForWindows\`
   - DSC: `C:\WindowsAzure\Logs\Plugins\Microsoft.Powershell.DSC\`
5. **Create GitHub Issue** with full error details
6. **Contact Azure Support** for production issues

## Useful Links

- [AVD Troubleshooting](https://docs.microsoft.com/azure/virtual-desktop/troubleshoot)
- [Azure AD Authentication](https://docs.microsoft.com/azure/virtual-desktop/configure-single-sign-on)
- [Health Check Reference](https://docs.microsoft.com/azure/virtual-desktop/troubleshoot-agent)
