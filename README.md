# Portfolio Container Deployment

This directory contains a static site container for `portfolio.html` configured for both local Docker Compose and Kubernetes/ArgoCD deployment.

## Quick Start - Local Docker Compose

1. Copy `portfolio.html` to this folder (already done).
2. Get Cloudflare tunnel credentials:
   - Install `cloudflared` locally or in container.
   - Run: `cloudflared tunnel login`
   - Run: `cloudflared tunnel create <NAME>`
   - Add DNS route: `cloudflared tunnel route dns <NAME> <YOUR_DOMAIN>`
   - Copy the generated `credentials.json` into `.cloudflared/`.
   - Set `tunnel` ID in `.cloudflared/config.yml` and your hostname.
3. Start stack:
   - `docker compose up --build`.
4. Verify locally at: `http://localhost:8080`

## ArgoCD Deployment - Kubernetes GitOps

This repository is configured for automatic deployment via **ArgoCD**. All Kubernetes manifests are in the `k8s/` directory.

### Prerequisites

- Kubernetes cluster (v1.19+)
- ArgoCD installed in your cluster
- Container registry (Docker Hub, ECR, GCR, etc.)

### Setup Steps

1. **Build and push the image to your registry:**
   ```bash
   REGISTRY=your-registry
   docker build -t $REGISTRY/portfolio:latest .
   docker push $REGISTRY/portfolio:latest
   ```

2. **Update the image reference in Kubernetes manifest:**
   ```bash
   sed -i "s|portfolio-web:latest|$REGISTRY/portfolio:latest|g" k8s/deployment.yaml
   ```

3. **Configure the ArgoCD Application:**
   ```bash
   cd .argocd
   sed -i 's|<YOUR_GIT_REPO_URL>|https://github.com/yourorg/portfolio-container|g' application.yaml
   ```

4. **Create the Application in ArgoCD:**
   ```bash
   kubectl apply -f .argocd/application.yaml
   ```

5. **Verify deployment:**
   ```bash
   argocd app get portfolio
   kubectl get all -n portfolio
   ```

### Configuration

All Kubernetes resources are managed via Kustomize:
- `k8s/namespace.yaml` - Portfolio namespace
- `k8s/deployment.yaml` - NGINX deployment with health checks
- `k8s/service.yaml` - ClusterIP service
- `k8s/ingress.yaml` - Ingress configuration (requires ingress controller)
- `k8s/kustomization.yaml` - Kustomize overlay

### Customization

This deployment is configured for **NGINX Ingress Controller** with **MetalLB** load balancing:

- **Ingress Controller**: NGINX (ingressClassName: `nginx`)
- **Load Balancer**: MetalLB for external IP assignment
- **Ingress Hostname**: `portfolio.local` (update in `k8s/ingress.yaml`)
- **TLS/HTTPS**: Uncomment cert-manager annotations to enable
- **Resource Limits**: Already configured in `k8s/deployment.yaml`

### NGINX Ingress + MetalLB Setup

For detailed setup instructions specific to your cluster, see [k8s/METALLB-NGINX-SETUP.md](k8s/METALLB-NGINX-SETUP.md).

**Quick setup:**
```bash
# 1. Configure MetalLB IP pool
sed -i 's|192.168.1.240-192.168.1.250|YOUR_IP_RANGE|g' k8s/metallb-config.yaml
kubectl apply -f k8s/metallb-config.yaml

# 2. Install NGINX Ingress (if not already installed)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer

# 3. Deploy portfolio
kubectl apply -f .argocd/application.yaml

# 4. Get the external IP and add to /etc/hosts
EXTERNAL_IP=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "$EXTERNAL_IP portfolio.local" >> /etc/hosts

# 5. Access
curl http://portfolio.local
```

See [k8s/METALLB-NGINX-SETUP.md](k8s/METALLB-NGINX-SETUP.md) for detailed setup instructions and troubleshooting.

For ArgoCD configuration, see [.argocd/README.md](.argocd/README.md).

## Environment

- NGINX static server on `web` service
- Cloudflared tunnel on `cloudflared` service (Docker Compose only)

## Notes

- For Docker Compose: `CLOUDFLARED_TOKEN` environment variable must be set
- For Kubernetes: Image must be available in your registry
- ArgoCD will auto-sync changes to this repository to your cluster
