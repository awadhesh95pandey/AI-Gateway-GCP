# LiteLLM Gateway Helm Chart

This Helm chart deploys LiteLLM Gateway on Kubernetes with Vertex AI integration and PostgreSQL database.

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (GKE recommended)
- Helm 3.x installed
- kubectl configured
- Vertex AI service account key (`VertexAiKey.json`)

### 1. Clone and Setup

```bash
git clone <repository-url>
cd AI-Gateway-GCP
```

### 2. Prepare Configuration

```bash
# Make the deployment script executable
chmod +x helm-deploy.sh

# Encode your service account key
./helm-deploy.sh encode-key

# This will create values-custom.yaml from the example
./helm-deploy.sh deploy
```

### 3. Edit Configuration

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

### 4. Deploy

```bash
./helm-deploy.sh deploy
```

## 📋 Available Commands

```bash
./helm-deploy.sh [command]

Commands:
  deploy     - Deploy LiteLLM Gateway (default)
  status     - Show deployment status
  test       - Test the deployment
  logs       - Show logs from LiteLLM Gateway
  cleanup    - Remove all LiteLLM resources
  encode-key - Encode VertexAiKey.json for values file
```

## 🔧 Configuration Options

### Core Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Kubernetes namespace | `litellm` |
| `vertexAI.projectId` | GCP Project ID | `""` (required) |
| `vertexAI.serviceAccountKey` | Base64 encoded service account key | `""` (required) |
| `vertexAI.location` | Vertex AI location | `us-central1` |

### LiteLLM Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `litellm.image.repository` | LiteLLM image repository | `ghcr.io/berriai/litellm` |
| `litellm.image.tag` | LiteLLM image tag | `main-latest` |
| `litellm.replicaCount` | Number of replicas | `1` |
| `litellm.env.LITELLM_MASTER_KEY` | Master API key | `sk-1234` |
| `litellm.env.UI_USERNAME` | UI username | `admin` |
| `litellm.env.UI_PASSWORD` | UI password | `admin123` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `litellm.service.type` | Service type | `LoadBalancer` |
| `litellm.service.port` | Service port | `80` |
| `litellm.service.targetPort` | Container port | `4000` |

### PostgreSQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `postgresql.auth.database` | Database name | `litellm` |
| `postgresql.auth.username` | Database username | `litellm` |
| `postgresql.auth.password` | Database password | `password` |
| `postgresql.persistence.enabled` | Enable persistence | `true` |
| `postgresql.persistence.size` | Storage size | `10Gi` |

### Autoscaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `litellm.autoscaling.enabled` | Enable HPA | `true` |
| `litellm.autoscaling.minReplicas` | Minimum replicas | `1` |
| `litellm.autoscaling.maxReplicas` | Maximum replicas | `10` |
| `litellm.autoscaling.targetCPUUtilizationPercentage` | CPU target | `80` |

## 🔐 Security Best Practices

### 1. Secure Credentials

Always use strong, unique passwords:

```yaml
litellm:
  env:
    LITELLM_MASTER_KEY: "sk-$(openssl rand -hex 32)"
    UI_PASSWORD: "$(openssl rand -base64 32)"

postgresql:
  auth:
    password: "$(openssl rand -base64 32)"
```

### 2. Network Security

For internal-only access:

```yaml
litellm:
  service:
    type: LoadBalancer
    annotations:
      cloud.google.com/load-balancer-type: "Internal"
```

### 3. Resource Limits

Configure appropriate resource limits:

```yaml
litellm:
  resources:
    limits:
      memory: "4Gi"
      cpu: "2000m"
    requests:
      memory: "2Gi"
      cpu: "1000m"
```

## 🧪 Testing

### Health Check

```bash
# Get external IP
kubectl get services -n litellm

# Test health endpoint
curl http://<EXTERNAL_IP>/health
```

### API Test

```bash
curl -X POST "http://<EXTERNAL_IP>/v1/chat/completions" \
  -H "Authorization: Bearer sk-your-master-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-pro",
    "messages": [{"role": "user", "content": "Hello from Kubernetes!"}]
  }'
```

### UI Access

Visit `http://<EXTERNAL_IP>/ui` and login with your configured credentials.

## 📊 Monitoring

### View Logs

```bash
# LiteLLM Gateway logs
./helm-deploy.sh logs

# PostgreSQL logs
kubectl logs -l app.kubernetes.io/name=litellm-gateway-postgresql -n litellm
```

### Check Status

```bash
./helm-deploy.sh status
```

### Metrics

The deployment includes resource monitoring. You can integrate with Prometheus/Grafana for advanced monitoring.

## 🔄 Upgrades

### Update Configuration

1. Edit `values-custom.yaml`
2. Run: `./helm-deploy.sh deploy`

### Update Image

```yaml
litellm:
  image:
    tag: "new-version"
```

Then redeploy:

```bash
./helm-deploy.sh deploy
```

## 🗑️ Cleanup

```bash
./helm-deploy.sh cleanup
```

This will remove:
- Helm release
- Namespace and all resources
- Persistent volumes (if not using retain policy)

## 🐛 Troubleshooting

### Common Issues

1. **Pods not starting**: Check resource limits and node capacity
2. **Database connection failed**: Verify PostgreSQL is running
3. **Vertex AI authentication failed**: Check service account key encoding
4. **External IP not assigned**: Check LoadBalancer service and cloud provider quotas

### Debug Commands

```bash
# Check pod status
kubectl get pods -n litellm

# Describe pod for events
kubectl describe pod <pod-name> -n litellm

# Check logs
kubectl logs <pod-name> -n litellm

# Check service
kubectl get services -n litellm
```

## 📚 Additional Resources

- [LiteLLM Documentation](https://docs.litellm.ai/)
- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Support

For issues and questions:
1. Check the troubleshooting section
2. Review logs using `./helm-deploy.sh logs`
3. Check Kubernetes events: `kubectl get events -n litellm`
