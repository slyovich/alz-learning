#!/bin/bash
set -e

RG_NAME="rg-alz-learning-001"

WEBAPP_NAME=$(az webapp list --resource-group ${RG_NAME} --query "[0].name" --output tsv)

if [ -z "${WEBAPP_NAME}" ]; then
    echo "Web App not found"
    exit 1
fi

# Enable build during deployment
az webapp config appsettings set --name ${WEBAPP_NAME} --resource-group ${RG_NAME} --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true

# Set startup command
az webapp config set --name ${WEBAPP_NAME} --resource-group ${RG_NAME} --startup-file "pm2 start server.js --no-daemon"

# Sleep for 30 seconds to allow the app to start
sleep 30

# Deploy the app
az webapp up --name ${WEBAPP_NAME} --resource-group ${RG_NAME} --runtime "NODE:24-lts" --track-status false
