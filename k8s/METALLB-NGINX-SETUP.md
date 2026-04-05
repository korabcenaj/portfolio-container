# NGINX Ingress + MetalLB Deployment Guide

## Overview

This configuration deploys the portfolio website to a Kubernetes cluster using:
- **NGINX Ingress Controller** - HTTP/HTTPS routing
- **MetalLB** - LoadBalancer IP assignment on bare metal clusters

## Prerequisites

- Kubernetes cluster (1.19+)
- MetalLB installed and configured
- NGINX Ingress Controller installed
- kubectl configured for your cluster
- ArgoCD (optional, for GitOps deployment)

## Quick Start

### 1. Install MetalLB (if not already installed)

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml
kubectl wait --for=condition=ready pod -l app=metallb,component=controller -n metallb-system --timeout=300s
```

### 2. Configure MetalLB IP Pool

Edit `k8s/metallb-config.yaml` with your network's available IP range:

```bash
# Update the IP range for your network
sed -i 's|192.168.1.240-192.168.1.250|YOUR_IP_RANGE|g' k8s/metallb-config.yaml

# Apply the configuration
kubectl apply -f k8s/metallb-config.yaml
```

### 3. Install NGINX Ingress Controller

```bash
# Add the Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress with LoadBalancer service
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

### 4. Verify NGINX LoadBalancer IP

```bash
kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller

# Output should show:
# NAME                                           TYPE           CLUSTER-IP   EXTERNAL-IP    PORT(S)
# nginx-ingress-ingress-nginx-controller         LoadBalancer   10.x.x.x     192.168.x.xx   80:XXXXX/TCP,443:XXXXX/TCP
```

Save the `EXTERNAL-IP` - this is your ingress endpoint.

### 5. Configure DNS or Hosts File

Point `portfolio.local` to the MetalLB external IP:

```bash
# On Linux/Mac:
echo "192.168.1.245 portfolio.local" >> /etc/hosts

# Or configure DNS in your network for proper DNS resolution
```

### 6. Deploy the Portfolio Application

Using ArgoCD (recommended):
```bash
kubectl apply -f .argocd/application.yaml
```

Or manually:
```bash
kubectl apply -k k8s/
```

### 7. Access the Portfolio

```bash
# HTTP
curl http://portfolio.local

# Or open in browser
open http://portfolio.local
```

## Verification Checklist

- [ ] MetalLB controller running: `kubectl get pods -n metallb-system`
- [ ] NGINX controller running: `kubectl get pods -n ingress-nginx`
- [ ] LoadBalancer service has external IP: `kubectl get svc -n ingress-nginx`
- [ ] Portfolio namespace exists: `kubectl get ns portfolio`
- [ ] Portfolio deployment running: `kubectl get pods -n portfolio`
- [ ] Ingress resource created: `kubectl get ingress -n portfolio`
- [ ] Can access via `portfolio.local`

## Troubleshooting

### No External IP Assigned

If the NGINX LoadBalancer service shows `<pending>`, MetalLB may not be ready:

```bash
# Check MetalLB controller
kubectl logs -n metallb-system -l app=metallb,component=controller

# Verify IP pool is configured
kubectl get ipaddresspools -n metallb-system
kubectl get l2advertisements -n metallb-system
```

### Cannot Resolve portfolio.local

- Verify `/etc/hosts` entry: `cat /etc/hosts | grep portfolio`
- Test DNS: `nslookup portfolio.local`
- Verify MetalLB external IP is correct

### Ingress Not Routing Traffic

Check ingress status:
```bash
kubectl describe ingress portfolio-web -n portfolio
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

## Scaling & High Availability

For production, consider:

1. **Multiple Replicas** - Update `k8s/deployment.yaml`:
   ```yaml
   replicas: 3
   ```

2. **Pod Disruption Budget** - Add to deployment:
   ```yaml
   podDisruptionBudget:
     minAvailable: 1
   ```

3. **HTTPS/TLS** - Uncomment in `k8s/ingress.yaml` and configure cert-manager

4. **Resource Limits** - Already configured in `k8s/deployment.yaml`

## Network Policies

For security, consider adding network policies:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: portfolio-allow-ingress
  namespace: portfolio
spec:
  podSelector:
    matchLabels:
      app: portfolio
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
```

## Deployment Architecture

```
Internet
   ↓
MetalLB External IP (192.168.1.245)
   ↓
NGINX Ingress Controller (LoadBalancer Service)
   ↓
Ingress Resource (portfolio.local → portfolio-web:80)
   ↓
portfolio-web Service (ClusterIP)
   ↓
portfolio-web Pods (NGINX serving portfolio.html)
```
