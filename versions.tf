terraform {
  required_version = ">= 0.13.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.72"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

#terraform {
#  required_providers {
#    helm = {
#      source = "hashicorp/helm"
#      version = "2.6.0"
#    }
#  }
#}
#
#provider "helm" {
#  # Configuration options
#}
