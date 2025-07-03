# NGINX Ingress Controller

Cloud-agnostic NGINX Ingress Controller for routing traffic to multiple applications through a single entry point.

## Overview

This Helm chart deploys NGINX Ingress Controller with cloud-specific optimizations:
- **AWS**: Network Load Balancer with proxy protocol
- **Azure**: Azure Load Balancer with resource group configuration
- **Cost Effective**: Single LoadBalancer instead of multiple per application

## Architecture

```
Internet Traffic
       ↓
Cloud LoadBalancer (Single Entry Point)
       ↓
NGINX Controller Pods
       ↓
Routes based on hostname/path
       ↓
Internal Services (ClusterIP)
       ↓
Application Pods
```

## Deployment

### Prerequisites
- Kubernetes cluster (AWS EKS or Azure AKS)
- ArgoCD installed and configured

### ArgoCD Deployment
```bash
# Deploy to AWS
kubectl apply -f ../../argocd-apps/ingress-aws.yaml

# Deploy to Azure  
kubectl apply -f ../../argocd-apps/ingress-azure.yaml
```

### Manual Deployment
```bash
# AWS
helm install ingress-nginx . -f ../../environments/aws-eks/ingress/values.yaml -n ingress-nginx --create-namespace

# Azure
helm install ingress-nginx . -f ../../environments/azure-aks/ingress/values.yaml -n ingress-nginx --create-namespace
```

## Configuration

### AWS EKS Configuration
- **LoadBalancer**: Network Load Balancer (NLB)
- **Proxy Protocol**: Enabled for real client IPs
- **Cross-Zone**: Load balancing across availability zones
- **Resources**: 200m CPU, 256Mi memory

### Azure AKS Configuration  
- **LoadBalancer**: Azure Load Balancer
- **Resource Group**: Specified for proper billing
- **Resources**: 150m CPU, 200Mi memory (cost-optimized)
- **Node Pool**: Default agent pool selection

## Usage

### 1. Get External IP
```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

### 2. Create Ingress Routes
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: app.lebo.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: grafana.lebo.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
```

### 3. Test Routing
```bash
# Get external IP
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test with host header
curl -H "Host: app.lebo.com" http://$EXTERNAL_IP
curl -H "Host: grafana.lebo.com" http://$EXTERNAL_IP
```

### 4. DNS Configuration
Point your domains to the external IP:
```
app.lebo.com      → EXTERNAL_IP
grafana.lebo.com  → EXTERNAL_IP
argocd.lebo.com   → EXTERNAL_IP
```

## Verification

### Check Controller Status
```bash
# Check pods
kubectl get pods -n ingress-nginx

# Check service
kubectl get svc -n ingress-nginx

# Check ingress class
kubectl get ingressclass

# Check logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Test Connectivity
```bash
# Test NGINX is responding
curl http://EXTERNAL_IP
# Should return: 404 Not Found (NGINX default backend)

# Test with specific host
curl -H "Host: app.lebo.com" http://EXTERNAL_IP
```

## Benefits

- **Cost Savings**: Single LoadBalancer vs multiple ($90→$30 AWS, $75→$25 Azure)
- **Centralized Management**: All traffic through one entry point
- **SSL Termination**: Handle certificates in one place
- **Path/Host Routing**: Route based on domain or URL path
- **Cloud Optimized**: Different configurations per cloud provider

## Troubleshooting

### Common Issues

**1. External IP Pending**
```bash
# Check service events
kubectl describe svc ingress-nginx-controller -n ingress-nginx

# Check cloud provider quotas and permissions
```

**2. 404 Errors**
```bash
# Check ingress rules exist
kubectl get ingress -A

# Verify service names and ports match
kubectl get svc -A
```

**3. SSL/TLS Issues**
```bash
# Check certificate secrets
kubectl get secrets -n ingress-nginx

# Verify TLS configuration in ingress
kubectl describe ingress your-ingress
```

## Cloud-Specific Notes

### AWS
- Uses Network Load Balancer for better performance
- Proxy protocol preserves client IPs
- Cross-zone load balancing for high availability

### Azure
- Uses Azure Load Balancer with resource group
- Cost-optimized resource allocation
- Agent pool node selection for placement

## Next Steps

1. **SSL/TLS**: Add cert-manager for automatic certificate management
2. **Monitoring**: Integrate with Prometheus for ingress metrics
3. **Security**: Add rate limiting and WAF rules
4. **Scaling**: Configure horizontal pod autoscaling