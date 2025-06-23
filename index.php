<?php
        
        // Versão simplificada sem dependências Azure para teste
        error_reporting(E_ALL);
        ini_set('display_errors', 1);

        $idioma_map = [
            "🇵🇹 Português (PT)" => "pt-PT",
            "🇧🇷 Português (BR)" => "pt-BR",
            "🇺🇸 English (US)" => "en-US",
            "🇪🇸 Español (ES)" => "es-ES",
            "🇫🇷 Français (FR)" => "fr-FR"
        ];

        function get_transcricoes() {
            // Simulação de dados
            $response = file_get_contents('https://vocalscript-function.azurewebsites.net/api/transcribe?url=LINK_DO_AUDIO');
            return json_decode($response, true);
        }

        function upload_para_blob($containerName, $blobName, $filePath) {
            // Simulação de upload
            echo "<div class='info'>🔄 Simulação: Upload de '$blobName' para container '$containerName'</div>";
            return true;
        }
    ?>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎹 VocalScript - Transcrição de Áudio para Texto</title>
    <style>
        body {
            background-color:rgb(39, 40, 40);
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .error {
            color: #d32f2f;
            background-color: #ffebee;
            padding: 15px;
            margin: 15px 0;
            border: 1px solid #f44336;
            border-radius: 8px;
            border-left: 5px solid #d32f2f;
        }
        .success {
            color: #2e7d32;
            background-color: #e8f5e8;
            padding: 15px;
            margin: 15px 0;
            border: 1px solid #4caf50;
            border-radius: 8px;
            border-left: 5px solid #2e7d32;
        }
        .info {
            color: #1976d2;
            background-color: #e3f2fd;
            padding: 15px;
            margin: 15px 0;
            border: 1px solid #2196f3;
            border-radius: 8px;
            border-left: 5px solid #1976d2;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            font-weight: bold;
            color: #333;
        }
        select, input[type="file"] {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 8px;
            font-size: 16px;
            transition: border-color 0.3s;
        }
        select:focus, input[type="file"]:focus {
            outline: none;
            border-color: #4CAF50;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background-color: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        th, td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #4CAF50;
            color: white;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .button {
            background: linear-gradient(45deg, #4CAF50, #45a049);
            border: none;
            color: white;
            padding: 15px 25px;
            text-align: center;
            text-decoration: none;
            display: inline-block;
            font-size: 16px;
            margin: 10px 5px;
            cursor: pointer;
            border-radius: 8px;
            transition: all 0.3s;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }
        .button:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.3);
        }
        h1 {
            color: #2c3e50;
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
        }
        h2 {
            color: #34495e;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
            margin-top: 40px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎹 VocalScript - Transcrição de Áudio para Texto</h1>

        <form method="post" enctype="multipart/form-data">
            <div class="form-group">
                <label for="idioma">🌐 Seleciona o idioma do áudio:</label>
                <select name="idioma" id="idioma">
                    <?php foreach ($idioma_map as $label => $code): ?>
                        <option value="<?= htmlspecialchars($code) ?>"><?= htmlspecialchars($label) ?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            
            <div class="form-group">
                <label for="audio_file">📤 Faz upload de um ficheiro .mp3 ou .wav:</label>
                <input type="file" name="audio_file" id="audio_file" accept=".mp3,.wav">
            </div>
            
            <input type="submit" name="submit" value="🚀 Enviar" class="button">
        </form>

        <?php
        if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['audio_file'])) {
            $idioma_code = $_POST['idioma'];
            $file = $_FILES['audio_file'];
            
            echo "<div class='info'>📝 Idioma selecionado: " . htmlspecialchars($idioma_code) . "</div>";
            
            if ($file['error'] === UPLOAD_ERR_OK) {
                $tmp_name = $file['tmp_name'];
                $original_name = $file['name'];
                $extension = pathinfo($original_name, PATHINFO_EXTENSION);
                
                echo "<div class='info'>📁 Ficheiro recebido: " . htmlspecialchars($original_name) . " (" . round($file['size']/1024, 2) . " KB)</div>";
                
                // For MP3 files, we would need to convert to WAV
                if (strtolower($extension) === 'mp3') {
                    echo "<div class='info'>🔄 Ficheiro .mp3 detectado - conversão para WAV seria necessária</div>";
                }
                
                $blob_name = $idioma_code . '__' . uniqid() . '.' . $extension;
                
                if (upload_para_blob("audios", $blob_name, $tmp_name)) {
                    echo "<div class='success'>✅ Ficheiro '$blob_name' processado com sucesso!</div>";
                } else {
                    echo "<div class='error'>❌ Erro ao processar o ficheiro</div>";
                }
            } else {
                $error_messages = [
                    UPLOAD_ERR_INI_SIZE => 'Ficheiro demasiado grande (limite do servidor)',
                    UPLOAD_ERR_FORM_SIZE => 'Ficheiro demasiado grande (limite do formulário)',
                    UPLOAD_ERR_PARTIAL => 'Upload incompleto',
                    UPLOAD_ERR_NO_FILE => 'Nenhum ficheiro selecionado',
                    UPLOAD_ERR_NO_TMP_DIR => 'Diretório temporário em falta',
                    UPLOAD_ERR_CANT_WRITE => 'Erro de escrita no disco',
                    UPLOAD_ERR_EXTENSION => 'Upload bloqueado por extensão'
                ];
                
                $error_msg = $error_messages[$file['error']] ?? 'Erro desconhecido';
                echo "<div class='error'>❌ Erro no upload: $error_msg</div>";
            }
        }
        ?>

        <h2>📄 Transcrições Guardadas</h2>
        
        <?php
        $transcricoes = get_transcricoes();
        
        if (!empty($transcricoes)) {
            echo "<table>";
            echo "<tr><th>📁 Ficheiro</th><th>📝 Transcrição</th>";
            if (isset($transcricoes[0]['translation'])) {
                echo "<th>🌐 Tradução</th>";
            }
            echo "</tr>";
            
            foreach ($transcricoes as $row) {
                echo "<tr>";
                echo "<td>" . htmlspecialchars($row['filename'] ?? '') . "</td>";
                echo "<td>" . htmlspecialchars($row['transcription'] ?? '') . "</td>";
                if (isset($row['translation'])) {
                    echo "<td>" . htmlspecialchars($row['translation']) . "</td>";
                }
                echo "</tr>";
            }
            
            echo "</table>";
            
            // CSV Export
            $csv = "Filename,Transcription";
            if (isset($transcricoes[0]['translation'])) {
                $csv .= ",Translation";
            }
            $csv .= "\n";
            
            foreach ($transcricoes as $row) {
                $csv .= '"' . str_replace('"', '""', $row['filename'] ?? '') . '",';
                $csv .= '"' . str_replace('"', '""', $row['transcription'] ?? '') . '"';
                if (isset($row['translation'])) {
                    $csv .= ',"' . str_replace('"', '""', $row['translation']) . '"';
                }
                $csv .= "\n";
            }
            
            $csv_encoded = base64_encode($csv);
            echo "<a href='data:text/csv;base64,$csv_encoded' download='transcricoes.csv' class='button'>📊 Exportar CSV</a>";
            
            // Translation downloads
            foreach ($transcricoes as $row) {
                if (isset($row['translation'])) {
                    $filename = $row['filename'] ?? 'audio';
                    $translation = $row['translation'];
                    $translation_encoded = base64_encode($translation);
                    echo "<a href='data:text/plain;base64,$translation_encoded' download='{$filename}_traducao.txt' class='button'>📄 Tradução: $filename</a>";
                }
            }
        } else {
            echo "<div class='info'>📭 Ainda não há transcrições disponíveis. Faça upload de um ficheiro de áudio para começar!</div>";
        }
        ?>

        <div style="margin-top: 40px; padding: 20px; background-color: #f8f9fa; border-radius: 8px; border-left: 5px solid #4CAF50;">
            <h3>ℹ️ Informações:</h3>
            <ul>
                <li>Esta é uma versão de demonstração</li>
                <li>Suporta ficheiros .mp3 e .wav</li>
                <li>As transcrições são simuladas para teste</li>
                <li>Para produção, será necessário configurar as APIs do Azure</li>
            </ul>
        </div>
    </div>
</body>
</html>
