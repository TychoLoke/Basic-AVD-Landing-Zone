// AVD Infrastructure Module - Complete with Azure AD Join
targetScope = 'resourceGroup'

param location string
param prefix string
param adminUsername string
@secure()
param adminPassword string
param sessionHostCount int
param vmSize string
param vnetAddressPrefix string
param subnetAddressPrefix string
param maxSessionLimit int
param loadBalancerType string
param currentTime string = utcNow()

// Variables
var hostPoolName = '${prefix}-hp'
var workspaceName = '${prefix}-ws'
var appGroupName = '${prefix}-dag'
var vnetName = '${prefix}-vnet'
var subnetName = '${prefix}-subnet'
var nsgName = '${prefix}-nsg'
var vmPrefix = '${prefix}-sh'
var registrationExpirationTime = dateTimeAdd(currentTime, 'P7D')

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Host Pool
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
  name: hostPoolName
  location: location
  properties: {
    hostPoolType: 'Pooled'
    loadBalancerType: loadBalancerType
    maxSessionLimit: maxSessionLimit
    preferredAppGroupType: 'Desktop'
    startVMOnConnect: true
    validationEnvironment: false
    registrationInfo: {
      expirationTime: registrationExpirationTime
      registrationTokenOperation: 'Update'
    }
  }
}

// Workspace
resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = {
  name: workspaceName
  location: location
  properties: {
    friendlyName: '${prefix} Demo Workspace'
    description: 'Cost-optimized demo workspace'
    applicationGroupReferences: [
      appGroup.id
    ]
  }
}

// Desktop Application Group
resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: appGroupName
  location: location
  properties: {
    hostPoolArmPath: hostPool.id
    applicationGroupType: 'Desktop'
    friendlyName: '${prefix} Desktop'
    description: 'Demo desktop application group'
  }
}

// Network Interfaces for Session Hosts
resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = [for i in range(0, sessionHostCount): {
  name: '${vmPrefix}-${i}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]

// Session Host VMs with System-Assigned Managed Identity
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = [for i in range(0, sessionHostCount): {
  name: '${vmPrefix}-${i}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-11'
        sku: 'win11-23h2-avd'
        version: 'latest'
      }
      osDisk: {
        name: '${vmPrefix}-${i}-osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: '${vmPrefix}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    licenseType: 'Windows_Client'
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}]

// Azure AD Login Extension - MUST BE FIRST
resource aadLoginExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [for i in range(0, sessionHostCount): {
  name: 'AADLoginForWindows'
  parent: vm[i]
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: ''
    }
  }
}]

// AVD Agent Extension - MUST RUN AFTER AAD LOGIN
resource avdAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [for i in range(0, sessionHostCount): {
  name: 'DSC'
  parent: vm[i]
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostPool.name
        registrationInfoToken: reference(hostPool.id).registrationInfo.token
        aadJoin: true
      }
    }
  }
  dependsOn: [
    aadLoginExtension[i]
  ]
}]

// Outputs
output hostPoolName string = hostPool.name
output workspaceName string = workspace.name
output applicationGroupName string = appGroup.name
output vnetName string = vnet.name
output hostPoolToken string = reference(hostPool.id).registrationInfo.token
output subnetId string = vnet.properties.subnets[0].id
