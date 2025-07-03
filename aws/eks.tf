provider "aws" {
  region = "eu-west-1"

  # Explicitly set higher timeout for API calls
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Increase timeouts
  max_retries = 10
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "platform-poc-vpc"
  cidr = "172.31.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["172.31.16.0/20", "172.31.48.0/20"]
  public_subnets  = ["172.31.0.0/20", "172.31.32.0/20"]

  enable_nat_gateway = true
  single_nat_gateway = true

  # Tags required for EKS
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"       = 1
    "kubernetes.io/cluster/platform-poc-eks" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                = 1
    "kubernetes.io/cluster/platform-poc-eks" = "shared"
  }

  tags = {
    Environment = "poc"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 19.21.0"
  cluster_name    = "platform-poc-eks"
  cluster_version = "1.28"

  # Network configuration
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # Endpoint access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      name           = "platform-poc-nodes"
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 4
      desired_size   = 2

      subnet_ids = module.vpc.private_subnets

      tags = {
        Environment = "poc"
      }
    }
  }

  tags = {
    Environment = "poc"
  }
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "region" {
  value = "eu-west-1"
}

output "cluster_iam_role_name" {
  value = module.eks.cluster_iam_role_name
}
