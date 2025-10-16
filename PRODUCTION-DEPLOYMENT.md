# LiteLLM Gateway Production Deployment Guide

This guide covers deploying LiteLLM Gateway with production-ready features including guardrails, cost monitoring, and Kong Gateway integration.

## 🚀 Quick Start

### Prerequisites
- GKE cluster with Kong Gateway already deployed
- Vertex AI service account key (`VertexAiKey.json`)
- Helm 3.x installed
- kubectl configured for your cluster

### 1. Prepare Configuration

```bash
# Clone the repository
git clone https://github.com/awadhesh95pandey/AI-Gateway-GCP.git
cd AI-Gateway-GCP

# Copy production values template
cp helm-chart/values-production.yaml values-custom.yaml

# Encode your service account key
cat VertexAiKey.json | base64 -w 0
```

### 2. Configure values-custom.yaml

Edit `values-custom.yaml` and set the following required values:

```yaml
# Vertex AI configuration - REQUIRED
vertexAI:
  projectId: "your-gcp-project-id"  # Replace with your GCP project
  serviceAccountKey: "base64-encoded-key"  # From step 1

# Security credentials - REQUIRED
litellm:
  env:
    LITELLM_MASTER_KEY: "sk-your-secure-key"  # Generate a secure key
    UI_PASSWORD: "your-secure-password"       # Set a secure password

postgresql:
  auth:
    password: "your-secure-db-password"       # Set a secure password
```

### 3. Deploy

```bash
# Deploy with production configuration
helm upgrade --install litellm ./helm-chart \
  --values values-custom.yaml \
  --namespace litellm \
  --create-namespace \
  --wait \
  --timeout=15m
```

## 🛡️ Production Features

### Cost Monitoring & Guardrails
- **Budget Limits**: Monthly budget caps with alerts
- **Rate Limiting**: Per-model and global rate limits
- **Token Limits**: Maximum tokens per request/model
- **Cost Tracking**: Real-time cost monitoring with Prometheus metrics

### High Availability
- **Multiple Replicas**: 2+ replicas with anti-affinity rules
- **Health Checks**: Comprehensive liveness and readiness probes
- **Auto-scaling**: CPU/Memory based horizontal pod autoscaling
- **Pod Disruption Budget**: Ensures minimum availability during updates

### Security
- **Network Policies**: Restrict ingress/egress traffic
- **Security Contexts**: Non-root containers with minimal privileges
- **Secret Management**: Secure handling of credentials and keys

### Monitoring & Observability
- **Prometheus Metrics**: Cost, usage, and performance metrics
- **ServiceMonitor**: Automatic Prometheus scraping configuration
- **Alerting Rules**: Pre-configured alerts for cost, errors, and performance
- **Grafana Ready**: Metrics ready for Grafana dashboards

### Caching & Performance
- **Redis Caching**: Available but disabled by default (can be enabled later)
- **Connection Pooling**: Efficient database connections
- **Load Balancing**: Intelligent request routing

## 🔗 Kong Gateway Integration

The deployment is configured for Kong Gateway integration:

### Service Configuration
```yaml
litellm:
  service:
    type: ClusterIP  # For Kong integration
    port: 4000
```

### Kong Route Example
```bash
# Create Kong service
kubectl apply -f - <<EOF
apiVersion: configuration.konghq.com/v1
kind: KongIngress
metadata:
  name: litellm-kong-ingress
  namespace: litellm
upstream:
  algorithm: round-robin
  healthchecks:
    active:
      healthy:
        interval: 30
        successes: 1
      unhealthy:
        interval: 30
        tcp_failures: 3
        http_failures: 3
      http_path: /health
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: litellm-ingress
  namespace: litellm
  annotations:
    kubernetes.io/ingress.class: kong
    konghq.com/plugins: rate-limiting, prometheus
spec:
  rules:
  - host: ai-gateway.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: litellm-litellm-gateway
            port:
              number: 4000
EOF
```

## 📊 Monitoring & Alerts

### Available Metrics
- `litellm_total_cost_usd`: Total cost in USD
- `litellm_requests_total`: Total number of requests
- `litellm_errors_total`: Total number of errors
- `litellm_tokens_total`: Total tokens processed
- `litellm_requests_per_minute`: Current RPM
- `litellm_response_time_seconds`: Response time metrics

### Pre-configured Alerts
- **High Cost Usage**: Alert when monthly cost exceeds threshold
- **Rate Limit Exceeded**: Alert when approaching rate limits
- **High Error Rate**: Alert on elevated error rates
- **Pod Memory Usage**: Alert on high memory usage
- **Daily Cost Spike**: Alert on unusual daily cost increases

