#!/bin/bash
set -e

RG_NAME="rg-alz-learning-001"
NSG_NAME="nsg-vnetintegration"
VNET_RG_NAME="rg-connectivity-chn-001"
VNET_NAME="vnet-connectivity-chn-001"
SNET_NAME="snet-vnetintegration"
SNET_PREFIX="10.0.0.16/28"

LOCATION=$(az group show --name $RG_NAME --query location --output tsv)
WEBAPP_NAME=$(az webapp list --resource-group ${RG_NAME} --query "[0].name" --output tsv)
WEBAPP_ID=$(az webapp show --resource-group ${RG_NAME} --name ${WEBAPP_NAME} --query id --output tsv)
VNET_ID=$(az network vnet show --resource-group $VNET_RG_NAME --name $VNET_NAME --query id --output tsv)

# Add subnet + nsg for vnet integration
echo "Creating NSG for vnet integration..."
az network nsg create \
  --resource-group $RG_NAME \
  --name $NSG_NAME \
  --location $LOCATION

NSG_ID=$(az network nsg show --resource-group $RG_NAME --name $NSG_NAME --query id --output tsv)

echo "Creating subnet for vnet integration..."
az network vnet subnet create \
  --resource-group $VNET_RG_NAME \
  --vnet-name $VNET_NAME \
  --name $SNET_NAME \
  --address-prefixes $SNET_PREFIX \
  --network-security-group $NSG_ID \
  --private-endpoint-network-policies Enabled \
  --private-link-service-network-policies Enabled \
  --default-outbound-access false \
  --delegation "Microsoft.Web/serverfarms"

SNET_ID=$(az network vnet subnet show --resource-group $VNET_RG_NAME --vnet-name $VNET_NAME --name $SNET_NAME --query id --output tsv)

# Add the default NSG rules to block all outbound traffic simulating a default FW rule
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

az network nsg rule create  \
  --nsg-name $NSG_NAME \
  --resource-group $RG_NAME \
  --name "DenyAllOutbound" \
  --priority 999 \
  --access Deny \
  --direction Outbound \
  --protocol "*" \
  --source-address-prefixes "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*"

# Add the vnet integration to the webapp
echo "Adding vnet integration to the webapp..."
az webapp vnet-integration add \
  --name $WEBAPP_NAME \
  --resource-group $RG_NAME \
  --subnet $SNET_ID \
  --vnet $VNET_ID

echo "Enabling outbound vnet routing..."
az resource update \
  --resource-group $RG_NAME \
  --name $WEBAPP_NAME \
  --resource-type "Microsoft.Web/sites" \
  --set properties.outboundVnetRouting.allTraffic=true
