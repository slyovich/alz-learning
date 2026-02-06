@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the existing virtual network')
param vnetName string

@description('Name of the GatewaySubnet in the VNet')
param gatewaySubnetName string = 'GatewaySubnet'

@description('Name of the VPN gateway public IP')
param gwPublicIpName string

@description('Name of the VPN gateway')
param vnetGatewayName string

@description('RouteBased or PolicyBased')
@allowed([
  'RouteBased'
  'PolicyBased'
])
param vpnType string = 'RouteBased'

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: vnet
  name: gatewaySubnetName
}

resource gwPublicIp 'Microsoft.Network/publicIPAddresses@2025-05-01' = {
  name: gwPublicIpName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = {
  name: vnetGatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          publicIPAddress: {
            id: gwPublicIp.id
          }
          subnet: {
            id: gatewaySubnet.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: vpnType
    enableBgp: false
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
  }
}
