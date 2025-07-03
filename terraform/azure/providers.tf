terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = var.aks_cluster_context
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
  config_context = var.aks_cluster_context
}