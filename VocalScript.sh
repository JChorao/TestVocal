#!/bin/bash

# Configurações
DOCKER_USERNAME="joaochorao"
NETWORK_NAME="vocalscript-net"
VOLUME_NAME="vocalscript-data"

LOCATION="FranceCentral"
RESOURCE_GROUP="rg-vocalscript"

# Login no Docker Hub
echo "Logging in to Docker Hub..."
docker login --username $DOCKER_USERNAME

# Criar rede e volume
docker network inspect $NETWORK_NAME >/dev/null 2>&1 || docker network create $NETWORK_NAME
docker volume inspect $VOLUME_NAME >/dev/null 2>&1 || docker volume create $VOLUME_NAME

# Construir imagens
# Construir imagens
echo "🏗 Building application image..."
docker build -t $DOCKER_USERNAME/vocalscript-app:latest -f Dockerfile .

echo "🏗 Building function image..."
docker build -t $DOCKER_USERNAME/vocalscript-function:latest \
  -f "function/BloblTriggerFunction/Dockerfile" \
  "function/BloblTriggerFunction"
  
# Baixar imagens base
echo "Pulling base images..."
docker pull mongo:latest
docker pull minio/minio

# Criar containers
echo "Creating containers..."

# MongoDB (CosmosDB emulator)
docker run -d \
  --name cosmosdb-emulator \
  --network $NETWORK_NAME \
  -p 27017:27017 \
  mongo:latest

# MinIO (Azure Storage emulator)
docker run -d \
  --name minio-storage \
  --network $NETWORK_NAME \
  -p 9000:9000 \
  -e "MINIO_ROOT_USER=azureuser" \
  -e "MINIO_ROOT_PASSWORD=AzureStoragePassword123" \
  minio/minio server /data

# Aplicação principal
docker run -d \
  --name vocalscript-app \
  --network $NETWORK_NAME \
  -p 5001:80 \
  -e COSMOS_DB_CONNECTION_STRING="mongodb://cosmosdb-emulator:27017" \
  -e AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=http;AccountName=azureuser;AccountKey=AzureStoragePassword123;BlobEndpoint=http://minio-storage:9000;EndpointSuffix=local" \
  -e APACHE_SERVER_NAME=vocalscript-app \
  $DOCKER_USERNAME/vocalscript-app:latest

echo "Containers criados com sucesso!"
echo "Acesse a aplicação em: http://localhost:5001"


# Variables


# Login to Azure (uncomment if needed)
az login

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
  --name "vocaltranslator" \
  --resource-group rg-vocalscript \
  --location francecentral \
  --kind SpeechServices \
  --sku S0 \
  --yes \
  --restore true


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

# Create App Service Plan
az appservice plan create \
    --name "asp-vocalscript" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --is-linux \
    --sku B1

# Create Function App
az functionapp create \
    --name "vocalscript-function" \
    --resource-group $RESOURCE_GROUP \
    --storage-account "functionstoragebd" \
    --plan "asp-vocalscript" \
    --functions-version 4 \
    --os-type Linux \
    --deployment-container-image-name "joaochorao/vocalscript-function:latest"

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

git add .env
git commit -m "Add .env file with Azure configuration"
git push origin main