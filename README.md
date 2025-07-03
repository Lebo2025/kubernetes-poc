# Kubernetes Cloud-Agnostic POC

This POC demonstrates cloud-agnostic Kubernetes deployments using Helm charts and ArgoCD, deploying the same application to both AWS EKS and Azure AKS.

## Overview

This project showcases how Kubernetes enables true multi-cloud deployments by:
- Using a single Helm chart that deploys to multiple cloud providers
- Leveraging cloud-specific configurations through values files
- Implementing GitOps practices with ArgoCD for automated deployments
- Maintaining consistency while optimizing for each cloud platform

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
1. AWS EKS and Azure AKS clusters created and configured
2. kubectl configured with contexts for both clusters
3. ArgoCD installed on both clusters
4. Git repository with your manifests pushed

### Step-by-Step Deployment

1. **Check current cluster contexts**
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

3. **Install ArgoCD on both clusters**
   ```bash
   # Switch to AWS EKS cluster
   kubectl config use-context your-eks-context
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   
   # Switch to Azure AKS cluster
   kubectl config use-context your-aks-context
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   
   # Wait for ArgoCD to be ready on both clusters
   kubectl get pods -n argocd -w
   ```

4. **Update repository URLs**
   ```bash
   # Replace YOUR_USERNAME with your GitHub username in all ArgoCD app files
   sed -i 's/YOUR_USERNAME/your-github-username/g' argocd-apps/*.yaml
   ```

5. **Deploy applications to ArgoCD**
   ```bash
   # Deploy to AWS EKS cluster
   kubectl config use-context your-eks-context
   kubectl apply -f argocd-apps/app-of-apps.yaml
   
   # Deploy to Azure AKS cluster
   kubectl config use-context your-aks-context
   kubectl apply -f argocd-apps/app-of-apps.yaml
   ```

6. **Verify deployments**
   ```bash
   # Check ArgoCD applications
   kubectl get applications -n argocd
   
   # Check deployed pods
   kubectl get pods -n app1-aws
   kubectl get pods -n app1-azure
   ```

7. **Access ArgoCD UI locally**
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

### AWS EKS Configuration
- **Replicas**: 3 instances for higher availability
- **Resources**: 500m CPU / 512Mi memory limits
- **Load Balancer**: Network Load Balancer (NLB) with AWS-specific annotations
- **Region**: eu-west-1

### Azure AKS Configuration  
- **Replicas**: 2 instances for cost optimization
- **Resources**: 400m CPU / 512Mi memory limits
- **Load Balancer**: Azure Load Balancer with resource group annotations
- **Region**: eastus

## Key Benefits

- **Portability**: Same application runs on multiple clouds without code changes
- **Consistency**: Identical deployment process across all environments
- **Optimization**: Cloud-specific configurations for performance and cost
- **Automation**: GitOps ensures deployments stay synchronized
- **Scalability**: Easy to add new cloud providers or environments

## Technologies Used

- **Kubernetes**: Container orchestration platform
- **Helm**: Package manager for Kubernetes applications
- **ArgoCD**: GitOps continuous delivery tool
- **Terraform**: Infrastructure as Code for cluster provisioning
- **AWS EKS**: Managed Kubernetes service on AWS
- **Azure AKS**: Managed Kubernetes service on Azure