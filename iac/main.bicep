targetScope = 'subscription'
param location string

import { getResourcePrefix, hubAddressRange, adminUsername, adminPassword } from 'variables.bicep'

var resourcePrefix = getResourcePrefix(location)
var resourceGroupName = 'rg-${resourcePrefix}'
module rg 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'deploy-${resourceGroupName}'
  params: {
    name: resourceGroupName
    tags: {
      Environment: 'IaC'
    }
  }
}

module workspace 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  name: 'deploy-law'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    rg
  ]
  params: {
    name: 'law-${resourcePrefix}'
    location: location
  }
}

module hub 'modules/hub.bicep' = {
  name: 'deploy-hub-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    parLocation: location
    parAddressRange: hubAddressRange
    parWorkspaceResourceId: workspace.outputs.resourceId    
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: 'Standard_B1s'
  }
}

module servers 'modules/spoke.bicep' = [for i in range(1, 4): {
  name: 'deploy-servers${i}-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    parIndex: i
    parLocation: location
    parAddressRange: '10.9.${i}.0/24'
    parWorkspaceResourceId: workspace.outputs.resourceId    
    adminUsername: adminUsername
    adminPassword: adminPassword
    hubVnetId: hub.outputs.hubVnetId
    vmSize: 'Standard_D2ds_v6'
    commandToExecute: 'apt-get update && apt-get install -y iperf3 && iperf3 -s'
  }  
}]

module clients 'modules/spoke.bicep' = [for i in range(5, 8): {
  name: 'deploy-clients${i}-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    servers
  ]
  params: {
    parIndex: i
    parLocation: location
    parAddressRange: '10.9.${i}.0/24'
    parWorkspaceResourceId: workspace.outputs.resourceId    
    adminUsername: adminUsername
    adminPassword: adminPassword
    hubVnetId: hub.outputs.hubVnetId
    vmSize: 'Standard_D2ds_v6'
    commandToExecute: 'apt-get install -y iperf3'
  }  
}]

