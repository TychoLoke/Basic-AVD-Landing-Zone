# Architecture Overview

This document describes the architecture of the AVD demo environment.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Azure Subscription                     │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │             Resource Group: rg-avd-demo                 │ │
│  │                                                          │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │         AVD Control Plane                        │   │ │
│  │  │  ┌──────────────┐  ┌──────────────┐            │   │ │
│  │  │  │  Host Pool   │  │  Workspace   │            │   │ │
│  │  │  │  avddemo-hp  │  │  avddemo-ws  │            │   │ │
│  │  │  └──────────────┘  └──────────────┘            │   │ │
│  │  │         │                  │                     │   │ │
│  │  │         │                  │                     │   │ │
│  │  │  ┌──────────────────────────┐                   │   │ │
│  │  │  │   Application Group      │                   │   │ │
│  │  │  │     avddemo-dag          │                   │   │ │
│  │  │  │   (Desktop Type)          │                   │   │ │
│  │  │  └──────────────────────────┘                   │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  │                                                          │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │         Compute Resources                        │   │ │
│  │  │                                                   │   │ │
│  │  │  ┌─────────────────┐  ┌─────────────────┐       │   │ │
│  │  │  │  Session Host 0  │  │  Session Host 1  │       │   │ │
│  │  │  │  avddemo-sh-0    │  │  avddemo-sh-1    │       │   │ │
│  │  │  │                  │  │                  │       │   │ │
│  │  │  │  Standard_B2ms   │  │  Standard_B2ms   │       │   │ │
│  │  │  │  Windows 11      │  │  Windows 11      │       │   │ │
│  │  │  │  Multi-session   │  │  Multi-session   │       │   │ │
│  │  │  │                  │  │                  │       │   │ │
│  │  │  │  Azure AD Joined │  │  Azure AD Joined │       │   │ │
│  │  │  └─────────────────┘  └─────────────────┘       │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  │                                                          │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │         Networking                               │   │ │
│  │  │                                                   │   │ │
│  │  │  ┌─────────────────────────────────────────┐     │   │ │
│  │  │  │  Virtual Network: avddemo-vnet           │     │   │ │
│  │  │  │  Address Space: 10.0.0.0/16             │     │   │ │
│  │  │  │                                           │     │   │ │
│  │  │  │  ┌───────────────────────────────────┐  │     │   │ │
│  │  │  │  │  Subnet: avddemo-subnet           │  │     │   │ │
│  │  │  │  │  Address: 10.0.1.0/24             │  │     │   │ │
│  │  │  │  │                                     │  │     │   │ │
│  │  │  │  │  ┌────────────┐  ┌────────────┐  │  │     │   │ │
│  │  │  │  │  │   NIC-0    │  │   NIC-1    │  │  │     │   │ │
│  │  │  │  │  └────────────┘  └────────────┘  │  │     │   │ │
│  │  │  │  └───────────────────────────────────┘  │     │   │ │
│  │  │  └─────────────────────────────────────────┘     │   │ │
│  │  │                                                   │   │ │
│  │  │  ┌─────────────────────────────────────────┐     │   │ │
│  │  │  │  Network Security Group: avddemo-nsg    │     │   │ │
│  │  │  │  - Allow RDP (port 3389)                │     │   │ │
│  │  │  └─────────────────────────────────────────┘     │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

            ┌──────────────────────────────────┐
            │    Users (Azure AD)              │
            │                                  │
            │  ┌────────┐  ┌────────┐         │
            │  │ User 1 │  │ User 2 │   ...   │
            │  └────────┘  └────────┘         │
            └──────────────────────────────────┘
                          │
                          │ HTTPS (443)
                          │
            ┌──────────────────────────────────┐
            │    AVD Gateway (Microsoft)       │
            └──────────────────────────────────┘
                          │
                          │ RDP over HTTPS
                          │
            ┌──────────────────────────────────┐
            │    Session Hosts (VMs)           │
            └──────────────────────────────────┘
```

## Components

### AVD Control Plane (Managed by Microsoft)

#### Host Pool (`avddemo-hp`)
- **Type**: Pooled
- **Load Balancing**: BreadthFirst
- **Max Sessions**: 10 per host
- **Start VM on Connect**: Enabled
- **Custom RDP Properties**: 
  - `enablerdsaadauth:i:1` (Azure AD SSO)
  - Clipboard disabled
  - Printer redirection disabled
  - Video optimization enabled

#### Workspace (`avddemo-ws`)
- Friendly name: "avddemo Demo Workspace"
- References application group
- User-facing workspace in client

#### Application Group (`avddemo-dag`)
- **Type**: Desktop
- **Published**: Full Windows desktop
- **Users**: Assigned via RBAC role "Desktop Virtualization User"

### Session Hosts

#### Virtual Machines
- **Name Pattern**: `avddemo-sh-{0,1}`
- **Size**: Standard_B2ms
  - vCPUs: 2
  - Memory: 8 GB
  - Temp Disk: 16 GB
- **OS Disk**: 128 GB Standard HDD
- **Image**: Windows 11 Multi-session (23H2)
- **License**: Windows Hybrid Benefit
- **Identity**: System-assigned managed identity

#### Extensions

| Extension | Purpose | Order |
|-----------|---------|-------|
| AADLoginForWindows | Azure AD authentication | 1 (first) |
| DSC | AVD agent installation | 2 (after AAD) |

### Networking

#### Virtual Network
- **Address Space**: 10.0.0.0/16
- **Subnet**: 10.0.1.0/24 (254 usable IPs)
- **DNS**: Azure-provided DNS

#### Network Security Group
- **Inbound**: 
  - Allow RDP (3389) from any source
  - (In production: Restrict to specific IPs)
- **Outbound**: 
  - Default allow all (required for AVD)

#### Network Interfaces
- Private IP allocation: Dynamic
- Accelerated networking: Not enabled (B-series doesn't support it)
- Delete with VM: Yes

### Identity & Access Management

#### Azure AD Integration
- VMs are Azure AD joined
- No on-premises Active Directory required
- Conditional access policies can be applied

#### RBAC Roles

| Role | Scope | Users | Purpose |
|------|-------|-------|---------|
| Desktop Virtualization User | Application Group | End users | Access to desktop |
| Virtual Machine User Login | Each VM | End users | Login to Windows |
| Virtual Machine Administrator Login | Each VM | Admins | Admin access to Windows |
| Owner | Resource Group | Deployer | Manage resources |

### Authentication Flow

```
User launches AVD client
         │
         ▼
