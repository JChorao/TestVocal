# Usa imagem oficial para Azure Functions com Python 3.10
FROM mcr.microsoft.com/azure-functions/python:4-python3.10-appservice

# Define variáveis de ambiente obrigatórias
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

# Define diretório de trabalho
WORKDIR /home/site/wwwroot

# Copia todos os ficheiros da função para dentro da imagem
COPY . .

# Instala dependências
RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt
