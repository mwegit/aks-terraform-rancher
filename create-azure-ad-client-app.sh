#!/bin/bash
set -e

# load environment variables
export RBAC_AZURE_TENANT_ID="5c0cffdd-687c-4e49-96fe-fcae46ad7e89"
export RBAC_CLIENT_APP_NAME="AKSAADClient3"
export RBAC_CLIENT_APP_URL="http://aksaadclient3"

# export RBAC_SERVER_APP_ID="COMPLETE_AFTER_SERVER_APP_CREATION"
# export RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID="COMPLETE_AFTER_SERVER_APP_CREATION"
# export RBAC_SERVER_APP_SECRET="COMPLETE_AFTER_SERVER_APP_CREATION"

export RBAC_SERVER_APP_ID=d2aec4ce-6697-46d5-a056-13776ed6e372
export RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID=e72cdd89-077a-45a6-96d1-704ed3a56825
export RBAC_SERVER_APP_SECRET='N=v97Sh4G@93+_7(#3cutekH)JxdzOS('


# generate manifest for client application
cat > ./manifest-client.json << EOF
[
    {
      "resourceAppId": "${RBAC_SERVER_APP_ID}",
      "resourceAccess": [
        {
          "id": "${RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID}",
          "type": "Scope"
        }
      ]
    }
]
EOF

# create client application
az ad app create --display-name ${RBAC_CLIENT_APP_NAME} \
    --native-app \
    --reply-urls "${RBAC_CLIENT_APP_URL}" \
    --homepage "${RBAC_CLIENT_APP_URL}" \
    --required-resource-accesses @manifest-client.json

RBAC_CLIENT_APP_ID=$(az ad app list --display-name ${RBAC_CLIENT_APP_NAME} --query [].appId -o tsv)

# create service principal for the client application
az ad sp create --id ${RBAC_CLIENT_APP_ID}

# remove manifest-client.json
rm ./manifest-client.json

# grant permissions to server application
RBAC_CLIENT_APP_RESOURCES_API_IDS=$(az ad app permission list --id $RBAC_CLIENT_APP_ID --query [].resourceAppId --out tsv | xargs echo)
for RESOURCE_API_ID in $RBAC_CLIENT_APP_RESOURCES_API_IDS;
do
  az ad app permission grant --api $RESOURCE_API_ID --id $RBAC_CLIENT_APP_ID
done

# Output terraform variables
echo "
export TF_VAR_rbac_server_app_id="${RBAC_SERVER_APP_ID}"
export TF_VAR_rbac_server_app_secret="${RBAC_SERVER_APP_SECRET}"
export TF_VAR_rbac_client_app_id="${RBAC_CLIENT_APP_ID}"
export TF_VAR_tenant_id="${RBAC_AZURE_TENANT_ID}"
"

