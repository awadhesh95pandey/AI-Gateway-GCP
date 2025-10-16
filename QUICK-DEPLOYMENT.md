# Quick LiteLLM Gateway Deployment

This guide provides a simple deployment without advanced monitoring features to avoid CRD dependencies.

## 🚀 Quick Start (No Prometheus Operator Required)

### Prerequisites
- GKE cluster
- Helm 3.x installed
- kubectl configured
- Vertex AI service account key (`VertexAiKey.json`)

### 1. Prepare Configuration

```bash
# Clone the repository
git clone https://github.com/awadhesh95pandey/AI-Gateway-GCP.git
cd AI-Gateway-GCP

# Copy simple values template
cp helm-chart/values-simple.yaml values-custom.yaml

# Encode your service account key
cat VertexAiKey.json | base64 -w 0
```

### 2. Configure values-custom.yaml

Edit `values-custom.yaml` and set these **REQUIRED** values:

```yaml
# Vertex AI configuration - REQUIRED
vertexAI:
  projectId: "your-gcp-project-id"  # Replace with your GCP project
  serviceAccountKey: "base64-encoded-key"  # From step 1

# Security credentials - REQUIRED
litellm:
  env:
    LITELLM_MASTER_KEY: "sk-your-secure-key-here"  # Generate a secure key
    UI_PASSWORD: "your-secure-password"            # Set a secure password

  config:
    general_settings:
      master_key: "sk-your-secure-key-here"        # Same as above
      ui_password: "your-secure-password"          # Same as above

postgresql:
  auth:
    password: "your-secure-db-password"            # Set a secure password
```

### 3. Deploy

```bash
# Deploy with simple configuration
helm install litellm ./helm-chart \
  --values values-custom.yaml \
  --namespace litellm \
  --create-namespace \
  --wait \
  --timeout=10m
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods -n litellm

# Check services
kubectl get services -n litellm

# Check logs
kubectl logs -l app.kubernetes.io/name=litellm-gateway -n litellm
```

### 5. Access the Gateway

```bash
# Port forward to access locally
kubectl port-forward -n litellm service/litellm-litellm-gateway 4000:4000

# Test the API
curl http://localhost:4000/health
```

## 🔧 Configuration

### Basic Model Configuration
The simple deployment includes:
- **Gemini Pro**: `vertex_ai/gemini-pro` model
- **Basic logging**: Request/response logging enabled
- **Health checks**: Liveness and readiness probes
- **PostgreSQL**: Persistent database for configuration

### Environment Variables
Key environment variables set:
- `LITELLM_MASTER_KEY`: API authentication key
- `LITELLM_LOG`: Enable logging
- `UI_USERNAME`: Web UI username (admin)
- `UI_PASSWORD`: Web UI password

## 🌐 Testing the API

### Using curl
```bash
# Health check
curl http://localhost:4000/health

# List models
curl -H "Authorization: Bearer sk-your-secure-key-here" \
  http://localhost:4000/v1/models

# Chat completion
curl -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-your-secure-key-here" \
  -d '{
    "model": "gemini-pro",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Using OpenAI Python SDK
```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-your-secure-key-here",
    base_url="http://localhost:4000"
)

response = client.chat.completions.create(
    model="gemini-pro",
    messages=[{"role": "user", "content": "Hello!"}]
)

print(response.choices[0].message.content)
```

## 🔄 Upgrading to Production

Once your basic deployment is working, you can upgrade to the full production configuration:

### 1. Install Prometheus Operator (Optional)
```bash
# Install Prometheus Operator for monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus-operator prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### 2. Upgrade to Production Configuration
```bash
# Copy production values
cp helm-chart/values-production.yaml values-production-custom.yaml

# Edit with your settings
# Then upgrade:
helm upgrade litellm ./helm-chart \
  --values values-production-custom.yaml \
  --namespace litellm
```

## 🚨 Troubleshooting

### Common Issues

#### Pod CrashLoopBackOff
```bash
# Check logs
kubectl logs -l app.kubernetes.io/name=litellm-gateway -n litellm

# Common causes:
# 1. Invalid service account key
# 2. Wrong GCP project ID
# 3. Missing credentials
```

#### Service Account Key Issues
```bash
# Verify base64 encoding
echo "your-base64-key" | base64 -d | jq .

# Should show valid JSON service account
```

#### Database Connection Issues
```bash
# Check PostgreSQL pod
kubectl get pods -n litellm | grep postgresql

# Check PostgreSQL logs
kubectl logs -l app.kubernetes.io/name=postgresql -n litellm
```

### Useful Commands
```bash
# Get all resources
kubectl get all -n litellm

# Describe deployment
kubectl describe deployment litellm-litellm-gateway -n litellm

# Check events
kubectl get events -n litellm --sort-by='.lastTimestamp'

# Delete deployment
helm uninstall litellm -n litellm
```

## 📈 Next Steps

1. **Test API endpoints** with your applications
2. **Configure additional models** in the values file
3. **Set up Kong Gateway** for production routing
4. **Enable monitoring** with Prometheus Operator
5. **Add Redis caching** for cost optimization
6. **Configure rate limiting** and guardrails

## 🔐 Security Notes

- Change all default passwords and keys
- Use strong, unique credentials
- Consider using Kubernetes secrets for sensitive data
- Enable network policies in production
- Regularly rotate service account keys

This simple deployment gets you started quickly without complex dependencies!

