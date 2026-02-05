@description('The resource ID of the virtual network to link the private DNS zones to.')
param virtualNetworkResourceIds array

module privateLinkPrivateDnsZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.7.2' = {
  params: {
    virtualNetworkLinks: virtualNetworkResourceIds
  }
}

output combinedPrivateLinkPrivateDnsZonesReplacedWithVnetsToLink array = privateLinkPrivateDnsZones.outputs.combinedPrivateLinkPrivateDnsZonesReplacedWithVnetsToLink
