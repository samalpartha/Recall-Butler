#!/bin/bash
set -e

# Usage: ./deploy_frontend.sh <BACKEND_URL>
if [ -z "$1" ]; then
  echo "Usage: ./deploy_frontend.sh <BACKEND_URL>"
  echo "Example: ./deploy_frontend.sh https://recall-butler-server-xyz-uc.a.run.app"
  exit 1
fi

BACKEND_URL=$1
echo "Deploying frontend with BACKEND_URL=$BACKEND_URL"

cd recall_butler/recall_butler_flutter

# Build web app with production backend URL
echo "Building Flutter web app..."
flutter build web --release --dart-define=BACKEND_URL=$BACKEND_URL --wasm

# Deploy to Firebase Hosting
echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting
