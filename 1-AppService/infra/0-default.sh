#!/bin/bash
set -e

# ==============================================================================
# Variables
# ==============================================================================
# Generate random suffix for unique names
RANDOM_SUFFIX=$(openssl rand -hex 3)
RG_NAME="rg-alz-learning-001"
LOCATION="switzerlandnorth"
LOCATION_SHORT="chn"
PLAN_NAME="asp-alz-learning-${LOCATION_SHORT}-${RANDOM_SUFFIX}"
WEBAPP_NAME="app-alz-learning-${LOCATION_SHORT}-${RANDOM_SUFFIX}"

echo "Starting Azure deployment..."
echo "Resource Group: $RG_NAME"
echo "Location: $LOCATION"
echo "App Service Plan: $PLAN_NAME"
echo "Web App: $WEBAPP_NAME"

# ==============================================================================
# 1. Create Resource Group
# ==============================================================================
echo "Creating Resource Group..."
az group create --name "$RG_NAME" --location "$LOCATION"

# ==============================================================================
# 2. Create App Service Plan (Linux, Basic B1)
# ==============================================================================
echo "Creating App Service Plan (B1, Linux)..."
az appservice plan create \
  --name "$PLAN_NAME" \
  --resource-group "$RG_NAME" \
  --sku B1 \
  --is-linux

# ==============================================================================
# 3. Create Web App (Node 20 LTS)
# ==============================================================================
echo "Creating Web App (Node 24 LTS)..."
az webapp create \
  --name "$WEBAPP_NAME" \
  --resource-group "$RG_NAME" \
  --plan "$PLAN_NAME" \
  --runtime "NODE:24-lts"

# ==============================================================================
# 4. Security Configuration
# ==============================================================================
echo "Configuring Security Settings..."

# Enable HTTPS Only, set Min TLS Version to 1.2 and set FTP state to FTPS Only
az webapp update \
  --name "$WEBAPP_NAME" \
  --resource-group "$RG_NAME" \
  --https-only true \
  --set siteConfig.minTlsVersion=1.2 \
  --set siteConfig.ftpsState=FTPSOnly \
  --set siteConfig.alwaysOn=true

# Assign System Assigned Identity
echo "Assigning System Identity..."
az webapp identity assign \
  --name "$WEBAPP_NAME" \
  --resource-group "$RG_NAME"

# ==============================================================================
# 5. Deploy app
# ==============================================================================
echo "Deploying app..."
cd ../api
./deploy.sh

# ==============================================================================
# 6. Final Output
# ==============================================================================
echo "Deployment Complete!"
echo "Web App URL: https://$WEBAPP_NAME.azurewebsites.net"
