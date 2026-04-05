#!/bin/bash
# Complete NGINX Ingress + MetalLB + Portfolio Deployment Script

set -e

echo "🚀 Portfolio Kubernetes Deployment Setup"
echo "========================================="
echo ""

# Check prerequisites
check_prerequisites() {
    echo "📋 Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl not found. Install it first."
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        echo "❌ helm not found. Install it first."
        exit 1
    fi
    
    echo "✅ Prerequisites met: kubectl, helm"
}

# Configure MetalLB
setup_metallb() {
    echo ""
    echo "🔧 Setting up MetalLB..."
    
    read -p "Enter MetalLB IP pool range (e.g., 192.168.1.240-192.168.1.250): " IP_RANGE
    
    if kubectl get namespace metallb-system &> /dev/null; then
        echo "✅ MetalLB system namespace exists"
    else
        echo "📦 Installing MetalLB..."
        kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml
        echo "⏳ Waiting for MetalLB controller..."
        kubectl wait --for=condition=ready pod -l app=metallb,component=controller -n metallb-system --timeout=300s
    fi
    
    # Update and apply MetalLB config
    sed -i.bak "s|192.168.1.240-192.168.1.250|${IP_RANGE}|g" k8s/metallb-config.yaml
    kubectl apply -f k8s/metallb-config.yaml
    echo "✅ MetalLB configured with IP pool: $IP_RANGE"
}

# Setup NGINX Ingress
setup_nginx_ingress() {
    echo ""
    echo "🔧 Setting up NGINX Ingress Controller..."
    
    if kubectl get namespace ingress-nginx &> /dev/null; then
        echo "✅ NGINX namespace exists"
        if kubectl get deployment -n ingress-nginx nginx-ingress-ingress-nginx-controller &> /dev/null; then
            echo "✅ NGINX Ingress already installed"
            return
        fi
    fi
    
    echo "📦 Installing NGINX Ingress Controller via Helm..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
    helm repo update
    
    helm install nginx-ingress ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.type=LoadBalancer \
        --wait
    
    echo "✅ NGINX Ingress installed"
}

# Get external IP and configure hosts
setup_hosts() {
    echo ""
    echo "🔧 Configuring host access..."
    
    echo "⏳ Waiting for LoadBalancer external IP..."
    EXTERNAL_IP=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
    
    RETRY=0
    while [ "$EXTERNAL_IP" == "pending" ] && [ $RETRY -lt 30 ]; do
        sleep 2
        EXTERNAL_IP=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
        RETRY=$((RETRY + 1))
    done
    
    if [ "$EXTERNAL_IP" == "pending" ]; then
        echo "⚠️  LoadBalancer IP still pending. Check MetalLB configuration."
        echo "Run: kubectl get svc -n ingress-nginx"
    else
        echo "✅ LoadBalancer external IP: $EXTERNAL_IP"
        
        read -p "Add portfolio.local to /etc/hosts? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Remove old entry if exists
            sudo sed -i.bak "/portfolio.local/d" /etc/hosts
            echo "$EXTERNAL_IP portfolio.local" | sudo tee -a /etc/hosts > /dev/null
            echo "✅ Updated /etc/hosts"
        fi
    fi
}

# Deploy portfolio
deploy_portfolio() {
    echo ""
    echo "🚀 Deploying portfolio application..."
    
    read -p "Use ArgoCD for deployment? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if kubectl get crd applications.argoproj.io &> /dev/null; then
            echo "✅ ArgoCD CRD found"
            read -p "Enter git repository URL: " REPO_URL
            sed -i.bak "s|<YOUR_GIT_REPO_URL>|${REPO_URL}|g" .argocd/application.yaml
            kubectl apply -f .argocd/application.yaml
            echo "✅ ArgoCD Application created"
        else
            echo "⚠️  ArgoCD not found. Using kubectl instead..."
            kubectl apply -k k8s/
        fi
    else
        echo "📦 Using kubectl to deploy..."
        kubectl apply -k k8s/
    fi
    
    echo "⏳ Waiting for portfolio deployment..."
    kubectl wait --for=condition=available --timeout=300s \
        deployment/portfolio-web -n portfolio 2>/dev/null || true
    
    echo "✅ Portfolio deployment complete"
}

# Verify deployment
verify_deployment() {
    echo ""
    echo "✅ Verification"
    echo "==============="
    echo ""
    echo "MetalLB:"
    kubectl get pods -n metallb-system
    echo ""
    echo "NGINX Ingress:"
    kubectl get pods -n ingress-nginx
    kubectl get svc -n ingress-nginx | grep LoadBalancer
    echo ""
    echo "Portfolio Application:"
    kubectl get pods -n portfolio
    kubectl get svc -n portfolio
    kubectl get ingress -n portfolio
    echo ""
    echo "To access: http://portfolio.local"
}

# Main execution
main() {
    check_prerequisites
    setup_metallb
    setup_nginx_ingress
    setup_hosts
    deploy_portfolio
    verify_deployment
    
    echo ""
    echo "🎉 Setup complete!"
}

main
