import logging
import os
import tempfile
import azure.functions as func
from azure.storage.blob import BlobServiceClient
from azure.cosmos import CosmosClient
import azure.cognitiveservices.speech as speechsdk
import requests

def main(blob: func.InputStream):
    logging.info(f"Processando blob: {blob.name}, {blob.length} bytes")

    # === ENV ===
    speech_key = os.environ["SPEECH_KEY"]
    speech_region = os.environ["SPEECH_REGION"]
    cosmos_conn = os.environ["COSMOS_DB_CONN_STRING"]
    db_name = os.environ["COSMOS_DB_NAME"]
    container_name = os.environ["COSMOS_DB_CONTAINER_NAME"]
    translator_key = os.environ["TRANSLATOR_KEY"]
    translator_endpoint = os.environ["TRANSLATOR_ENDPOINT"]

    # === SALVAR TEMPORARIAMENTE O ÁUDIO ===
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp_audio:
        tmp_audio.write(blob.read())
        temp_audio_path = tmp_audio.name

    # === TRANSCRIÇÃO ===
    speech_config = speechsdk.SpeechConfig(subscription=speech_key, region=speech_region)
    audio_config = speechsdk.audio.AudioConfig(filename=temp_audio_path)
    recognizer = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)

    result = recognizer.recognize_once()
    transcription = result.text if result.reason == speechsdk.ResultReason.RecognizedSpeech else "Erro na transcrição"
    logging.info(f"Transcrição: {transcription}")

    # === TRADUÇÃO ===
    headers = {
        "Ocp-Apim-Subscription-Key": translator_key,
        "Ocp-Apim-Subscription-Region": speech_region,
        "Content-type": "application/json"
    }
    params = {
        "api-version": "3.0",
        "from": "auto",
        "to": ["pt"]
    }
    body = [{"text": transcription}]
    translate_url = f"{translator_endpoint}/translate"

    translation = "Erro na tradução"
    try:
        response = requests.post(translate_url, params=params, headers=headers, json=body)
        response.raise_for_status()
        translation = response.json()[0]["translations"][0]["text"]
        logging.info(f"Tradução: {translation}")
    except Exception as e:
        logging.error(f"Erro ao traduzir: {e}")

    # === GRAVAR NO COSMOS DB ===
    client = CosmosClient.from_connection_string(cosmos_conn)
    db = client.get_database_client(db_name)
    container = db.get_container_client(container_name)

    filename = os.path.basename(blob.name)

    container.upsert_item({
        "id": filename,
        "filename": filename,
        "transcription": transcription,
        "translation": translation
    })

    logging.info("✅ Transcrição e tradução gravadas com sucesso.")
