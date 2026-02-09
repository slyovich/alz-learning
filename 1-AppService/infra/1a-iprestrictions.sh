#!/bin/bash
set -e

RG_NAME="rg-alz-learning-001"

WEBAPP_NAME=$(az webapp list --resource-group ${RG_NAME} --query "[0].name" --output tsv)

if [ -z "${WEBAPP_NAME}" ]; then
    echo "Web App not found"
    exit 1
fi

az webapp config access-restriction set \
  --resource-group ${RG_NAME} \
  --name ${WEBAPP_NAME} \
  --default-action Deny \
  --scm-default-action Deny \
  --use-same-restrictions-for-scm-site true
