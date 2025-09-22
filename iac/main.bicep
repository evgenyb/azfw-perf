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
    firewallSKU: 'Premium'
  }
}

module firewallRouteTable 'br/public:avm/res/network/route-table:0.5.0' = {
  name: 'deploy-route-firewall'
  scope: resourceGroup(resourceGroupName)
  params: {
    // Required parameters
    name: 'to-firewall'
    // Non-required parameters
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: hub.outputs.firewallPrivateIP
        }
      }
    ]
  }
}

module servers 'modules/server.bicep' = [for i in range(1, 4): {
  name: 'deploy-servers${i}-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    parIndex: i
    parLocation: location
    parAddressRange: '10.9.1${i}.0/24'
    parWorkspaceResourceId: workspace.outputs.resourceId    
    adminUsername: adminUsername
    adminPassword: adminPassword
    hubVnetId: hub.outputs.hubVnetId
    vmSize: 'Standard_D2ds_v6'
    firewallRouteResourceId: firewallRouteTable.outputs.resourceId
  }  
}]

module clients 'modules/client.bicep' = [for i in range(1, 4): {
  name: 'deploy-clients${i}-${resourcePrefix}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    servers
  ]
  params: {
    parIndex: i
    parLocation: location
    parAddressRange: '10.9.2${i}.0/24'
    parWorkspaceResourceId: workspace.outputs.resourceId    
    adminUsername: adminUsername
    adminPassword: adminPassword
    hubVnetId: hub.outputs.hubVnetId
    serverVNetId: servers[i - 1].outputs.serverVNetId
    vmSize: 'Standard_D2ds_v6'
    firewallRouteResourceId: firewallRouteTable.outputs.resourceId
  }  
}]