Authenticates with Azure AD
         │
         ▼
Receives feed from Workspace
         │
         ▼
Clicks SessionDesktop
         │
         ▼
AVD Gateway brokers connection
         │
         ▼
VM starts (if stopped)
         │
         ▼
RDP connection established
         │
         ▼
Azure AD SSO (no password prompt)
         │
         ▼
Windows desktop loads
```

## Data Flow

### User Connection
1. Client connects to AVD Gateway (HTTPS:443)
2. Gateway authenticates user (Azure AD)
3. Gateway determines available session hosts
4. RDP traffic tunneled through gateway (port 443)
5. Session established on available host

### Session Host Registration
1. VM boots
2. AADLoginForWindows extension joins VM to Azure AD
3. DSC extension installs AVD agent
4. Agent registers with host pool using token
5. Agent maintains heartbeat with control plane

## Security Architecture

### Network Security
- No public IPs on session hosts
- Outbound traffic allowed for:
  - Azure AD authentication
  - AVD control plane
  - Windows updates
  - Azure services

### Identity Security
- Azure AD authentication
- Multi-factor authentication supported
- Conditional access policies supported
- No local user accounts (except emergency admin)

### Data Security
- Data at rest: Encrypted (Azure disk encryption)
- Data in transit: TLS 1.2+
- Session isolation: Each user gets separate session
- No data persists between sessions (no FSLogix in demo)

## Scalability

### Current Configuration
- 2 session hosts
- Up to 20 concurrent users (10 per host)

### Scaling Options

#### Vertical Scaling
Change VM size in parameters:
- Standard_B2s (1 vCPU, 4GB) - Lower cost
- Standard_D4s_v5 (4 vCPU, 16GB) - Better performance

#### Horizontal Scaling
Increase session host count:
- Max 3 hosts in current template
- Edit template for more hosts

### Autoscaling
Not included in demo. For production:
- Configure autoscale rules
- Based on time or load
- Can reduce to 0 hosts when not in use

## Cost Breakdown

### Monthly Costs (8 hrs/day, West Europe)

| Component | Cost | Notes |
|-----------|------|-------|
| 2x Standard_B2ms VMs | €110 | Compute |
| 2x OS Disks (128 GB Standard) | €10 | Storage |
| Network egress | €5 | Minimal |
| AVD Control Plane | €0 | No charge |
| **Total** | **~€125** | Approximate |

### Cost Optimization Features
- Start VM on Connect (auto-start/stop)
- B-series burstable VMs (cheaper than D-series)
- Standard HDD (cheaper than SSD)
- No FSLogix (saves storage costs)
- Windows Hybrid Benefit (saves 40%)

## High Availability

### Current Configuration
- **SLA**: 99.9% (single VM with managed disk)
- No redundancy across availability zones
- No cross-region redundancy

### Production Recommendations
- Deploy across availability zones
- Use 3+ session hosts for redundancy
- Implement secondary region for DR
- Enable Azure Site Recovery

## Monitoring & Diagnostics

### Included
- Azure Activity Log (free)
- Resource health alerts
- VM insights (if enabled)

### Not Included (to minimize costs)
- Log Analytics workspace
- Diagnostic settings
- Azure Monitor for AVD
- Application Insights

### Recommended for Production
1. Enable diagnostic settings
2. Create Log Analytics workspace
3. Configure AVD Insights
4. Set up alerts for:
   - Session host availability
   - User connection failures
   - Performance degradation

## Limitations

### Demo-Specific Limitations
- No user profile management (FSLogix)
- No application virtualization (MSIX)
- No custom images
- No monitoring/alerting
- Basic networking (no Azure Firewall)
- Single region deployment

### Platform Limitations
- Max 10,000 session hosts per host pool
- Max 200 application groups per workspace
- Max 500 applications per host pool
- B-series VMs: No accelerated networking

## Future Enhancements

Potential additions:
- [ ] FSLogix profile containers
- [ ] Azure Files integration
- [ ] Custom golden image
- [ ] Azure Monitor Workbook
- [ ] Auto-scaling rules
- [ ] Multi-region deployment
- [ ] Azure Firewall integration
- [ ] Application publishing
- [ ] RemoteApp configuration

## References

- [AVD Architecture Documentation](https://docs.microsoft.com/azure/architecture/example-scenario/wvd/windows-virtual-desktop)
- [Network Guidelines](https://docs.microsoft.com/azure/virtual-desktop/rdp-bandwidth)
- [Security Best Practices](https://docs.microsoft.com/azure/virtual-desktop/security-guide)
- [Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
