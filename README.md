# Kubernetes Cloud-Agnostic POC

This POC demonstrates cloud-agnostic Kubernetes deployments using Helm charts and ArgoCD, deploying the same application to both AWS EKS and Azure AKS.

## Architecture

- **Single Helm Chart**: `helm-charts/app1/` contains the base application template
- **Environment-Specific Values**: Cloud-specific configurations in `environments/`
- **ArgoCD Applications**: Separate apps for each cloud using the same chart
- **GitOps**: ArgoCD manages deployments from this Git repository

## Structure

```
├── helm-charts/app1/           # Base Helm chart
├── environments/               # Cloud-specific values
│   ├── aws-eks/values.yaml    # AWS EKS configuration
│   └── azure-aks/values.yaml  # Azure AKS configuration
└── argocd-apps/               # ArgoCD application definitions
```

## Deployment

### Prerequisites
1. Install ArgoCD in both AWS EKS and Azure AKS clusters
2. Update repository URLs in `argocd-apps/*.yaml` files to match your Git repository

### Step-by-Step Deployment

1. **Check current cluster context**
   ```bash
   kubectl config current-context
   kubectl config get-contexts
   ```

2. **Push changes to Git**
   ```bash
   git add .
   git commit -m "Add Helm-based cloud-agnostic deployment"
   git push
   ```

3. **Deploy to AWS EKS cluster**
   ```bash
   kubectl config use-context your-eks-context
   kubectl apply -f argocd-apps/app-of-apps.yaml
   ```

4. **Deploy to Azure AKS cluster**
   ```bash
   kubectl config use-context your-aks-context
   kubectl apply -f argocd-apps/app-of-apps.yaml
   ```

5. **Verify deployments**
   ```bash
   # Check ArgoCD applications
   kubectl get applications -n argocd
   
   # Check deployed pods
   kubectl get pods -n app1-aws
   kubectl get pods -n app1-azure
   ```

6. **Access ArgoCD UI locally**
   ```bash
   # Port forward ArgoCD server to local machine
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   
   # Get ArgoCD admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   Open browser to https://localhost:8080
   ```
   
   Then:
   - Open browser to `https://localhost:8080`
   - Login with username: `admin` and the password from above command
   - Accept the self-signed certificate warning
   - Monitor your cloud-agnostic deployments across both clusters

## Cloud Differences Handled

- **Resource limits**: Different CPU/memory based on cloud pricing
- **Load balancer annotations**: Cloud-specific service configurations  
- **Node selectors**: Platform-specific scheduling
- **Replica counts**: Environment-appropriate scaling