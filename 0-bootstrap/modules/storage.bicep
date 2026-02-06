targetScope = 'resourceGroup'

@description('Specifies the name of the storage account to create.')
param storageAccountName string = 'asalzstateuks001'

@description('Specifies the subnet resource ID for the private endpoint.')
param subnetId string

@description('Specifies the ID of the existing private DNS zone for private link.')
param privateLinkPrivateDnsZoneId string

// Create an Azure Storage Account to store the state of the landing zone deployment
module storageAccount 'br/public:avm/res/storage/storage-account:0.31.0' = {
  name: 'lz-vending-storage-account'
  params: {
    name: storageAccountName
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    defaultToOAuthAuthentication: true
    allowSharedKeyAccess: false
    privateEndpoints: [
      {
        name: 'pe-${storageAccountName}-blob'
        location: resourceGroup().location
        privateLinkServiceConnectionName: 'plsc-${storageAccountName}-blob'
        customNetworkInterfaceName: 'nic-${storageAccountName}-blob'
        service: 'blob'
        subnetResourceId: subnetId
        resourceGroupResourceId: resourceGroup().id
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateLinkPrivateDnsZoneId
            }
          ]
        }
      }
    ]
    enableHierarchicalNamespace: false
    allowedCopyScope: 'AAD'
    publicNetworkAccess: 'Disabled'
    roleAssignments: [
      {
        principalId: deployer().objectId
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
      }
    ]
  }
}
