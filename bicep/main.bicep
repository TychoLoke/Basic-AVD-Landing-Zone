// Azure Virtual Desktop - Complete Demo Environment
// Cost-optimized with Azure AD Join - Ready to Deploy

targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'westeurope'

@description('Resource group name')
param resourceGroupName string = 'rg-avd-demo'

@description('Prefix for all resources')
param prefix string = 'avddemo'

@description('Admin username for session hosts')
param adminUsername string = 'avdadmin'

@description('Admin password for session hosts')
@secure()
param adminPassword string

@description('Number of session hosts to deploy')
@minValue(1)
@maxValue(3)
param sessionHostCount int = 2

@description('VM size for session hosts')
@allowed([
  'Standard_B2s'
  'Standard_B2ms'
  'Standard_D2s_v5'
])
param vmSize string = 'Standard_B2ms'

@description('Virtual network address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet address prefix')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Maximum session limit per host')
param maxSessionLimit int = 10

@description('Load balancer type')
@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param loadBalancerType string = 'BreadthFirst'

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

// Deploy AVD infrastructure
module avdInfra 'modules/avd-infrastructure.bicep' = {
  scope: rg
  name: 'avd-infrastructure-deployment'
  params: {
    location: location
    prefix: prefix
    adminUsername: adminUsername
    adminPassword: adminPassword
    sessionHostCount: sessionHostCount
    vmSize: vmSize
    vnetAddressPrefix: vnetAddressPrefix
    subnetAddressPrefix: subnetAddressPrefix
    maxSessionLimit: maxSessionLimit
    loadBalancerType: loadBalancerType
  }
}

output hostPoolName string = avdInfra.outputs.hostPoolName
output workspaceName string = avdInfra.outputs.workspaceName
output applicationGroupName string = avdInfra.outputs.applicationGroupName
output vnetName string = avdInfra.outputs.vnetName
