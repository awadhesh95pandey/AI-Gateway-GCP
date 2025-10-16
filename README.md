# LiteLLM Gateway on GKE with Helm

This repository contains a production-ready Helm chart for deploying LiteLLM Gateway on Google Kubernetes Engine (GKE) with Vertex AI integration.

## 🚀 Overview

LiteLLM Gateway provides a unified OpenAI-compatible API interface for Google's Vertex AI models. This Helm deployment includes:

- **LiteLLM Proxy Server**: Main gateway service with auto-scaling
- **PostgreSQL Database**: Persistent storage for configuration and usage data
- **Vertex AI Integration**: Direct connection to Google's AI models
- **Production Features**: Health checks, monitoring, security contexts

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client Apps   │───▶│  LiteLLM Gateway │───▶│   Vertex AI     │
│  (OpenAI SDK)   │    │   (Kubernetes)   │    │   (Gemini Pro)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   PostgreSQL     │
                       │  (Persistent)    │
                       └──────────────────┘
```

## ✨ Features

### Core Features
- ✅ **OpenAI-Compatible API**: Use OpenAI SDK with Vertex AI models
- ✅ **Helm-Based Deployment**: Professional package management
- ✅ **Auto-Scaling**: Horizontal Pod Autoscaler with CPU/Memory targets
- ✅ **Production-Ready**: Resource limits, health checks, security contexts
- ✅ **Persistent Storage**: PostgreSQL with persistent volumes
- ✅ **Multiple Models**: Gemini Pro, Gemini Pro Vision, Gemini Flash
- ✅ **Easy Configuration**: Values-based customization

### Production Features (New!)
- 🛡️ **Cost Monitoring**: Budget limits, spend tracking, real-time alerts
- 🛡️ **Guardrails**: Rate limiting, token limits, content filtering
- 📊 **Monitoring**: Prometheus metrics, Grafana dashboards, alerting rules
- 🔗 **Kong Integration**: Ready for Kong Gateway routing
- 🚀 **High Availability**: Multi-replica deployment with anti-affinity
- 💾 **Redis Caching**: Optional cost optimization (disabled by default)
- 🔒 **Security**: Network policies, security contexts, secret management

## 🚀 Quick Start

### Prerequisites

- **Kubernetes cluster** (GKE recommended)
- **Helm 3.x** installed
- **kubectl** configured
- **Vertex AI service account key** (`VertexAiKey.json`)

## 🏭 Production Deployment (Recommended)

For production deployments with guardrails, monitoring, and Kong integration:

```bash
# Clone repository
git clone https://github.com/awadhesh95pandey/AI-Gateway-GCP.git
cd AI-Gateway-GCP

# Use production configuration
cp helm-chart/values-production.yaml values-custom.yaml

# Configure your settings (see PRODUCTION-DEPLOYMENT.md)
# Then deploy:
helm upgrade --install litellm ./helm-chart \
  --values values-custom.yaml \
  --namespace litellm \
  --create-namespace \
  --wait
```

📖 **See [PRODUCTION-DEPLOYMENT.md](PRODUCTION-DEPLOYMENT.md) for complete production setup guide with:**
- Cost monitoring and budget controls
- Rate limiting and guardrails
- Prometheus metrics and alerting
- Kong Gateway integration
- High availability configuration
- Security best practices

## 🛠️ Development Deployment

### 1. Setup

```bash
git clone <repository-url>
cd AI-Gateway-GCP

# Make deployment script executable
chmod +x helm-deploy.sh
```

### 2. Configure

```bash
# Encode your service account key
./helm-deploy.sh encode-key

# Create configuration file (this will prompt you to edit values)
./helm-deploy.sh deploy
```

Edit `values-custom.yaml` with your settings:

```yaml
# Required: Your GCP Project ID
vertexAI:
  projectId: "your-gcp-project-id"
  serviceAccountKey: "base64-encoded-key-here"

# Required: Secure credentials
litellm:
  env:
    LITELLM_MASTER_KEY: "sk-your-secure-key-here"
    UI_PASSWORD: "your-secure-password"

postgresql:
  auth:
    password: "your-secure-db-password"
