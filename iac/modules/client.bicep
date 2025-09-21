targetScope = 'resourceGroup'

param parLocation string
param parIndex int
param parAddressRange string
param parWorkspaceResourceId string
param adminUsername string
@secure()
param adminPassword string
param hubVnetId string
param vmSize string

var varVNetName = 'vnet-client${parIndex}-${parLocation}'

module modVNet 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: 'deploy-${varVNetName}-${parIndex}'
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
        addressPrefixes: [parAddressRange]
        name: 'subnet-workload'
      }
    ]
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'hub-to-client${parIndex}'
        remoteVirtualNetworkResourceId: hubVnetId
        useRemoteGateways: false
      }
    ]    
    enableTelemetry: false
  }
}

module modVirtualMachine 'br/public:avm/res/compute/virtual-machine:0.20.0' = {
  name: 'deploy-client${parIndex}-vm-${parLocation}'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: 'vm-client${parIndex}-${parLocation}'
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: modVNet.outputs.subnetResourceIds[0]
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
        storageAccountType: 'Premium_LRS'
      }
    }
    extensionCustomScriptConfig: {
      name: 'install-iperf3'
      settings: {
        fileUris: [
          'https://raw.githubusercontent.com/evgenyb/azfw-perf/refs/heads/main/iac/scripts/init.sh'
        ]
        commandToExecute: 'sh client.sh'
      }
    }
    osType: 'Linux'
    vmSize: vmSize
    availabilityZone: -1
    location: parLocation
    enableTelemetry: false
  }
}

output clientVNetId string = modVNet.outputs.resourceId
