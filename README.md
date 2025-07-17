# Kubernetes Cloud-Agnostic POC

This POC demonstrates cloud-agnostic Kubernetes deployments using Helm charts and ArgoCD, deploying the same application to both AWS EKS and Azure AKS.

## Overview

This project showcases how Kubernetes enables true multi-cloud deployments by:
- Using a single Helm chart that deploys to multiple cloud providers
- Leveraging cloud-specific configurations through values files
- Implementing advanced scheduling with pod affinity and topology constraints
- Optimizing for high availability (AWS) vs cost efficiency (Azure)
- Implementing GitOps practices with ArgoCD for automated deployments
- Maintaining consistency while optimizing for each cloud platform
- Supporting blue-green deployment strategy for zero-downtime updates

## Architecture

- **Single Helm Chart**: `helm-charts/app1/` contains the base application template
- **Environment-Specific Values**: Cloud-specific configurations in `environments/`
- **ArgoCD Applications**: Separate apps for each cloud using the same chart
- **GitOps**: ArgoCD manages deployments from this Git repository
- **Blue-Green Deployments**: Zero-downtime updates with separate blue and green environments

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

## Blue-Green Deployment

The application uses a blue-green deployment strategy for zero-downtime updates:

1. **How it works:**
   - Two identical environments (blue and green) are maintained
   - Only one environment receives production traffic at a time
   - Updates are applied to the inactive environment
   - Traffic is switched to the updated environment after testing

2. **Implementation:**
   - Both blue and green deployments run simultaneously
   - The active version is controlled by the `blueGreen.active` value in values.yaml
   - A main service routes traffic to the active deployment
   - A preview service allows testing the inactive deployment before switching

3. **Performing a blue-green deployment:**
   ```bash
   # 1. Update the inactive deployment with new version
   # If blue is active, update green values.yaml:
   # blueGreen.green.tag: "1.26"
   
   # 2. Apply the changes and wait for the new version to be ready
   kubectl apply -f argocd-apps/app-of-apps.yaml
   
   # 3. Test the new version using the preview service
   # Access http://<PREVIEW-SERVICE-IP>
   
   # 4. Switch traffic to the new version by updating values.yaml:
   # blueGreen.active: "green"
   
   # 5. Apply the change to switch traffic
   kubectl apply -f argocd-apps/app-of-apps.yaml
   ```

4. **Rollback:**
   - To rollback, simply switch the active version back:
   ```bash
   # Update values.yaml:
   # blueGreen.active: "blue"
   
   # Apply the change
   kubectl apply -f argocd-apps/app-of-apps.yaml
   ```

## Cloud Differences Handled

### AWS EKS Configuration (High Availability)
**Application:**
- **Replicas**: 3 instances for higher availability
- **Resources**: 500m CPU / 512Mi memory limits
- **Load Balancer**: Network Load Balancer (NLB) with AWS-specific annotations
- **Region**: eu-west-1
- **Node Affinity**: Required scheduling across availability zones (eu-west-1a, eu-west-1b)
- **Pod Anti-Affinity**: Required - strict pod separation across nodes
- **Topology Spread**: Strict constraints (maxSkew: 1, DoNotSchedule)
- **Node Selection**: Specific instance types (t3.medium)

**Monitoring:**
- **Prometheus**: 500m CPU / 1Gi memory limits
- **Grafana**: 200m CPU / 256Mi memory limits
- **Load Balancer**: NLB for Grafana access

### Azure AKS Configuration (Cost Optimized)
**Application:**
- **Replicas**: 2 instances for cost optimization
- **Resources**: 400m CPU / 512Mi memory limits
- **Load Balancer**: Azure Load Balancer with resource group annotations
- **Region**: eastus
- **Node Affinity**: Preferred scheduling across zones (flexible)
- **Pod Anti-Affinity**: Preferred - soft pod separation for cost efficiency
- **Topology Spread**: Flexible constraints (maxSkew: 2, ScheduleAnyway)
- **Node Selection**: Default agent pool with OS selection

**Monitoring:**
- **Prometheus**: 400m CPU / 512Mi memory limits (cost optimized)
- **Grafana**: 150m CPU / 200Mi memory limits (cost optimized)
- **Load Balancer**: Azure Load Balancer for Grafana access

## Key Benefits

- **Portability**: Same applications and monitoring run on multiple clouds without code changes
- **Consistency**: Identical deployment process across all environments
- **Optimization**: Cloud-specific configurations for performance and cost
- **Advanced Scheduling**: Pod affinity, anti-affinity, and topology spread constraints per cloud
- **High Availability**: Intelligent pod distribution across availability zones
- **Cost Efficiency**: Flexible vs strict scheduling based on cloud strategy
- **Automation**: GitOps ensures deployments stay synchronized
- **Observability**: Unified monitoring across all cloud environments
- **Scalability**: Easy to add new cloud providers or environments
- **Zero-Downtime Updates**: Blue-green deployment strategy for seamless updates

## Ingress Routes

The following ingress routes are configured:

**AWS:**
- `app.aws.lebo.com` → App1 Service
- `app-preview.aws.lebo.com` → App1 Preview Service
- `grafana.aws.lebo.com` → Grafana Service
- `prometheus.aws.lebo.com` → Prometheus Service
- `argocd.aws.lebo.com` → ArgoCD Service

**Azure:**
- `app.azure.lebo.com` → App1 Service
- `app-preview.azure.lebo.com` → App1 Preview Service
- `grafana.azure.lebo.com` → Grafana Service
- `prometheus.azure.lebo.com` → Prometheus Service
- `argocd.azure.lebo.com` → ArgoCD Service

## Future Enhancements

This POC can be extended with:

- **Backstage IDP**: Self-service cluster provisioning
- **Additional Clouds**: GCP, DigitalOcean support
- **Advanced Monitoring**: Custom dashboards and alerts
- **Security Scanning**: Container and infrastructure security
- **Cost Optimization**: Resource usage monitoring
- **Canary Deployments**: Percentage-based traffic splitting

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