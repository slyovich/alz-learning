#!/bin/bash
set -e

RG_NAME="rg-alz-learning-001"

WEBAPP_NAME=$(az webapp list --resource-group ${RG_NAME} --query "[0].name" --output tsv)

TENANT_ID=$(az account show --query tenantId --output tsv)

echo "Creating App Registration for Microsoft provider authentication..."
az ad app create \
  --display-name $WEBAPP_NAME \
  --enable-id-token-issuance true \
  --web-redirect-uris https://$WEBAPP_NAME.azurewebsites.net/.auth/login/aad/callback \
  --requested-access-token-version 2 \
  --identifier-uris "api://$WEBAPP_NAME" \
  --required-resource-accesses @4-manifest.json

APPREG_CLIENTID=$(az ad app list --display-name $WEBAPP_NAME --query "[0].appId" --output tsv)
APPREG_SECRET=$(az ad app credential reset --id $APPREG_CLIENTID --query "password" --output tsv)

echo "Update Web App appsettings..."
az webapp config appsettings set \
  --resource-group $RG_NAME \
  --name $WEBAPP_NAME \
  --settings "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET=$APPREG_SECRET" WEBSITE_AUTH_AAD_ALLOWED_TENANTS="$TENANT_ID"

echo "Enabling EasyAuth for the web app..."
az webapp auth update \
  --resource-group $RG_NAME \
  --name $WEBAPP_NAME \
  --enabled true \
  --unauthenticated-client-action Return401 \
  --enable-token-store true

az webapp auth microsoft update \
  --resource-group $RG_NAME \
  --name $WEBAPP_NAME \
  --allowed-audiences "api://$WEBAPP_NAME" \
  --client-id "$APPREG_CLIENTID" \
  --client-secret-setting-name "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET" \
  --issuer "https://sts.windows.net/$TENANT_ID/v2.0" \
  --yes
