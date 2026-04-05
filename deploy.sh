#!/bin/bash
# ArgoCD Portfolio Deployment Script

set -e

REGISTRY="${1:-localhost:5000}"
REPO_URL="${2:-}"

echo "🚀 Portfolio Container - ArgoCD Deployment Setup"
echo "================================================"
echo ""

if [ -z "$REPO_URL" ]; then
    echo "Usage: ./deploy.sh <registry> [git-repo-url]"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh docker.io/myuser"
    echo "  ./deploy.sh gcr.io/my-project ghttps://github.com/myorg/portfolio"
    echo ""
    exit 1
fi

echo "📦 Building Docker image..."
docker build -t "${REGISTRY}/portfolio:latest" .

echo "📤 Pushing to registry: ${REGISTRY}"
docker push "${REGISTRY}/portfolio:latest"

echo "🔧 Configuring Kubernetes manifests..."
sed -i.bak "s|portfolio-web:latest|${REGISTRY}/portfolio:latest|g" k8s/deployment.yaml

echo "🔧 Configuring ArgoCD application..."
sed -i.bak "s|<YOUR_GIT_REPO_URL>|${REPO_URL}|g" .argocd/application.yaml

echo "📋 Applying Kubernetes namespace and ArgoCD Application..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f .argocd/application.yaml

echo ""
echo "✅ Deployment configuration complete!"
echo ""
echo "📊 Check deployment status with:"
echo "   kubectl get all -n portfolio"
echo "   argocd app get portfolio"
echo ""
echo "🔄 To sync manually:"
echo "   argocd app sync portfolio"
echo ""
