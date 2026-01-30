#!/bin/bash
PROJECT_ID="gen-lang-client-0692818755"

create_secret() {
    NAME=$1
    VALUE=$2
    echo "Creating secret $NAME..."
    gcloud secrets create $NAME --replication-policy="automatic" --project=$PROJECT_ID || true
    echo -n "$VALUE" | gcloud secrets versions add $NAME --data-file=- --project=$PROJECT_ID
}

# API Keys
create_secret "recall-butler-groq-api-key" "INSERT_KEY_HERE"
create_secret "recall-butler-cerebras-api-key" "INSERT_KEY_HERE"
create_secret "recall-butler-openrouter-api-key" "INSERT_KEY_HERE"
create_secret "recall-butler-tmdb-api-key" "INSERT_KEY_HERE"
create_secret "recall-butler-tmdb-read-token" "INSERT_KEY_HERE"
create_secret "recall-butler-google-api-key" "INSERT_KEY_HERE"
create_secret "recall-butler-mistral-api-key" "INSERT_KEY_HERE"

# Internal Secrets
JWT_SECRET=$(openssl rand -hex 32)
SERVICE_SECRET=$(openssl rand -base64 32)
create_secret "recall-butler-jwt-secret" "$JWT_SECRET"
create_secret "recall-butler-service-secret" "$SERVICE_SECRET"

echo "All secrets created."
