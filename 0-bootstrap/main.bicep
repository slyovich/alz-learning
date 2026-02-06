targetScope = 'managementGroup'

@description('The name of the management group.')
param managementGroupName string = 'alz-landingzones-corp'

@description('The ID of the existing subscription.')
param existingSubscriptionId string

@description('Specifies the location for resources.')
param location string = 'uksouth'

@description('Specifies the acronyme of the location')
param locationShortName string = 'uks'

module subscriptionVending 'modules/lz-vending.bicep' = {
  name: 'lz-vending-initialisation'
  params: {
    managementGroupName: managementGroupName
    existingSubscriptionId: existingSubscriptionId
    location: location
    locationShortName: locationShortName
  }
}

module dnsZones 'modules/dns-zones.bicep' = {
  name: 'lz-vending-dns-zones'
  scope: resourceGroup(existingSubscriptionId, 'rg-connectivity-${locationShortName}-001')
  params: {
    virtualNetworkResourceIds: [
      {
        virtualNetworkResourceId: '/subscriptions/${existingSubscriptionId}/resourceGroups/rg-connectivity-${locationShortName}-001/providers/Microsoft.Network/virtualNetworks/vnet-connectivity-${locationShortName}-001'
      }
      {
        virtualNetworkResourceId: '/subscriptions/${existingSubscriptionId}/resourceGroups/rg-connectivity-${locationShortName}-001/providers/Microsoft.Network/virtualNetworks/vnet-connectivity-${locationShortName}-002'
      }
    ]
  }
  dependsOn: [
    subscriptionVending
  ]
}

module resourceGroups 'modules/resourcegroups.bicep' = {
  name: 'lz-vending-resource-groups'
  scope: subscription(existingSubscriptionId)
  params: {
    location: location
    locationShortName: locationShortName
  }
  dependsOn: [
    dnsZones
  ]
}

module storage 'modules/storage.bicep' = {
  name: 'lz-vending-storage'
  scope: resourceGroup(existingSubscriptionId, 'rg-devops-${locationShortName}-001')
  params: {
    storageAccountName: 'asalzstate${locationShortName}001'
    subnetId: '/subscriptions/${existingSubscriptionId}/resourceGroups/rg-connectivity-${locationShortName}-001/providers/Microsoft.Network/virtualNetworks/vnet-connectivity-${locationShortName}-002/subnets/snet-bootstrap-privateendpoints'
    privateLinkPrivateDnsZoneId: '/subscriptions/${existingSubscriptionId}/resourceGroups/rg-connectivity-${locationShortName}-001/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
  }
  dependsOn: [
    resourceGroups
  ]
}

module vpngateway 'modules/vpngateway.bicep' = {
  name: 'lz-vending-vpngateway'
  scope: resourceGroup(existingSubscriptionId, 'rg-connectivity-${locationShortName}-001')
  params: {
    vnetName: 'vnet-connectivity-${locationShortName}-002'
    gwPublicIpName: 'pip-connectivity-${locationShortName}-001'
    vnetGatewayName: 'vng-connectivity-${locationShortName}-001'
  }
  dependsOn: [
    resourceGroups
  ]
}
