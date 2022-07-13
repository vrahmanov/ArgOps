terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.22"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.1"
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