```

### 3. Deploy

```bash
./helm-deploy.sh deploy
```

### 4. Access

Get your gateway endpoints:

```bash
./helm-deploy.sh status
```

Your gateway will be available at:
- **API**: `http://<EXTERNAL_IP>/v1/chat/completions`
- **Admin UI**: `http://<EXTERNAL_IP>/ui`
- **Docs**: `http://<EXTERNAL_IP>/docs`
- **Health**: `http://<EXTERNAL_IP>/health`

## 📋 Management Commands

```bash
./helm-deploy.sh [command]

Commands:
  deploy     - Deploy LiteLLM Gateway (default)
  status     - Show deployment status
  test       - Test the deployment
  logs       - Show logs from LiteLLM Gateway
  cleanup    - Remove all resources
  encode-key - Encode VertexAiKey.json for values file
```

## 🔧 Configuration

### Available Models

- **gemini-pro**: General text generation
- **gemini-pro-vision**: Vision and multimodal tasks  
- **gemini-flash**: Fast responses for simple queries

### Resource Defaults

- **LiteLLM**: 4Gi memory, 2 CPU cores
- **PostgreSQL**: 1Gi memory, 500m CPU
- **Storage**: 10Gi persistent volume
- **Auto-scaling**: 1-10 replicas based on CPU/Memory

### Security Features

- Service account key stored as Kubernetes secret
- Security contexts with non-root users
- Resource limits to prevent resource exhaustion
- Configurable network policies

## 💻 Usage Examples

### OpenAI SDK (Python)

```python
import openai

client = openai.OpenAI(
    api_key="sk-your-master-key",
    base_url="http://<EXTERNAL_IP>/v1"
)

response = client.chat.completions.create(
    model="gemini-pro",
    messages=[
        {"role": "user", "content": "Hello from Kubernetes!"}
    ]
)

print(response.choices[0].message.content)
```

### cURL

```bash
curl -X POST "http://<EXTERNAL_IP>/v1/chat/completions" \
  -H "Authorization: Bearer sk-your-master-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-pro",
    "messages": [{"role": "user", "content": "What is Kubernetes?"}]
  }'
```

## 📊 Monitoring

### View Logs

```bash
# Real-time logs
./helm-deploy.sh logs

# Specific component logs
kubectl logs -l app.kubernetes.io/name=litellm-gateway -n litellm
```

### Check Status

```bash
# Deployment status
./helm-deploy.sh status

# Detailed pod information
kubectl get pods -n litellm -o wide
```

### Health Checks

```bash
# Test deployment
./helm-deploy.sh test

# Manual health check
curl http://<EXTERNAL_IP>/health
```

## 🔄 Updates and Scaling

### Update Configuration

1. Edit `values-custom.yaml`
2. Run: `./helm-deploy.sh deploy`

### Scale Manually

```bash
kubectl scale deployment litellm-litellm-gateway -n litellm --replicas=3
```

### Update Image

```yaml
# In values-custom.yaml
litellm:
  image:
    tag: "new-version"
```

## 🐛 Troubleshooting

### Common Issues

1. **Pods not starting**: Check resource limits and node capacity
2. **Database connection failed**: Verify PostgreSQL is running
3. **Vertex AI authentication failed**: Check service account key encoding
4. **External IP not assigned**: Check LoadBalancer service and quotas

### Debug Commands

```bash
# Check pod events
kubectl describe pod <pod-name> -n litellm

# Check service status
kubectl get services -n litellm

# View all events
kubectl get events -n litellm --sort-by='.lastTimestamp'
```

## 🗑️ Cleanup

```bash
./helm-deploy.sh cleanup
```

This removes:
- Helm release and all resources
- Namespace and persistent volumes
- LoadBalancer and external IPs

## 📚 Documentation

- **[HELM-README.md](./HELM-README.md)** - Detailed Helm chart documentation
- **[values-example.yaml](./helm-chart/values-example.yaml)** - Configuration examples
- **[LiteLLM Docs](https://docs.litellm.ai/)** - Official LiteLLM documentation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes with the Helm chart
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
1. Check the [troubleshooting section](#-troubleshooting)
2. Review logs: `./helm-deploy.sh logs`
3. Check Kubernetes events: `kubectl get events -n litellm`
4. Open an issue in this repository
