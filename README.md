# LiteLLM Gateway on GKE with Vertex AI

This repository contains all the necessary configuration files and deployment scripts to deploy LiteLLM Gateway on Google Kubernetes Engine (GKE) with Vertex AI integration and PostgreSQL database.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   LoadBalancer  │    │  LiteLLM Gateway│    │   PostgreSQL    │
│    Service      │───▶│     Pod         │───▶│    Database     │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Vertex AI     │
                       │   (Gemini Pro)  │
                       └─────────────────┘
```

## 📋 Prerequisites

Before deploying, ensure you have:

1. **GKE Cluster**: A running GKE cluster with sufficient resources
2. **kubectl**: Configured to connect to your GKE cluster
3. **gcloud CLI**: Installed and authenticated
4. **Vertex AI Service Account**: `VertexAiKey.json` file with proper permissions
5. **LoadBalancer Quota**: Ensure your GCP project has LoadBalancer quota available

### Required GCP APIs
Make sure these APIs are enabled in your GCP project:
- Kubernetes Engine API
- Vertex AI API
- Compute Engine API

### Vertex AI Permissions
Your service account should have these roles:
- `roles/aiplatform.user`
- `roles/ml.developer`

## 📁 File Structure

```
.
├── namespace.yaml              # Kubernetes namespace
├── vertex-ai-secret.yaml      # Vertex AI credentials secret template
├── postgre.yaml               # PostgreSQL deployment with PVC
├── litellm-config.yaml        # LiteLLM configuration
├── litellm-deployment.yaml    # LiteLLM Gateway deployment
├── service.yaml               # LoadBalancer service
├── deploy.sh                  # Automated deployment script
├── VertexAiKey.json          # Your Vertex AI service account key
└── README.md                 # This file
```

## 🚀 Quick Deployment

### Option 1: Automated Deployment (Recommended)

```bash
# Make the script executable
chmod +x deploy.sh

# Deploy everything
./deploy.sh deploy
```

### Option 2: Manual Deployment

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Create Vertex AI secret
kubectl create secret generic vertex-ai-credentials \
  --from-file=vertex-key.json=VertexAiKey.json \
  -n litellm

# 3. Deploy PostgreSQL
kubectl apply -f postgre.yaml

# 4. Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n litellm --timeout=300s

# 5. Deploy LiteLLM configuration
kubectl apply -f litellm-config.yaml

# 6. Deploy LiteLLM Gateway
kubectl apply -f litellm-deployment.yaml

# 7. Create service
kubectl apply -f service.yaml

# 8. Wait for deployment
kubectl wait --for=condition=available deployment/litellm-proxy -n litellm --timeout=600s
```

## 📊 Accessing the Gateway

After deployment, get the external IP:

```bash
kubectl get service litellm-service -n litellm
```

### Available Endpoints

- **Gateway API**: `http://<EXTERNAL_IP>/v1/chat/completions`
- **Admin UI**: `http://<EXTERNAL_IP>/ui`
- **API Documentation**: `http://<EXTERNAL_IP>/docs`
- **Health Check**: `http://<EXTERNAL_IP>/health`

### Default Credentials

- **Master Key**: `sk-1234`
- **UI Username**: `admin`
- **UI Password**: `admin123`

## 🤖 Available Models

The gateway is configured with these Vertex AI models:

- **gemini-pro**: `vertex_ai/gemini-pro`
- **gemini-pro-vision**: `vertex_ai/gemini-pro-vision`
- **gemini-flash**: `vertex_ai/gemini-2.5-flash-lite`

## 📝 Usage Examples

### Using curl

```bash
curl -X POST "http://<EXTERNAL_IP>/v1/chat/completions" \
  -H "Authorization: Bearer sk-1234" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-pro",
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ]
  }'
```

### Using Python

```python
import openai

client = openai.OpenAI(
    api_key="sk-1234",
    base_url="http://<EXTERNAL_IP>/v1"
)

response = client.chat.completions.create(
    model="gemini-pro",
    messages=[
        {"role": "user", "content": "Hello, how are you?"}
    ]
)

print(response.choices[0].message.content)
```

## 🔧 Configuration

### Environment Variables

Key environment variables in the deployment:

- `GOOGLE_APPLICATION_CREDENTIALS`: Path to Vertex AI service account key
- `DATABASE_URL`: PostgreSQL connection string
- `STORE_MODEL_IN_DB`: Enable database storage for models

### Resource Limits

Current resource configuration:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "2000m"
```

### Database Configuration

- **Database**: PostgreSQL 15
- **Storage**: 10Gi PersistentVolume
- **Connection**: Internal cluster service

## 🔍 Monitoring & Troubleshooting

### Check Deployment Status

```bash
# Check all resources
./deploy.sh status

# Check pods
kubectl get pods -n litellm

# Check logs
kubectl logs -f deployment/litellm-proxy -n litellm
kubectl logs -f deployment/postgres -n litellm
```

### Common Issues

1. **External IP Pending**: Wait 5-10 minutes for GCP to assign the IP
2. **Pod CrashLoopBackOff**: Check logs for configuration issues
3. **Database Connection Failed**: Ensure PostgreSQL is running and accessible

### Health Checks

The deployment includes:
- **Liveness Probe**: `/health` endpoint
- **Readiness Probe**: `/health` endpoint
- **Init Container**: Waits for PostgreSQL to be ready

## 🧹 Cleanup

To remove all resources:

```bash
./deploy.sh cleanup
```

Or manually:

```bash
kubectl delete namespace litellm
```

## 🔒 Security Considerations

1. **Change Default Credentials**: Update master key and UI credentials in production
2. **Network Policies**: Consider implementing network policies for additional security
3. **TLS/SSL**: Add TLS termination for production use
4. **RBAC**: Implement proper RBAC for service accounts
5. **Secret Management**: Consider using Google Secret Manager instead of Kubernetes secrets

## 📈 Scaling

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: litellm-hpa
  namespace: litellm
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: litellm-proxy
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Database Scaling

For production, consider:
- Google Cloud SQL for PostgreSQL
- Connection pooling
- Read replicas

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review LiteLLM documentation
3. Check GKE and Vertex AI documentation
4. Open an issue in this repository
