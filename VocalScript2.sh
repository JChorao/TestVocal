
# Variables
LOCATION="FranceCentral"  # Change to your desired location
RESOURCE_GROUP="rg-vocalscript"

# Login to Azure (uncomment if needed)
# az login

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Storage Account for audio
az storage account create \
    --name "vocalstoragedb" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false

# Get storage connection string
STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
    --name "vocalstoragedb" \
    --resource-group $RESOURCE_GROUP \
    --output tsv)

# Create audio container
az storage container create \
    --name "audios" \
    --account-name "vocalstoragedb" \
    --auth-mode login \
    --public-access off

# Create Container Registry
az acr create \
    --name "vocalscriptacr" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Basic \
    --admin-enabled true

# Create Cosmos DB Account
az cosmosdb create \
    --name "vocal-cosmosdb" \
    --resource-group $RESOURCE_GROUP \
    --locations regionName=$LOCATION failoverPriority=0 isZoneRedundant=false \
    --kind GlobalDocumentDB \
    --default-consistency-level "Session" \
    --enable-free-tier false

# Create Cosmos DB Database
az cosmosdb sql database create \
    --account-name "vocal-cosmosdb" \
    --name "TranscricoesDB" \
    --resource-group $RESOURCE_GROUP

# Create Cosmos DB Container
az cosmosdb sql container create \
    --account-name "vocal-cosmosdb" \
    --database-name "TranscricoesDB" \
    --name "Transcricoes" \
    --resource-group $RESOURCE_GROUP \
    --partition-key-path "/id"

# Get Cosmos DB connection string
COSMOS_CONNECTION_STRING=$(az cosmosdb keys list \
    --name "vocal-cosmosdb" \
    --resource-group $RESOURCE_GROUP \
    --type connection-strings \
    --query "connectionStrings[0].connectionString" \
    --output tsv)

# Create Translator Service
az cognitiveservices account create \
    --name "vocaltranslator$RAND_SUFFIX" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --kind TextTranslation \
    --sku S1 \
    --yes

# Create Storage Account for functions
az storage account create \
    --name "functionstoragebd" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS

# Create Application Insights
az monitor app-insights component create \
    --app "vocalscript-func-ai" \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP \
    --application-type web

# Get App Insights connection string
AI_CONNECTION_STRING=$(az monitor app-insights component show \
    --app "vocalscript-func-ai" \
    --resource-group $RESOURCE_GROUP \
    --query "connectionString" \
    --output tsv)

# Create Function App
az functionapp create \
    --name "vocalscript-function" \
    --resource-group $RESOURCE_GROUP \
    --storage-account "functionstoragebd" \
    --plan "asp-vocalscript" \
    --runtime "node" \
    --functions-version 4 \
    --os-type Linux \
    --runtime-version 18 \
    --docker-custom-image-name "joaochorao/vocalscript-function:latest"

# Configure Function App settings
az functionapp config appsettings set \
    --name "vocalscript-function" \
    --resource-group $RESOURCE_GROUP \
    --settings \
        "FUNCTIONS_WORKER_RUNTIME=node" \
        "AzureWebJobsStorage=$STORAGE_CONNECTION_STRING" \
        "APPLICATIONINSIGHTS_CONNECTION_STRING=$AI_CONNECTION_STRING"

# Assign identity to function app
az functionapp identity assign \
    --name "vocalscript-function" \
    --resource-group $RESOURCE_GROUP

# Output important information
echo "Deployment completed!"
echo "Cosmos DB Connection String: $COSMOS_CONNECTION_STRING;DatabaseName=TranscricoesDB;"
echo "Storage Connection String: $STORAGE_CONNECTION_STRING"
echo "Frontend URL: https://vocalscript-frontend.azurewebsites.net"

cat <<EOF > ".env"
AZURE_FUNCTION_URL=https://vocalscript-function.azurewebsites.net/api/transcribe
AZURE_STORAGE_ACCOUNT=vocalstoragedb
AZURE_STORAGE_KEY=$STORAGE_CONNECTION_STRING
AZURE_STORAGE_CONTAINER=audios
AZURE_REGION=$LOCATION
EOF
