# ArgoCD Configuration

This directory contains the ArgoCD Application manifest for deploying this portfolio to a Kubernetes cluster with **NGINX Ingress Controller** and **MetalLB** load balancing.

## Prerequisites

- Kubernetes cluster (v1.19+)
- ArgoCD installed and configured
- NGINX Ingress Controller installed with LoadBalancer service
- MetalLB installed and configured with IP address pool
- Container registry (Docker Hub, ECR, GCR, etc.)

For NGINX Ingress + MetalLB setup, see [../k8s/METALLB-NGINX-SETUP.md](../k8s/METALLB-NGINX-SETUP.md).

## Quick Setup with Automated Script

For a complete automated setup:

```bash
cd k8s
chmod +x deploy-with-nginx-metallb.sh
./deploy-with-nginx-metallb.sh
```

This script will:
1. Verify prerequisites
2. Install and configure MetalLB
3. Install NGINX Ingress Controller
4. Get the external IP and update /etc/hosts
5. Deploy the portfolio application
6. Verify all components

## Manual Setup Instructions

### 1. Build and Push Image

Build and push the image to your container registry:

```bash
REGISTRY=your-registry
docker build -t $REGISTRY/portfolio:latest .
docker push $REGISTRY/portfolio:latest
```

Update the image in `k8s/deployment.yaml`:
```bash
sed -i "s|portfolio-web:latest|$REGISTRY/portfolio:latest|g" k8s/deployment.yaml
```

### 2. Configure ArgoCD Application

Update `application.yaml` with your repository URL:

```bash
sed -i 's|<YOUR_GIT_REPO_URL>|https://github.com/yourorg/portfolio-container|g' application.yaml
```

### 3. Create the Application in ArgoCD

```bash
kubectl apply -f application.yaml
```

Or using `argocd` CLI:

```bash
argocd app create portfolio \
  --repo https://github.com/yourorg/portfolio-container \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace portfolio \
  --auto-prune \
  --self-heal \
  --sync-policy automated
```

### 4. Monitor Sync Status

```bash
argocd app get portfolio
argocd app sync portfolio  # Manual sync if needed
```

## Accessing the Portfolio

Once deployed, the portfolio is available at:

```
http://portfolio.local
```

To verify:
```bash
curl http://portfolio.local
```

## Troubleshooting

### No LoadBalancer IP

If the NGINX service shows `<pending>`:

```bash
kubectl logs -n metallb-system -l app=metallb,component=controller
kubectl get ipaddresspools -n metallb-system
```

### Cannot Resolve portfolio.local

Verify /etc/hosts:
```bash
grep portfolio.local /etc/hosts
```

Get the correct NGINX external IP:
```bash
kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller
```

### Application Not Syncing

Check ArgoCD Application status:
```bash
argocd app get portfolio
kubectl describe app portfolio -n argocd
```

## Production Considerations

- Scale replicas: Update `k8s/deployment.yaml` to `replicas: 3`
- Enable HTTPS: Uncomment cert-manager config in `k8s/ingress.yaml`
- Add Pod Disruption Budget for high availability
- Configure network policies for security
- Set up proper resource requests/limits (already configured)
- Use private container registry with image pull secrets
