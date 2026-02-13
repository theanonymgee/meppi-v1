#!/usr/bin/env python3
"""
BGE-M3 Embedding Server for MEPPI Rails
Simple HTTP API for text embeddings using BGE-M3 model.
"""

import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from sentence_transformers import SentenceTransformer

# Configuration
BGE_MODEL_PATH = "/home/theanonymgee/.openclaw/workspace/dev/tools/models/bge-m3/models--BAAI--bge-m3/snapshots/5617a9f61b028005a4858fdac845db406aefb181"
EMBEDDING_DIM = 1024

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

embedder = None

@app.before_request
def load_model():
    global embedder
    if embedder is None:
        print("Loading BGE-M3 model...")
        try:
            embedder = SentenceTransformer(BGE_MODEL_PATH)
            print("Model loaded successfully!")
        except Exception as e:
            print(f"Failed to load model: {e}")
            return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "model": "BAAI/bge-m3", "dimensions": EMBEDDING_DIM})

@app.route('/embeddings', methods=['POST'])
def embed():
    data = request.get_json()
    text = data.get('text')
    if not text:
        return jsonify({"error": "Missing text"}), 400
    if embedder is None:
        return jsonify({"error": "Model not loaded"}), 503
    try:
        embedding = embedder.encode(text, normalize_embeddings=True)
        return jsonify({"embedding": embedding.tolist()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/embeddings/batch', methods=['POST'])
def embed_batch():
    data = request.get_json()
    texts = data.get('texts')
    if not texts:
        return jsonify({"error": "Missing texts"}), 400
    if embedder is None:
        return jsonify({"error": "Model not loaded"}), 503
    try:
        embeddings = embedder.encode(texts, normalize_embeddings=True)
        return jsonify({"embeddings": embeddings.tolist()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.getenv('BGE_M3_PORT', 8001))
    print(f"Starting BGE-M3 server on port {port}...")
    app.run(host='127.0.0.1', port=port, debug=False)
