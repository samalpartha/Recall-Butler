#!/bin/bash
set -e

PROJECT_ID="gen-lang-client-0692818755"
REGION="us-central1"
REPO="recall-butler-repo"
IMAGE="server"
TAG="latest"
SERVICE_NAME="recall-butler-server"
DB_INSTANCE="$PROJECT_ID:$REGION:recall-butler-db"

# 1. Build Docker Image (Platform: linux/amd64 for Cloud Run)
echo "Building Docker image..."
cd recall_butler/recall_butler_server
docker build --platform linux/amd64 -t us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$TAG -f Dockerfile.prod .

# 2. Push to Artifact Registry
echo "Pushing image to Artifact Registry..."
docker push us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$TAG

# 3. Deploy to Cloud Run
echo "Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$TAG \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --memory 1Gi \
  --add-cloudsql-instances $DB_INSTANCE \
  --set-env-vars SERVERPOD_RUN_MODE=production \
  --set-secrets SERVERPOD_PASSWORD_database=recall-butler-db-pass:latest \
  --set-secrets SERVERPOD_PASSWORD_serviceSecret=recall-butler-service-secret:latest \
  --set-secrets SERVERPOD_PASSWORD_SHARED_JWT_SECRET=recall-butler-jwt-secret:latest \
  --set-secrets SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper=recall-butler-jwt-pepper:latest \
  --set-secrets SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey=recall-butler-jwt-private-key:latest \
  --set-secrets SERVERPOD_PASSWORD_jwtHmacSha512PublicKey=recall-butler-jwt-public-key:latest \
  --set-secrets SERVERPOD_PASSWORD_emailSecretHashPepper=recall-butler-email-pepper:latest \
  --set-secrets GROQ_API_KEY=recall-butler-groq-api-key:latest \
  --set-secrets CEREBRAS_API_KEY=recall-butler-cerebras-api-key:latest \
  --set-secrets OPENROUTER_API_KEY=recall-butler-openrouter-api-key:latest \
  --set-secrets MISTRAL_API_KEY=recall-butler-mistral-api-key:latest \
  --set-secrets GOOGLE_API_KEY=recall-butler-google-api-key:latest \
  --set-secrets TMDB_API_KEY=recall-butler-tmdb-api-key:latest \
  --set-secrets TMDB_READ_TOKEN=recall-butler-tmdb-read-token:latest \
  --project $PROJECT_ID

# 4. Run Migrations
echo "Running database migrations..."
JOB_NAME="recall-butler-migration-job"
# Try to create job, if exists update it
gcloud run jobs create $JOB_NAME \
  --image us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$TAG \
  --region $REGION \
  --set-env-vars SERVERPOD_RUN_MODE=production \
  --set-secrets SERVERPOD_PASSWORD_database=recall-butler-db-pass:latest \
  --set-secrets SERVERPOD_PASSWORD_serviceSecret=recall-butler-service-secret:latest \
  --set-secrets SERVERPOD_PASSWORD_SHARED_JWT_SECRET=recall-butler-jwt-secret:latest \
  --set-secrets SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper=recall-butler-jwt-pepper:latest \
  --set-secrets SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey=recall-butler-jwt-private-key:latest \
  --set-secrets SERVERPOD_PASSWORD_jwtHmacSha512PublicKey=recall-butler-jwt-public-key:latest \
  --set-secrets SERVERPOD_PASSWORD_emailSecretHashPepper=recall-butler-email-pepper:latest \
  --add-cloudsql-instances $DB_INSTANCE \
  --command "/app/server" \
  --args "--apply-migrations" \
  --project $PROJECT_ID || \
gcloud run jobs update $JOB_NAME \
  --image us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$TAG \
  --region $REGION \
  --set-env-vars SERVERPOD_RUN_MODE=production \
  --set-secrets SERVERPOD_PASSWORD_database=recall-butler-db-pass:latest \
  --set-secrets SERVERPOD_PASSWORD_serviceSecret=recall-butler-service-secret:latest \
  --set-secrets SERVERPOD_PASSWORD_SHARED_JWT_SECRET=recall-butler-jwt-secret:latest \
  --set-secrets SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper=recall-butler-jwt-pepper:latest \
  --set-secrets SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey=recall-butler-jwt-private-key:latest \
  --set-secrets SERVERPOD_PASSWORD_jwtHmacSha512PublicKey=recall-butler-jwt-public-key:latest \
  --set-secrets SERVERPOD_PASSWORD_emailSecretHashPepper=recall-butler-email-pepper:latest \
  --add-cloudsql-instances $DB_INSTANCE \
  --command "/app/server" \
  --args "--apply-migrations" \
  --project $PROJECT_ID

echo "Executing migration job..."
gcloud run jobs execute $JOB_NAME --region $REGION --project $PROJECT_ID --wait

echo "Deployment and migrations successful!"
