#!/bin/bash
set -e

# Ask for user public IP
read -p "Enter your public IP address: " USER_IP

RG_NAME="rg-alz-learning-001"

WEBAPP_NAME=$(az webapp list --resource-group ${RG_NAME} --query "[0].name" --output tsv)

if [ -z "${WEBAPP_NAME}" ]; then
    echo "Web App not found"
    exit 1
fi

az webapp config access-restriction add \
  --resource-group ${RG_NAME} \
  --name ${WEBAPP_NAME} \
  --priority 100 \
  --rule-name "Allow-My-IP" \
  --action Allow \
  --description "Allow my IP address" \
  --ip-address "${USER_IP}/32"