### Grafana Dashboard Queries
```promql
# Cost tracking
sum(litellm_total_cost_usd)

# Request rate
rate(litellm_requests_total[5m])

# Error rate
rate(litellm_errors_total[5m]) / rate(litellm_requests_total[5m]) * 100

# Token usage
rate(litellm_tokens_total[5m])
```

## 🔧 Configuration Options

### Model Configuration with Guardrails
```yaml
litellm:
  config:
    model_list:
      - model_name: gemini-pro
        litellm_params:
          model: vertex_ai/gemini-pro
          max_tokens: 4096
          temperature: 0.7
        model_info:
          rpm: 100        # Requests per minute limit
          tpm: 10000      # Tokens per minute limit
          max_budget: 500 # Budget limit for this model
```

### Global Guardrails
```yaml
litellm:
  config:
    general_settings:
      max_budget: 1000          # Monthly budget limit
      budget_duration: "30d"    # Budget period
      rpm_limit: 500           # Global RPM limit
      tpm_limit: 50000         # Global TPM limit
      max_tokens: 8192         # Global max tokens
      max_retries: 3           # Retry attempts
      request_timeout: 60      # Request timeout
```

### Redis Caching (Optional - Disabled by Default)
```yaml
# To enable Redis caching, set:
redis:
  enabled: true  # Change from false to true
  persistence:
    enabled: true
    size: "10Gi"

litellm:
  config:
    general_settings:
      cache: true  # Change from false to true
      cache_type: "redis"
```

**Note**: Redis is disabled by default to ensure smooth initial deployment. Enable it later for cost optimization.

## 🚨 Troubleshooting

### Check Deployment Status
```bash
# Check all pods
kubectl get pods -n litellm

# Check services
kubectl get services -n litellm

# Check ingress
kubectl get ingress -n litellm
```

### View Logs
```bash
# LiteLLM Gateway logs
kubectl logs -l app.kubernetes.io/name=litellm-gateway -n litellm -f

# PostgreSQL logs
kubectl logs -l app.kubernetes.io/name=litellm-gateway-postgresql -n litellm -f

# Redis logs
kubectl logs -l app.kubernetes.io/name=litellm-gateway-redis -n litellm -f
```

### Common Issues

#### CrashLoopBackOff
1. Check if service account key is properly base64 encoded
2. Verify GCP project ID is correct
3. Ensure database credentials are set
4. Check resource limits

#### High Costs
1. Review rate limits and budgets
2. Check for inefficient queries
3. Monitor token usage patterns
4. Verify caching is working

#### Performance Issues
1. Scale up replicas
2. Increase resource limits
3. Enable Redis caching
4. Check database performance

## 🔄 Updates and Maintenance

### Updating the Deployment
```bash
# Update configuration
helm upgrade litellm ./helm-chart \
  --values values-custom.yaml \
  --namespace litellm \
  --wait

# Check rollout status
kubectl rollout status deployment/litellm-litellm-gateway -n litellm
```

### Backup and Recovery
```bash
# Backup PostgreSQL data
kubectl exec -n litellm deployment/litellm-postgresql -- pg_dump -U litellm litellm > backup.sql

# Restore from backup
kubectl exec -i -n litellm deployment/litellm-postgresql -- psql -U litellm litellm < backup.sql
```

## 📈 Scaling

### Horizontal Scaling
```yaml
litellm:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

### Vertical Scaling
```yaml
litellm:
  resources:
    limits:
      memory: "8Gi"
      cpu: "4000m"
    requests:
      memory: "4Gi"
      cpu: "2000m"
```

## 🔐 Security Best Practices

1. **Use strong passwords** for all credentials
2. **Rotate service account keys** regularly
3. **Enable network policies** to restrict traffic
4. **Monitor access logs** for suspicious activity
5. **Keep images updated** with latest security patches
6. **Use RBAC** to limit Kubernetes permissions

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review logs for error messages
3. Verify configuration against this guide
4. Check Kubernetes events: `kubectl get events -n litellm`

## 🎯 Architecture Flow

```
Client → Kong Gateway → LiteLLM Gateway → Vertex AI
                    ↓
                Redis Cache
                    ↓
              PostgreSQL DB
                    ↓
            Prometheus Metrics
```

This production deployment provides a robust, scalable, and cost-effective AI Gateway solution with comprehensive monitoring and guardrails.
