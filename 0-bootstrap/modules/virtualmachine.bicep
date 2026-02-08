@description('The name of the virtual machine.')
param vmName string

@description('The name of the bastion host.')
param bastionName string

@description('The virtual network resource ID for the private endpoint.')
param virtualNetworkResourceId string

@description('Specifies the subnet resource ID for the private endpoint.')
param subnetId string

@description('Specifies the admin username for the virtual machine.')
param adminUsername string

@description('Specifies the admin public key for the virtual machine.')
param adminPublicKey string

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
  name: 'lz-vending-vm'
  params: {
    // Required parameters
    availabilityZone: -1
    name: vmName
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: subnetId
            privateIPAllocationMethod: 'Dynamic'
            pipConfiguration: {
              name: 'pip-${vmName}'
              publicIPAddressVersion: 'IPv4'
              publicIPAllocationMethod: 'Static'
              skuName: 'Standard'
              skuTier: 'Regional'
              availabilityZones: [1, 2, 3]
            }
          }
        ]
        nicSuffix: '-nic-01'
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
    vmSize: 'Standard_D2s_v3'
    // Non-required parameters
    adminUsername: adminUsername
    disablePasswordAuthentication: true
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    publicKeys: [
      {
        keyData: adminPublicKey
        path: '/home/${adminUsername}/.ssh/authorized_keys'
      }
    ]
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.8.2' = {
  name: 'lz-vending-bastion'
  params: {
    // Required parameters
    name: bastionName
    virtualNetworkResourceId: virtualNetworkResourceId
    // Non-required parameters
    location: resourceGroup().location
    skuName: 'Developer'
  }
}
