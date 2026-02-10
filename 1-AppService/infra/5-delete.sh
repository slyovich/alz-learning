#!/bin/bash
set -e

RG_NAME="rg-alz-learning-001"
PE_NSG_NAME="nsg-privateendpoint"
INT_NSG_NAME="nsg-vnetintegration"

WEBAPP_NAME=$(az webapp list --resource-group ${RG_NAME} --query "[0].name" --output tsv)
APPREG_CLIENTID=$(az ad app list --display-name $WEBAPP_NAME --query "[0].appId" --output tsv)

echo "Deleting NSG assignments..."
PE_SNET_ID=$(az network nsg show --resource-group ${RG_NAME} --name $PE_NSG_NAME --query 'subnets[].id' -o tsv)
INT_SNET_ID=$(az network nsg show --resource-group ${RG_NAME} --name $INT_NSG_NAME --query 'subnets[].id' -o tsv)
az network vnet subnet update --ids $PE_SNET_ID --remove networkSecurityGroup
az network vnet subnet update --ids $INT_SNET_ID --remove networkSecurityGroup

echo "Deleting resource group ${RG_NAME}..."
az group delete --name ${RG_NAME} --yes

echo "Deleting subnets..."
az network vnet subnet delete --ids $PE_SNET_ID $INT_SNET_ID

echo "Deleting app registration ${WEBAPP_NAME}..."
az ad app delete --id $APPREG_CLIENTID
