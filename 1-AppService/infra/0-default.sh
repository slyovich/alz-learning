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
APPINSIGHTS_NAME="appi-alz-learning-${LOCATION_SHORT}-${RANDOM_SUFFIX}"
LOG_ANALYTICS_WORKSPACE_NAME="log-alz-learning-${LOCATION_SHORT}-${RANDOM_SUFFIX}"

echo "Starting Azure deployment..."
echo "Resource Group: $RG_NAME"
echo "Location: $LOCATION"
echo "App Service Plan: $PLAN_NAME"
echo "Web App: $WEBAPP_NAME"
echo "Application Insights: $APPINSIGHTS_NAME"
echo "Log Analytics Workspace: $LOG_ANALYTICS_WORKSPACE_NAME"

# ==============================================================================
# 1. Create Resource Group
# ==============================================================================
echo "Creating Resource Group..."
az group create --name "$RG_NAME" --location "$LOCATION"

# ==============================================================================
# 2. Create Log Analytics Workspace
# ==============================================================================
echo "Creating Log Analytics Workspace..."
az monitor log-analytics workspace create \
  --resource-group "$RG_NAME" \
  --workspace-name "$LOG_ANALYTICS_WORKSPACE_NAME" \
  --location "$LOCATION"

# ==============================================================================
# 3. Create App Service Plan (Linux, Basic B1)
# ==============================================================================
echo "Creating App Service Plan (B1, Linux)..."
az appservice plan create \
  --name "$PLAN_NAME" \
  --resource-group "$RG_NAME" \
  --sku B1 \
  --is-linux

# ==============================================================================
# 4. Create Web App (Node 20 LTS)
# ==============================================================================
echo "Creating Web App (Node 24 LTS)..."
az webapp create \
  --name "$WEBAPP_NAME" \
  --resource-group "$RG_NAME" \
  --plan "$PLAN_NAME" \
  --runtime "NODE:24-lts"

# ==============================================================================
# 5. Security Configuration
# ==============================================================================
echo "Configuring Security Settings..."

# Enable HTTPS Only, set Min TLS Version to 1.2 and set FTP state to FTPS Only
az webapp update \
  --name "$WEBAPP_NAME" \
  --resource-group "$RG_NAME" \
  --https-only true \
  --set siteConfig.minTlsVersion=1.2 \
  --set siteConfig.ftpsState=FTPSOnly

# Assign System Assigned Identity
echo "Assigning System Identity..."
az webapp identity assign \
  --name "$WEBAPP_NAME" \
  --resource-group "$RG_NAME"

# ==============================================================================
# 6. Monitoring (Application Insights)
# ==============================================================================
echo "Creating Application Insights..."
az monitor app-insights component create \
  --app "$APPINSIGHTS_NAME" \
  --location "$LOCATION" \
  --resource-group "$RG_NAME" \
  --kind web \
  --application-type web \
  --workspace "$LOG_ANALYTICS_WORKSPACE_NAME"

# Retrieve Instrumentation Key and Connection String
INSTRUMENTATION_KEY=$(az monitor app-insights component show --app "$APPINSIGHTS_NAME" --resource-group "$RG_NAME" --query instrumentationKey --output tsv)
CONNECTION_STRING=$(az monitor app-insights component show --app "$APPINSIGHTS_NAME" --resource-group "$RG_NAME" --query connectionString --output tsv)

echo "Configuring Application Insights for Web App..."
az webapp config appsettings set \
  --name "$WEBAPP_NAME" \
  --resource-group "$RG_NAME" \
  --settings \
    APPINSIGHTS_INSTRUMENTATIONKEY="$INSTRUMENTATION_KEY" \
    APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
    ApplicationInsightsAgent_EXTENSION_VERSION="~3" \
    XDT_MicrosoftApplicationInsights_Mode="recommended"

# ==============================================================================
# 6. Final Output
# ==============================================================================
echo "Deployment Complete!"
echo "Web App URL: https://$WEBAPP_NAME.azurewebsites.net"
