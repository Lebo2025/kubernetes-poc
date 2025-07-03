# Generated Terraform configuration for ${{ values.name }} cluster
# Cloud Provider: ${{ values.cloud_provider }}
# Region: ${{ values.region }}

{% if values.cloud_provider == "aws" %}
provider "aws" {
  region = "${{ values.region }}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${{ values.name }}-vpc"
  cidr = "172.31.0.0/16"

  azs             = ["${{ values.region }}a", "${{ values.region }}b"]
  private_subnets = ["172.31.16.0/20", "172.31.48.0/20"]
  public_subnets  = ["172.31.0.0/20", "172.31.32.0/20"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "production"
    ManagedBy   = "backstage"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 19.21.0"
  cluster_name    = "${{ values.name }}-eks"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      name           = "${{ values.name }}-nodes"
      instance_types = ["${{ values.instance_type }}"]
      min_size       = 1
      max_size       = ${{ values.node_count * 2 }}
      desired_size   = ${{ values.node_count }}
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "backstage"
  }
}
{% endif %}

{% if values.cloud_provider == "azure" %}
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${{ values.name }}-rg"
  location = "${{ values.region }}"

  tags = {
    Environment = "production"
    ManagedBy   = "backstage"
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${{ values.name }}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${{ values.name }}"

  default_node_pool {
    name       = "default"
    node_count = ${{ values.node_count }}
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    ManagedBy   = "backstage"
  }
}
{% endif %}