# 🎹 VocalScript - Transcrição de Áudio para Texto

Uma aplicação web para transcrição de áudio para texto usando Azure Services.

## 📋 Pré-requisitos

- PHP 7.4 ou superior
- Composer
- XAMPP ou servidor web com PHP
- Conta Azure (para produção)

## 🚀 Instalação

1. **Instalar dependências:**
   ```bash
   composer install
   ```

2. **Configurar variáveis de ambiente:**
   Criar um arquivo `.env` ou configurar as seguintes variáveis:
   ```
   AZURE_STORAGE_CONNECTION_STRING=sua_connection_string_aqui
   AZURE_CONTAINER_NAME=audios
   COSMOS_DB_CONN_STRING=sua_cosmos_connection_string
   COSMOS_DB_NAME=VocalScriptDB
   COSMOS_DB_CONTAINER_NAME=transcriptions
   ```

## 📁 Arquivos

- `test.php` - Versão principal com integração Azure
- `test_simple.php` - Versão simplificada para demonstração
- `index.php` - Arquivo principal (se existir)

## 🔧 Uso

### Para testar sem Azure:
Acesse: `http://localhost/VocalScript/test_simple.php`

### Para usar com Azure:
1. Configure as variáveis de ambiente
2. Acesse: `http://localhost/VocalScript/test.php`

## 🌟 Funcionalidades

- ✅ Upload de arquivos de áudio (.mp3, .wav)
- ✅ Seleção de idioma para transcrição
- ✅ Interface moderna e responsiva
- ✅ Exportação de transcrições para CSV
- ✅ Download de traduções
- ⚠️ Integração com Azure Blob Storage (requer configuração)
- ⚠️ Integração com Azure Cosmos DB (requer configuração)

## 🛠️ Problemas Comuns

### "Nada aparece na página"
- Verifique se o PHP está funcionando
- Execute `composer install` para instalar dependências
- Verifique os logs de erro do servidor

### Erros de Azure
- Verifique as variáveis de ambiente
- Confirme que as credenciais Azure estão corretas
- Use a versão `test_simple.php` para testar sem Azure

## 📝 Notas

- A versão simplificada funciona sem dependências externas
- Para produção, configure adequadamente as APIs do Azure
- Certifique-se de que o servidor tem permissões de escrita para uploads

## 🐛 Debug

O arquivo principal agora mostra erros detalhados para facilitar o debug. Se ainda tiver problemas:

1. Verifique os logs do servidor web
2. Ative display_errors no PHP
3. Use a versão simplificada para testar
