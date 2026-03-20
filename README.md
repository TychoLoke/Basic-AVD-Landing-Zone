# Azure Virtual Desktop (AVD) - Cost-Optimized Demo Environment

[![Deployment Guide](https://img.shields.io/badge/Deployment-Guide-0078D4?style=for-the-badge)](./docs/DEPLOYMENT-GUIDE.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A complete, production-ready Azure Virtual Desktop environment optimized for cost and demos. Features Azure AD join, SSO, and automatic VM startup.

## ✨ Features

- ✅ **Azure AD Join** - No domain controller required
- ✅ **Single Sign-On (SSO)** - Seamless authentication
- ✅ **Cost Optimized** - B-series VMs, auto-shutdown capability
- ✅ **Start VM on Connect** - VMs auto-start when users connect
- ✅ **Production Ready** - Follows Azure best practices
- ✅ **Easy Deployment** - One command to deploy everything

## 💰 Cost Estimate

| Usage Pattern | Monthly Cost (EUR) |
|--------------|-------------------|
| 8 hours/day | €130-150 |
| 24/7 | €240 |
| VMs stopped | €10 (storage only) |

*Costs based on 2x Standard_B2ms VMs in West Europe*

## 🚀 Quick Start

### Prerequisites

- Azure subscription with Contributor access
- Azure PowerShell or Azure CLI installed
- Bicep CLI (auto-installed with Azure CLI)

### Option 1: PowerShell Deployment

```powershell
# Clone repository
git clone https://github.com/TychoLoke/Basic-AVD-Landing-Zone.git
cd Basic-AVD-Landing-Zone

# Login to Azure
Connect-AzAccount

# Edit parameters (change password!)
notepad parameters/avd-demo.parameters.json

# Deploy
./scripts/deploy.ps1
```

### Option 2: Azure CLI Deployment

```bash
# Clone repository
git clone https://github.com/TychoLoke/Basic-AVD-Landing-Zone.git
cd Basic-AVD-Landing-Zone

# Login to Azure
az login

# Edit parameters (change password!)
nano parameters/avd-demo.parameters.json

# Deploy
./scripts/deploy.sh
```

### Option 3: Deploy to Azure Button

Use the deployment guide linked at the top of this README for a guided setup flow and post-deployment validation steps.

## 📋 What Gets Deployed

### AVD Resources
- **Host Pool**: Pooled with BreadthFirst load balancing
- **Workspace**: Single workspace for all users
- **Application Group**: Desktop application group
- **2 Session Hosts**: Windows 11 Multi-session (23H2)

### Compute
- **VM Size**: Standard_B2ms (2 vCPU, 8GB RAM)
- **OS Disk**: 128GB Standard HDD
- **Identity**: System-assigned managed identity
- **License**: Windows Hybrid Benefit enabled

### Networking
- **Virtual Network**: 10.0.0.0/16
- **Subnet**: 10.0.1.0/24
- **NSG**: Basic security rules

### Extensions
- **AADLoginForWindows**: Azure AD authentication
- **DSC**: AVD agent configuration

## 🎯 Post-Deployment Steps

### 1. Assign Users

```powershell
# Get application group ID
$appGroupId = (Get-AzWvdApplicationGroup -Name "avddemo-dag" -ResourceGroupName "rg-avd-demo").Id

# Assign user
New-AzRoleAssignment `
  -SignInName "user@yourdomain.com" `
  -RoleDefinitionName "Desktop Virtualization User" `
  -Scope $appGroupId
```

### 2. Enable SSO (Already Configured!)

SSO is pre-configured with `enablerdsaadauth:i:1`. Users will experience seamless login when using the Windows Desktop client.

### 3. Connect

**Web Client**: https://client.wvd.microsoft.com  
**Windows Client**: https://aka.ms/wvd/clients/windows  
**macOS Client**: https://aka.ms/wvd/clients/mac

## 📁 Repository Structure

```
Basic-AVD-Landing-Zone/
├── bicep/
│   ├── main.bicep                    # Main deployment template
│   └── modules/
│       └── avd-infrastructure.bicep  # Infrastructure module
├── parameters/
│   └── avd-demo.parameters.json      # Configuration parameters
├── scripts/
│   ├── deploy.ps1                    # PowerShell deployment script
│   ├── deploy.sh                     # Bash deployment script
│   └── cleanup.ps1                   # Cleanup script
├── docs/
│   ├── DEPLOYMENT-GUIDE.md           # Detailed deployment guide
│   ├── TROUBLESHOOTING.md            # Common issues and solutions
│   └── ARCHITECTURE.md               # Architecture overview
├── .github/
│   └── workflows/
│       └── validate.yml              # Bicep validation workflow
├── .gitignore
├── LICENSE
├── README.md
└── CONTRIBUTING.md
```

## 🔧 Configuration

### Key Parameters

Edit `parameters/avd-demo.parameters.json`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `location` | `westeurope` | Azure region |
| `prefix` | `avddemo` | Resource name prefix |
| `adminPassword` | *required* | Local admin password |
| `sessionHostCount` | `2` | Number of VMs (1-3) |
| `vmSize` | `Standard_B2ms` | VM size |
| `maxSessionLimit` | `10` | Max sessions per host |

### Custom RDP Properties

The deployment includes optimized RDP properties:
- Azure AD authentication enabled
- Clipboard redirection disabled (security)
- Printer redirection disabled (performance)
- Video playback optimization enabled

## 🛠️ Management

### Start/Stop VMs

```powershell
# Stop all VMs (save money)
Get-AzVM -ResourceGroupName "rg-avd-demo" | Stop-AzVM -Force

# Start all VMs
Get-AzVM -ResourceGroupName "rg-avd-demo" | Start-AzVM
```

### Check Session Host Status

```powershell
Get-AzWvdSessionHost -HostPoolName "avddemo-hp" -ResourceGroupName "rg-avd-demo" | 
  Format-Table Name, Status, Sessions
```

### View Active Sessions

```powershell
Get-AzWvdUserSession -HostPoolName "avddemo-hp" -ResourceGroupName "rg-avd-demo" |
  Format-Table UserPrincipalName, SessionState, CreateTime
```

## 🔍 Troubleshooting

### Session Hosts Show "Unavailable"

**Solution**: Wait 10 minutes after deployment for Azure AD join to complete, then restart VMs if needed.

```powershell
Restart-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-0"
Restart-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-1"
```

### SSO Not Working

**Solution**: Ensure user has VM login permissions.

```powershell
$vm = Get-AzVM -ResourceGroupName "rg-avd-demo" -Name "avddemo-sh-0"
New-AzRoleAssignment `
  -SignInName "user@domain.com" `
  -RoleDefinitionName "Virtual Machine User Login" `
  -Scope $vm.Id
```

### Can't Connect to Desktop

**Checklist**:
1. ✅ Session hosts show "Available" status?
2. ✅ User assigned "Desktop Virtualization User" role?
3. ✅ User assigned "Virtual Machine User Login" role?
4. ✅ VMs are running?

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more solutions.

## 📊 Monitoring

### Azure Monitor Integration

The deployment doesn't include monitoring by default to minimize costs. To add monitoring:

1. Enable diagnostic settings on the host pool
2. Create Log Analytics workspace
3. Configure Insights for AVD

### Cost Management

Set up cost alerts:
1. Azure Portal → Cost Management
2. Budgets → Create
3. Set budget: €200/month
4. Alert at 80% (€160)

## 🔐 Security Best Practices

1. **Change Default Password**: Immediately change the admin password after deployment
2. **Enable MFA**: Require multi-factor authentication for all users
3. **Conditional Access**: Configure conditional access policies
4. **Just-In-Time Access**: Use Azure Bastion for administrative access
5. **Update Management**: Enable automatic updates

## 🚀 Advanced Scenarios

### Multi-Region Deployment

Deploy to multiple regions for disaster recovery or geographic distribution.

### Custom Images

Replace the marketplace image with your own custom image containing pre-installed applications.

### FSLogix Profile Containers

Add Azure Files or Azure NetApp Files for user profile management.

### GPU-Enabled VMs

Change `vmSize` parameter to use NV-series VMs for graphics-intensive workloads.

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- Follows [Azure Landing Zones](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/) best practices
- Optimized based on [AVD documentation](https://docs.microsoft.com/azure/virtual-desktop/)

## 📧 Support

- **Issues**: Use GitHub Issues for bug reports and feature requests
- **Discussions**: Use GitHub Discussions for questions and community support
- **Azure Support**: For production issues, contact Azure Support

## 🔗 Related Resources

- [Azure Virtual Desktop Documentation](https://docs.microsoft.com/azure/virtual-desktop/)
- [AVD Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [AVD Tech Community](https://techcommunity.microsoft.com/t5/azure-virtual-desktop/bd-p/AzureVirtualDesktop)

---

**⭐ If this project helped you, please give it a star!**
