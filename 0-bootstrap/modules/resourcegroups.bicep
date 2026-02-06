targetScope = 'subscription'

@description('Specifies the location for resources.')
param location string = 'uksouth'

@description('Specifies the acronyme of the location')
param locationShortName string = 'uks'

// Create a resource group to hold the storage account
resource storageResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-devops-${locationShortName}-001'
  location: location
}
