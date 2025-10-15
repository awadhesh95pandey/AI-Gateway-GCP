#!/bin/bash

# ============================================
# LiteLLM Gateway GKE Deployment Script
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install gcloud first."
        exit 1
    fi
    
    # Check if VertexAiKey.json exists
    if [ ! -f "VertexAiKey.json" ]; then
        print_error "VertexAiKey.json file not found in current directory."
        exit 1
    fi
    
    # Check kubectl connection to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubectl configuration."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Create Vertex AI secret from JSON file
create_vertex_secret() {
    print_status "Creating Vertex AI credentials secret..."
    
    # Delete existing secret if it exists
    kubectl delete secret vertex-ai-credentials -n litellm --ignore-not-found=true
    
    # Create secret from file
    kubectl create secret generic vertex-ai-credentials \
        --from-file=vertex-key.json=VertexAiKey.json \
        -n litellm
    
    print_success "Vertex AI credentials secret created!"
}

# Deploy all components
deploy_components() {
    print_status "Starting LiteLLM Gateway deployment..."
    
    # 1. Create namespace
    print_status "Creating namespace..."
    kubectl apply -f namespace.yaml
    
    # 2. Create Vertex AI secret
    create_vertex_secret
    
    # 3. Deploy PostgreSQL
    print_status "Deploying PostgreSQL database..."
    kubectl apply -f postgre.yaml
    
    # Wait for PostgreSQL to be ready
    print_status "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n litellm --timeout=300s
    
    # 4. Create LiteLLM ConfigMap
    print_status "Creating LiteLLM configuration..."
    kubectl apply -f litellm-config.yaml
    
    # 5. Deploy LiteLLM
    print_status "Deploying LiteLLM Gateway..."
    kubectl apply -f litellm-deployment.yaml
    
    # 6. Create LiteLLM Service
    print_status "Creating LiteLLM service..."
    kubectl apply -f service.yaml
    
    print_success "All components deployed!"
}

# Wait for deployment to be ready
wait_for_deployment() {
    print_status "Waiting for LiteLLM deployment to be ready..."
    kubectl wait --for=condition=available deployment/litellm-proxy -n litellm --timeout=600s
    
    print_status "Waiting for service to get external IP..."
    # Wait up to 5 minutes for LoadBalancer to get external IP
    for i in {1..30}; do
        EXTERNAL_IP=$(kubectl get service litellm-service -n litellm -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ ! -z "$EXTERNAL_IP" ]; then
            break
        fi
        echo "Waiting for external IP... (attempt $i/30)"
        sleep 10
    done
    
    print_success "LiteLLM Gateway is ready!"
}

# Display deployment information
show_deployment_info() {
    print_status "Deployment Information:"
    echo "=========================="
    
    # Get service information
    EXTERNAL_IP=$(kubectl get service litellm-service -n litellm -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
    EXTERNAL_PORT=$(kubectl get service litellm-service -n litellm -o jsonpath='{.spec.ports[0].port}')
    
    echo "🌐 LiteLLM Gateway URL: http://$EXTERNAL_IP:$EXTERNAL_PORT"
    echo "📊 Admin UI: http://$EXTERNAL_IP:$EXTERNAL_PORT/ui"
    echo "📖 API Docs: http://$EXTERNAL_IP:$EXTERNAL_PORT/docs"
    echo "🔑 Master Key: sk-1234"
    echo "👤 UI Username: admin"
    echo "🔒 UI Password: admin123"
    echo ""
    
    # Show pod status
    echo "Pod Status:"
    kubectl get pods -n litellm
    echo ""
    
    # Show service status
    echo "Service Status:"
    kubectl get services -n litellm
    echo ""
    
    print_warning "Note: If External IP shows 'Pending', wait a few more minutes for GCP to assign the IP."
    print_warning "Make sure your GKE cluster has sufficient resources and LoadBalancer quota."
}

# Test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    EXTERNAL_IP=$(kubectl get service litellm-service -n litellm -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$EXTERNAL_IP" ]; then
        print_warning "External IP not yet assigned. Skipping connectivity test."
        return
    fi
    
    # Test health endpoint
    if curl -s -f "http://$EXTERNAL_IP/health" > /dev/null; then
        print_success "Health check passed!"
    else
        print_warning "Health check failed. The service might still be starting up."
    fi
}

# Cleanup function
cleanup() {
    print_status "Cleaning up LiteLLM deployment..."
    kubectl delete namespace litellm --ignore-not-found=true
    print_success "Cleanup completed!"
}

# Main execution
main() {
    echo "============================================"
    echo "🚀 LiteLLM Gateway GKE Deployment Script"
    echo "============================================"
    echo ""
    
    case "${1:-deploy}" in
        "deploy")
            check_prerequisites
            deploy_components
            wait_for_deployment
            show_deployment_info
            test_deployment
            ;;
        "cleanup")
            cleanup
            ;;
        "status")
            show_deployment_info
            ;;
        "test")
            test_deployment
            ;;
        *)
            echo "Usage: $0 [deploy|cleanup|status|test]"
            echo "  deploy  - Deploy LiteLLM Gateway (default)"
            echo "  cleanup - Remove all LiteLLM resources"
            echo "  status  - Show deployment status"
            echo "  test    - Test the deployment"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
