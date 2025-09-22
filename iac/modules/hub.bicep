targetScope = 'resourceGroup'

param parLocation string
param parAddressRange string
param parWorkspaceResourceId string
param adminUsername string
@secure()
param adminPassword string
param vmSize string
param firewallSKU string

var varVNetName = 'vnet-hub-${parLocation}'


module modVNet 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'deploy-${varVNetName}'
  params: {
    addressPrefixes: [
      parAddressRange
    ]
    name: varVNetName
    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'diagnostic'
        workspaceResourceId: parWorkspaceResourceId
      }
    ]
    location: parLocation
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        addressPrefixes: [cidrSubnet(parAddressRange, 26, 0)]
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefixes: [cidrSubnet(parAddressRange, 26, 1)]
      }
      {
        name: 'subnet-workload'
        addressPrefixes: [cidrSubnet(parAddressRange, 26, 2)] 
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefixes: [cidrSubnet(parAddressRange, 26, 3)] 
      }
    ]
    enableTelemetry: false
  }
}

module publicIP 'br/public:avm/res/network/public-ip-address:0.9.0' = {
  name: 'deploy-public-ip'
  params: {
    name: 'pip-bastion-${parLocation}'
    location: parLocation
    skuName: 'Standard'
    availabilityZones: []
  }
}

resource resBastion 'Microsoft.Network/bastionHosts@2024-07-01' = {
  name: 'bastion-${parLocation}'
  location: parLocation
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    enableIpConnect: false
    disableCopyPaste: false
    enableShareableLink: false
    enableKerberos: false
    enableSessionRecording: false
    ipConfigurations: [
      {
        name: 'IpConfAzureBastionSubnet'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.outputs.resourceId
          }
          subnet: {
            id: '${modVNet.outputs.resourceId}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

module modVirtualMachine 'br/public:avm/res/compute/virtual-machine:0.20.0' = {
  name: 'deploy-hub-vm-${parLocation}'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: 'vm-hub-${parLocation}'
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: modVNet.outputs.subnetResourceIds[2]
          }
        ]
        nicSuffix: '-nic-01'
        enableAcceleratedNetworking: false
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }    
    osType: 'Linux'
    vmSize: vmSize
    availabilityZone: -1
    location: parLocation
    enableTelemetry: false
  }
}

module firewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.1' = {
  name: 'firewallPolicyDeployment'
  params: {
    name: 'nfp-${parLocation}'
    tier: firewallSKU
    threatIntelMode: 'Off'
  }
}

resource firewallPolicies 'Microsoft.Network/firewallPolicies@2024-07-01' existing = {
  name: 'nfp-${parLocation}'
  dependsOn: [
    firewallPolicy
  ]
}

resource spokesRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicies
  name: 'SpokesFirewallRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'spokes-net-rc01'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
        {
            name: 'allow-client-to-server'
            ruleType: 'NetworkRule'
            description: 'Allow communication between client and server VNets'
            sourceAddresses: [
              '10.9.11.0/24'
              '10.9.12.0/24'
              '10.9.13.0/24'
              '10.9.14.0/24'
              '10.9.21.0/24'
              '10.9.22.0/24'
              '10.9.23.0/24'
              '10.9.24.0/24'
            ]
            ipProtocols: [
              'ICMP'
              'TCP'
            ]
            destinationPorts: [
              '5201'
              '443'
            ]
            destinationAddresses: [
              '10.9.11.0/24'
              '10.9.12.0/24'
              '10.9.13.0/24'
              '10.9.14.0/24'
              '10.9.21.0/24'
              '10.9.22.0/24'
              '10.9.23.0/24'
              '10.9.24.0/24'
            ]
          }          
        ]
      }                      
    ]
  }
}

resource spokesAppRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicies
  name: 'SpokesAppRuleCollectionGroup'
  dependsOn: [
    spokesRuleCollectionGroup
  ]
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'spokes-app-rc01'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
        {
            name: 'allow-to-internet'
            ruleType: 'ApplicationRule'
            description: 'Allow communication to Internet'
            sourceAddresses: [
              '10.9.11.0/24'
              '10.9.12.0/24'
              '10.9.13.0/24'
              '10.9.14.0/24'
              '10.9.21.0/24'
              '10.9.22.0/24'
              '10.9.23.0/24'
              '10.9.24.0/24'
            ]
            protocols: [
              {
                protocolType: 'Http'
                port: 80
              }
              {
                protocolType: 'Https'
                port: 443
              }
            ]            
            targetFqdns: [
              '*'
            ]            
          }          
        ]
      }                
    ]
  }
}


var nafName = 'naf-${parLocation}'
module azureFirewall 'br/public:avm/res/network/azure-firewall:0.8.0' = {
  name: 'deploy-azure-firewall'
  params: {
    name: nafName
    azureSkuTier: firewallSKU
    location: parLocation
    virtualNetworkResourceId: modVNet.outputs.resourceId
    firewallPolicyId: firewallPolicy.outputs.resourceId
    publicIPAddressObject: {
      name: 'pip-${nafName}'
      publicIPAllocationMethod: 'Static'
      skuName: 'Standard'
      skuTier: 'Regional'
    }    
    diagnosticSettings: [
      {
        name: 'diagnostics'
        workspaceResourceId: parWorkspaceResourceId
        logAnalyticsDestinationType: 'Dedicated'
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
            enabled: true
          }
        ]
      }
    ]
  }
}

output hubVnetId string = modVNet.outputs.resourceId
output firewallPrivateIP string = azureFirewall.outputs.privateIp
