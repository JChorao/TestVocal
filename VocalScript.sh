#!/bin/bash

# Configurações
DOCKER_USERNAME="joaochorao"
NETWORK_NAME="vocalscript-net"
VOLUME_NAME="vocalscript-data"

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