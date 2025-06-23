#!/bin/bash

#-----------------------------------------------------
# Azure Deployment - App Service Only with GitHub Deployment
#-----------------------------------------------------

LOCATION="FranceCentral"
RESOURCE_GROUP="rg-vocalscript"

# az login  # Uncomment if needed

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Storage Account for files
az storage account create \
    --name "vocalstoragedb" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false

STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
    --name "vocalstoragedb" \
    --resource-group $RESOURCE_GROUP \
    --output tsv)

az storage container create \
    --name "audios" \
    --account-name "vocalstoragedb" \
    --auth-mode login \
    --public-access off

# Cosmos DB
az cosmosdb create \
    --name "vocal-cosmosdb" \
    --resource-group $RESOURCE_GROUP \
    --locations regionName=$LOCATION failoverPriority=0 isZoneRedundant=false \
    --kind GlobalDocumentDB \
    --default-consistency-level "Session" \
    --enable-free-tier false

az cosmosdb sql database create \
    --account-name "vocal-cosmosdb" \
    --name "TranscricoesDB" \
    --resource-group $RESOURCE_GROUP

az cosmosdb sql container create \
    --account-name "vocal-cosmosdb" \
    --database-name "TranscricoesDB" \
    --name "Transcricoes" \
    --resource-group $RESOURCE_GROUP \
    --partition-key-path "/id"

COSMOS_CONNECTION_STRING=$(az cosmosdb keys list \
    --name "vocal-cosmosdb" \
    --resource-group $RESOURCE_GROUP \
    --type connection-strings \
    --query "connectionStrings[0].connectionString" \
    --output tsv)

# App Service Plan
az appservice plan create \
    --name "asp-vocalscript" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --is-linux \
    --sku B1

# Web App (PHP)
az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan asp-vocalscript \
    --name vocalscript-app 

# Cognitive Services (Speech-to-Text)
az cognitiveservices account create \
    --name "vocal-speech-to-text" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --kind SpeechServices \
    --sku S0 \
    --yes

# Final output
echo "Deployment completed!"
echo "App URL: https://vocalscript-app.azurewebsites.net"
echo "Cosmos DB Connection: $COSMOS_CONNECTION_STRING"
echo "Storage Connection: $STORAGE_CONNECTION_STRING"