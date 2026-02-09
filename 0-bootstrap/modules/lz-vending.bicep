targetScope = 'managementGroup'

@description('The name of the management group.')
param managementGroupName string

@description('The ID of the existing subscription.')
param existingSubscriptionId string

@description('Specifies the location for resources.')
param location string

@description('Specifies the acronyme of the location')
param locationShortName string

module subscriptionVending 'br/public:avm/ptn/lz/sub-vending:0.5.3' = {
  name: 'lz-vending'
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
            name: 'GatewaySubnet'
            addressPrefix: '10.0.1.0/27'
            privateEndpointNetworkPolicies: 'Enabled'
            privateLinkServiceNetworkPolicies: 'Enabled'
            defaultOutboundAccess: false
          }
          {
            name: 'snet-bootstrap-privateendpoints'
            addressPrefix: '10.0.1.32/28'
            networkSecurityGroup: {
              name: 'nsg-bootstrap-privateendpoints'
              location: location
              securityRules: [
                {
                  name: 'AllowInternalHTTPSCommunication'
                  properties: {
                    access: 'Allow'
                    description: 'Allow internal HTTPS communication'
                    destinationAddressPrefix: 'VirtualNetwork'
                    destinationPortRange: '443'
                    direction: 'Inbound'
                    priority: 200
                    protocol: 'Tcp'
                    sourceAddressPrefixes: ['10.0.1.32/28']
                    sourcePortRange: '*'
                  }
                }
                {
                  name: 'DenyAllInbound'
                  properties: {
                    access: 'Deny'
                    description: 'Deny all inbound traffic'
                    destinationAddressPrefix: '*'
                    destinationPortRange: '*'
                    direction: 'Inbound'
                    priority: 999
                    protocol: '*'
                    sourceAddressPrefixes: ['*']
                    sourcePortRange: '*'
                  }
                }
              ]
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
