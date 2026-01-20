# 🚀 Recall Butler Deployment Guide

## Prerequisites

### Required Software

- **Docker** 20.10+
- **Kubernetes** 1.24+ (kubectl configured)
- **PostgreSQL** 16+ with pgvector extension
- **Redis** 7.0+ (optional, for caching)
- **Git**

### Required Accounts

- Docker Hub (for container images)
- Cloud provider (GCP, AWS, or Azure for Kubernetes)
- Domain registrar (for API domain)

---

## Environment Setup

### 1. Clone Repository

```bash
git clone https://github.com/yourorg/recall-butler.git
cd recall-butler
```

### 2. Configure Environment Variables

```bash
cp .env.template .env
```

Edit `.env` and set all required variables:

```bash
# Generate secrets
openssl rand -base64 32  # For JWT_SECRET
openssl rand -base64 32  # For ENCRYPTION_MASTER_KEY

# Set API keys
OPENROUTER_API_KEY=your_key_here

# Configure database
DATABASE_URL=postgresql://user:pass@host:5432/recall_butler
```

---

## Local Development

### 1. Start PostgreSQL with pgvector

```bash
docker run -d \
  --name postgres-pgvector \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=recall_butler \
  -p 5432:5432 \
  pgvector/pgvector:pg16
```

### 2. Run Database Migrations

```bash
cd recall_butler_server
serverpod create-migration
serverpod apply-migrations --mode development
```

### 3. Start Backend Server

```bash
cd recall_butler_server
dart run bin/main.dart
```

### 4. Start Flutter App

```bash
cd recall_butler_flutter
flutter run -d chrome  # For web
# OR
flutter run -d macos   # For desktop
# OR  
flutter run           # For mobile (with emulator/device)
```

---

## Production Deployment

### Step 1: Build Docker Images

```bash
# Build backend image
cd recall_butler_server
docker build -f Dockerfile.prod -t your-dockerhub/recall-butler-server:latest .
docker push your-dockerhub/recall-butler-server:latest
```

### Step 2: Create Kubernetes Cluster

#### GCP (GKE)

```bash
gcloud container clusters create recall-butler-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --enable-autoscaling \
  --min-nodes 3 \
  --max-nodes 10
```

#### AWS (EKS)

```bash
eksctl create cluster \
  --name recall-butler-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 3 \
  --nodes-max 10
```

### Step 3: Create Kubernetes Namespace

```bash
kubectl create namespace recall-butler
```

### Step 4: Create Kubernetes Secrets

```bash
kubectl create secret generic recall-butler-secrets \
  --from-literal=JWT_SECRET=$(openssl rand -base64 32) \
  --from-literal=ENCRYPTION_MASTER_KEY=$(openssl rand -base64 32) \
  --from-literal=OPENROUTER_API_KEY=your_key \
  --from-literal=DATABASE_URL=postgresql://user:pass@host:5432/recall_butler \
  -n recall-butler
```

### Step 5: Deploy to Kubernetes

```bash
# Update image in deployment file
export DOCKER_IMAGE=your-dockerhub/recall-butler-server:latest
envsubst < k8s/deployment-production.yaml | kubectl apply -f -

# Apply monitoring
kubectl apply -f k8s/monitoring.yaml -n recall-butler
```

### Step 6: Configure Ingress & SSL

```bash
# Install cert-manager for SSL
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@recallbutler.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### Step 7: Verify Deployment

```bash
# Check pods
kubectl get pods -n recall-butler

# Check services
kubectl get svc -n recall-butler

# Check ingress
kubectl get ingress -n recall-butler

# View logs
kubectl logs -f deployment/recall-butler-server -n recall-butler
```

### Step 8: Setup Monitoring

Access Grafana dashboard:

```bash
kubectl port-forward svc/grafana 3000:3000 -n recall-butler
# Open http://localhost:3000
```

---

## Database Management

### Run Migrations

```bash
kubectl exec -it deployment/recall-butler-server -n recall-butler -- \
  serverpod apply-migrations --mode production
```

### Backup Database

```bash
# Manual backup
./scripts/backup_database.sh

# Setup automated backups (cron)
crontab -e
# Add: 0 2 * * * /path/to/backup_database.sh
```

### Restore from Backup

```bash
gunzip < backup_file.sql.gz | psql $DATABASE_URL
```

---

## Monitoring & Observability

### Access Metrics

- **Prometheus**: `http://prometheus.recallbutler.com`
- **Grafana**: `http://grafana.recallbutler.com`

### View Application Logs

```bash
# Real-time logs
kubectl logs -f deployment/recall-butler-server -n recall-butler

# Last 100 lines
kubectl logs --tail=100 deployment/recall-butler-server -n recall-butler
```

### Health Checks

```bash
curl https://api.recallbutler.com/health
```

Expected response:

```json
{
  "status": "healthy",
  "version": "2.0.0",
  "uptime": 86400,
  "database": "connected",
  "redis": "connected"
}
```

---

## Scaling

### Manual Scaling

```bash
kubectl scale deployment recall-butler-server --replicas=5 -n recall-butler
```

### Auto-scaling

Already configured via HorizontalPodAutoscaler in deployment manifest:

- Min replicas: 3
- Max replicas: 10
- CPU target: 70%
- Memory target: 80%

---

## Troubleshooting

### Pod Crashes

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n recall-butler

# Check recent logs
kubectl logs --previous <pod-name> -n recall-butler
```

### Database Connection Issues

```bash
# Test database connectivity from pod
kubectl exec -it deployment/recall-butler-server -n recall-butler -- \
  psql $DATABASE_URL -c "SELECT 1"
```

### High Memory Usage

```bash
# Check resource usage
kubectl top pods -n recall-butler

# Increase memory limits in deployment.yaml
resources:
  limits:
    memory: "2Gi"  # Increase from 1Gi
```

---

## CI/CD Pipeline

The GitHub Actions pipeline automatically:

1. ✅ Runs all tests
2. ✅ Performs security scanning
3. ✅ Builds Docker images
4. ✅ Deploys to staging (develop branch)
5. ✅ Deploys to production (main branch)

### Triggering Manual Deployment

```bash
# Via GitHub CLI
gh workflow run ci-cd.yml -f environment=production

# Or push to main branch
git push origin main
```

---

## Security Checklist

Before going live:

- [ ] All secrets in environment variables (not code)
- [ ] HTTPS enabled with valid SSL certificate
- [ ] Rate limiting configured
- [ ] CSRF protection enabled
- [ ] Input sanitization active
- [ ] Database backups automated
- [ ] Monitoring and alerting configured
- [ ] Security headers enabled
- [ ] Database credentials rotated
- [ ] No debug mode in production

---

## Performance Optimization

### Enable Caching

```bash
# Deploy Redis
helm install redis bitnami/redis -n recall-butler

# Update environment
REDIS_URL=redis://redis-master:6379
```

### Database Connection Pooling

Already configured in `DATABASE_URL`:

```
?poolsize=20&connection_limit=50
```

### CDN Configuration

For Flutter web assets:

```nginx
location /assets/ {
  expires 1y;
  add_header Cache-Control "public, immutable";
}
```

---

## Support

- **Documentation**: <https://docs.recallbutler.com>
- **API Reference**: <https://api.recallbutler.com/docs>
- **Support Email**: <support@recallbutler.com>
- **GitHub Issues**: <https://github.com/yourorg/recall-butler/issues>

---

**Deployment Status**: ✅ PRODUCTION-READY
