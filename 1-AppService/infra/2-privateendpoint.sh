#!/bin/bash
set -e

RG_NAME="rg-alz-learning-001"
NSG_NAME="nsg-privateendpoint"
VNET_RG_NAME="rg-connectivity-chn-001"
VNET_NAME="vnet-connectivity-chn-001"
SNET_NAME="snet-privateendpoint"
SNET_PREFIX="10.0.0.0/28"
SNET_BOOTSTRAP_PREFIX="10.0.1.32/28"

LOCATION=$(az group show --name $RG_NAME --query location --output tsv)
WEBAPP_NAME=$(az webapp list --resource-group ${RG_NAME} --query "[0].name" --output tsv)
WEBAPP_ID=$(az webapp show --resource-group ${RG_NAME} --name ${WEBAPP_NAME} --query id --output tsv)

DNS_ZONE="privatelink.azurewebsites.net"
DNS_ZONE_ID=$(az network private-dns zone show --resource-group $VNET_RG_NAME --name $DNS_ZONE --query id --output tsv)

# Add subnet + nsg for private endpoint in vnet connectivity 001
echo "Creating NSG for private endpoint..."
az network nsg create \
  --resource-group $RG_NAME \
  --name $NSG_NAME \
  --location $LOCATION

NSG_ID=$(az network nsg show --resource-group $RG_NAME --name $NSG_NAME --query id --output tsv)

echo "Creating subnet for private endpoint..."
az network vnet subnet create \
  --resource-group $VNET_RG_NAME \
  --vnet-name $VNET_NAME \
  --name $SNET_NAME \
  --address-prefixes $SNET_PREFIX \
  --network-security-group $NSG_ID \
  --private-endpoint-network-policies Enabled \
  --private-link-service-network-policies Enabled \
  --default-outbound-access false

SNET_ID=$(az network vnet subnet show --resource-group $VNET_RG_NAME --vnet-name $VNET_NAME --name $SNET_NAME --query id --output tsv)

# Add the default NSG rules to block all inbound traffic
echo "Adding NSG rule to deny all inbound traffic..."
az network nsg rule create  \
  --nsg-name $NSG_NAME \
  --resource-group $RG_NAME \
  --name "DenyAllInbound" \
  --priority 999 \
  --access Deny \
  --direction Inbound \
  --protocol "*" \
  --source-address-prefixes "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*"

# Add NSG rule to allow inbound traffic from the VM boostrap subnet
echo "Adding NSG rule to allow inbound traffic from the VM boostrap subnet..."
az network nsg rule create  \
  --nsg-name $NSG_NAME \
  --resource-group $RG_NAME \
  --name "AllowBootstrapVM" \
  --priority 100 \
  --access Allow \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefixes $SNET_BOOTSTRAP_PREFIX \
  --destination-address-prefixes VirtualNetwork \
  --destination-port-ranges "443"

# Add private endpoint
echo "Creating private endpoint..."
az network private-endpoint create \
  --resource-group $RG_NAME \
  --connection-name "psc${WEBAPP_NAME}" \
  --name "pe-${WEBAPP_NAME}" \
  --private-connection-resource-id $WEBAPP_ID \
  --subnet $SNET_ID \
  --group-id "sites" \
  --manual-request false \
  --nic-name "nic-${WEBAPP_NAME}"

az network private-endpoint dns-zone-group create \
  --resource-group $RG_NAME \
  --endpoint-name "pe-${WEBAPP_NAME}" \
  --name "zone-group" \
  --private-dns-zone $DNS_ZONE_ID \
  --zone-name $DNS_ZONE

# Disable public network access
echo "Disabling public network access..."
az webapp update \
  --resource-group $RG_NAME \
  --name $WEBAPP_NAME \
  --set "publicNetworkAccess=Disabled"
