#!/bin/bash

# LiteLLM Gateway Helm Deployment Script
# This script helps deploy LiteLLM Gateway using Helm

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
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

# Configuration
CHART_NAME="litellm-gateway"
RELEASE_NAME="litellm"
NAMESPACE="litellm"
VALUES_FILE="values-custom.yaml"

# Check if Helm is installed
check_helm() {
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install Helm first."
        echo "Visit: https://helm.sh/docs/intro/install/"
        exit 1
    fi
    print_success "Helm is installed: $(helm version --short)"
}

# Check if kubectl is installed and configured
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "kubectl is not configured or cluster is not accessible."
        exit 1
    fi
    
    print_success "kubectl is configured and cluster is accessible"
}

# Create values file from example if it doesn't exist
setup_values_file() {
    if [ ! -f "$VALUES_FILE" ]; then
        if [ -f "helm-chart/values-example.yaml" ]; then
            print_status "Creating $VALUES_FILE from example..."
            cp helm-chart/values-example.yaml "$VALUES_FILE"
            print_warning "Please edit $VALUES_FILE with your configuration before deploying!"
            print_warning "Required fields:"
            echo "  - vertexAI.projectId"
            echo "  - vertexAI.serviceAccountKey (base64 encoded)"
            echo "  - litellm.env.LITELLM_MASTER_KEY"
            echo "  - litellm.env.UI_PASSWORD"
            echo "  - postgresql.auth.password"
            echo ""
            read -p "Press Enter after editing $VALUES_FILE to continue..."
        else
            print_error "values-example.yaml not found. Please create $VALUES_FILE manually."
            exit 1
        fi
    else
        print_success "Using existing $VALUES_FILE"
    fi
}

# Encode service account key
encode_service_account() {
    if [ -f "VertexAiKey.json" ]; then
        print_status "Encoding VertexAiKey.json..."
        ENCODED_KEY=$(cat VertexAiKey.json | base64 -w 0)
        print_success "Service account key encoded. Add this to your $VALUES_FILE:"
        echo "vertexAI:"
        echo "  serviceAccountKey: \"$ENCODED_KEY\""
        echo ""
    else
        print_warning "VertexAiKey.json not found. Please ensure you have the service account key file."
    fi
}

# Deploy using Helm
deploy() {
    print_status "Deploying LiteLLM Gateway with Helm..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy with Helm
    helm upgrade --install "$RELEASE_NAME" ./helm-chart \
        --namespace "$NAMESPACE" \
        --values "$VALUES_FILE" \
        --wait \
        --timeout=10m
    
    print_success "Deployment completed!"
}

# Check deployment status
status() {
    print_status "Checking deployment status..."
    
    echo ""
    print_status "Helm release status:"
    helm status "$RELEASE_NAME" -n "$NAMESPACE"
    
    echo ""
    print_status "Pod status:"
    kubectl get pods -n "$NAMESPACE"
    
    echo ""
    print_status "Service status:"
    kubectl get services -n "$NAMESPACE"
    
    # Get external IP
    EXTERNAL_IP=$(kubectl get service "$RELEASE_NAME-litellm-gateway" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -n "$EXTERNAL_IP" ]; then
        print_success "LiteLLM Gateway is accessible at:"
        echo "  Gateway API: http://$EXTERNAL_IP/v1/chat/completions"
        echo "  Admin UI: http://$EXTERNAL_IP/ui"
        echo "  API Docs: http://$EXTERNAL_IP/docs"
        echo "  Health Check: http://$EXTERNAL_IP/health"
    else
        print_warning "External IP not yet assigned. Run 'kubectl get services -n $NAMESPACE' to check."
    fi
}

# Test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    EXTERNAL_IP=$(kubectl get service "$RELEASE_NAME-litellm-gateway" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
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

# Cleanup deployment
cleanup() {
    print_status "Cleaning up LiteLLM Gateway deployment..."
    
    helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" || true
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    
    print_success "Cleanup completed!"
}

# Get logs
logs() {
    print_status "Getting logs from LiteLLM Gateway..."
    kubectl logs -l app.kubernetes.io/name=litellm-gateway -n "$NAMESPACE" --tail=50 -f
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        check_helm
        check_kubectl
        setup_values_file
        encode_service_account
        deploy
        status
        ;;
    "status")
        status
        ;;
    "test")
        test_deployment
        ;;
    "logs")
        logs
        ;;
    "cleanup")
        cleanup
        ;;
    "encode-key")
        encode_service_account
        ;;
    *)
        echo "Usage: $0 [deploy|status|test|logs|cleanup|encode-key]"
        echo "  deploy     - Deploy LiteLLM Gateway (default)"
        echo "  status     - Show deployment status"
        echo "  test       - Test the deployment"
        echo "  logs       - Show logs from LiteLLM Gateway"
        echo "  cleanup    - Remove all LiteLLM resources"
        echo "  encode-key - Encode VertexAiKey.json for values file"
        exit 1
        ;;
esac
