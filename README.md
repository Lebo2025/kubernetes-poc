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
├── helm-charts/
│   ├── app1/                  # Base application Helm chart
│   └── monitoring/            # Prometheus & Grafana Helm chart
├── environments/              # Cloud-specific values
│   ├── aws-eks/
│   │   ├── values.yaml        # AWS EKS app configuration
│   │   └── monitoring/values.yaml # AWS monitoring configuration
│   └── azure-aks/
│       ├── values.yaml        # Azure AKS app configuration
│       └── monitoring/values.yaml # Azure monitoring configuration
└── argocd-apps/               # ArgoCD application definitions
    ├── app-of-apps.yaml       # Parent application
    ├── app1-aws.yaml          # AWS application
    ├── app1-azure.yaml        # Azure application
    ├── monitoring-aws.yaml    # AWS monitoring stack
    └── monitoring-azure.yaml  # Azure monitoring stack
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
   # View all available contexts
   kubectl config get-contexts
   
   # Install on AWS EKS cluster
   kubectl config use-context your-eks-context
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   kubectl get pods -n argocd -w  # Wait for all pods to be Running
   
   # Install on Azure AKS cluster
   kubectl config use-context your-aks-context
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   kubectl get pods -n argocd -w  # Wait for all pods to be Running
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

   **Troubleshooting:**
   ```bash
   # If you need to delete ArgoCD from a specific cluster
   kubectl config use-context your-target-context
   kubectl delete namespace argocd
   
   # If applications fail to sync, check repository access
   kubectl describe application app-of-apps -n argocd
   ```

6. **Verify deployments**
   ```bash
   # Check ArgoCD applications
   kubectl get applications -n argocd
   
   # Check deployed pods
   kubectl get pods -n app1-aws
   kubectl get pods -n app1-azure
   kubectl get pods -n monitoring
   
   # Check services and external IPs
   kubectl get svc -n app1-aws
   kubectl get svc -n app1-azure
   kubectl get svc -n monitoring
   ```

7. **Access ArgoCD UI locally**
   ```bash
   # For AWS EKS cluster
   kubectl config use-context your-eks-context
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   
   # Get ArgoCD admin password (in another terminal)
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```
   
   ```bash
   # For Azure AKS cluster (use different port)
   kubectl config use-context your-aks-context
   kubectl port-forward svc/argocd-server -n argocd 8081:443
   
   # Get ArgoCD admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```
   
   **Access:**
   - AWS ArgoCD: `https://localhost:8080` 
   - Azure ArgoCD: `https://localhost:8081`
   - Login: username `admin` + password from above commands
   - Accept self-signed certificate warnings
   - Monitor your cloud-agnostic deployments across both clusters

8. **Access Grafana Monitoring**
   ```bash
   # Get Grafana LoadBalancer external IP for AWS
   kubectl config use-context your-eks-context
   kubectl get svc grafana -n monitoring
   
   # Get Grafana LoadBalancer external IP for Azure
   kubectl config use-context your-aks-context
   kubectl get svc grafana -n monitoring
   
   # Or access via port-forward if LoadBalancer is pending
   kubectl port-forward svc/grafana -n monitoring 3000:3000
   ```
   
   **Grafana Access:**
   - URL: `http://<EXTERNAL-IP>:3000` or `http://localhost:3000`
   - Username: `admin`
   - Password: `admin123`
   - Monitor metrics from both AWS and Azure deployments
   - Prometheus data source: `http://prometheus:9090`

## Cloud Differences Handled

### AWS EKS Configuration
**Application:**
- **Replicas**: 3 instances for higher availability
- **Resources**: 500m CPU / 512Mi memory limits
- **Load Balancer**: Network Load Balancer (NLB) with AWS-specific annotations
- **Region**: eu-west-1

**Monitoring:**
- **Prometheus**: 500m CPU / 1Gi memory limits
- **Grafana**: 200m CPU / 256Mi memory limits
- **Load Balancer**: NLB for Grafana access

### Azure AKS Configuration  
**Application:**
- **Replicas**: 2 instances for cost optimization
- **Resources**: 400m CPU / 512Mi memory limits
- **Load Balancer**: Azure Load Balancer with resource group annotations
- **Region**: eastus

**Monitoring:**
- **Prometheus**: 400m CPU / 512Mi memory limits (cost optimized)
- **Grafana**: 150m CPU / 200Mi memory limits (cost optimized)
- **Load Balancer**: Azure Load Balancer for Grafana access

## Key Benefits

- **Portability**: Same applications and monitoring run on multiple clouds without code changes
- **Consistency**: Identical deployment process across all environments
- **Optimization**: Cloud-specific configurations for performance and cost
- **Automation**: GitOps ensures deployments stay synchronized
- **Observability**: Unified monitoring across all cloud environments
- **Scalability**: Easy to add new cloud providers or environments

## Scaling with Backstage IDP

For organizations needing to create multiple clusters, this POC includes Backstage templates for self-service cluster provisioning:

### Backstage Template Features
- **Self-Service**: Developers can create clusters via UI forms
- **Multi-Cloud**: Support for AWS, Azure, and GCP
- **Standardized**: Consistent configurations across all clusters
- **GitOps Ready**: Auto-generates ArgoCD applications
- **Monitoring Included**: Optional Prometheus/Grafana deployment

### Using the Template
1. **Install Backstage** in your organization
2. **Register the template**: `backstage/templates/cluster-template.yaml`
3. **Create clusters** via Backstage UI with custom parameters:
   - Cloud provider (AWS/Azure/GCP)
   - Region and instance types
   - Node count and application replicas
   - Enable/disable monitoring and ArgoCD

### Template Structure
```
backstage/
├── templates/
│   ├── cluster-template.yaml    # Backstage template definition
│   └── skeleton/                # Template files
│       ├── terraform/           # Infrastructure as Code
│       ├── environments/        # Cloud-specific values
│       └── argocd-apps/         # GitOps applications
└── catalog/
    └── platform-system.yaml    # Platform catalog entities
```

## Technologies Used

- **Kubernetes**: Container orchestration platform
- **Helm**: Package manager for Kubernetes applications
- **ArgoCD**: GitOps continuous delivery tool
- **Terraform**: Infrastructure as Code for cluster provisioning
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Metrics visualization and dashboards
- **Backstage**: Internal Developer Platform for self-service
- **AWS EKS**: Managed Kubernetes service on AWS
- **Azure AKS**: Managed Kubernetes service on Azure