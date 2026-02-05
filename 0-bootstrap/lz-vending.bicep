targetScope = 'managementGroup'

@description('The name of the management group.')
param managementGroupName string = 'alz-landingzones-corp'

@description('The ID of the existing subscription.')
param existingSubscriptionId string

@description('Specifies the location for resources.')
param location string = 'uksouth'

@description('Specifies the acronyme of the location')
param locationShortName string = 'uks'

module subscriptionVending 'br/public:avm/ptn/lz/sub-vending:0.5.3' = {
  name: 'lz-vending-initialisation'
  params: {
    subscriptionAliasEnabled: false
    existingSubscriptionId: existingSubscriptionId
    subscriptionTags: {
      test: 'true'
    }
    subscriptionWorkload: 'Production'
    subscriptionManagementGroupAssociationEnabled: true
    subscriptionManagementGroupId: managementGroupName
    virtualNetworkEnabled: true
    virtualNetworkLocation: location
    virtualNetworkResourceGroupName: 'rg-connectivity-${locationShortName}-001'
    virtualNetworkName: 'vnet-connectivity-${locationShortName}-001'
    virtualNetworkAddressSpace: [
      '10.0.0.0/24'
    ]
    virtualNetworkResourceGroupLockEnabled: false
    virtualNetworkPeeringEnabled: false
    additionalVirtualNetworks: [
      {
        name: 'vnet-connectivity-${locationShortName}-002'
        addressPrefixes: ['10.0.1.0/24']
        location: location
        resourceGroupName: 'rg-connectivity-${locationShortName}-001'
        resourceGroupLockEnabled: false
        subnets: [
          {
            name: 'snet-bootstrap-privateendpoints'
            addressPrefix: '10.0.1.0/28'
            networkSecurityGroup: {
              name: 'nsg-bootstrap-privateendpoints'
              location: location
            }
            privateEndpointNetworkPolicies: 'Enabled'
            privateLinkServiceNetworkPolicies: 'Enabled'
            defaultOutboundAccess: false
          }
        ]
      }
    ]
    peerAllVirtualNetworks: true
    roleAssignmentEnabled: true
    userAssignedIdentityResourceGroupName: 'rg-identities-${locationShortName}-001'
    userAssignedIdentitiesResourceGroupLockEnabled: false
    userAssignedManagedIdentities: [
      {
        name: 'id-bootstrap-${locationShortName}-ops'
        location: location
        roleAssignments: [
          {
            definition: '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
            description: 'Owner role assignment for the bootstrap identity.'
            relativeScope: ''
          }
        ]
      }
    ]
    resourceProviders: {}
  }
}

module dnsZones 'dns-zones.bicep' = {
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

module resourceGroups 'resourcegroups.bicep' = {
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

module storage 'storage.bicep' = {
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
