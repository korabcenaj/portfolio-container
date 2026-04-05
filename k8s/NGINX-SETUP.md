---
# NGINX Ingress Controller Installation
# This file documents how to install NGINX Ingress Controller with MetalLB

# 1. Install NGINX Ingress Controller using Helm:
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update
# helm install nginx-ingress ingress-nginx/ingress-nginx \
#   --namespace ingress-nginx \
#   --create-namespace \
#   --set controller.service.type=LoadBalancer

# 2. Verify NGINX Ingress is running:
# kubectl get svc -n ingress-nginx
# kubectl get pods -n ingress-nginx

# 3. Get the LoadBalancer IP assigned by MetalLB:
# kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller
# You should see an EXTERNAL-IP from the MetalLB pool

# 4. Configure DNS or /etc/hosts to point to the EXTERNAL-IP:
# echo "192.168.1.245 portfolio.local" >> /etc/hosts

# 5. Deploy the application:
# kubectl apply -f .argocd/application.yaml

# 6. Access the portfolio:
# http://portfolio.local

apiVersion: v1
kind: Namespace
metadata:
  name: ingress-nginx
