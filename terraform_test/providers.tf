
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint #cluster.endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    # .aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = [
        "eks", "get-token", "--cluster-name", local.name
      ]
      command = "aws"
    }
  }
}

#provider "helm" {
#  kubernetes {
#    host                   = var.cluster_endpoint
#    cluster_ca_certificate = base64decode(var.cluster_ca_cert)
#    exec {
#      api_version = "client.authentication.k8s.io/v1alpha1"
#      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
#      command     = "aws"
#    }
#  }
#}
provider "aws" {
  region = local.region

  default_tags {
    tags = {
      ExampleDefaultTag = "ExampleDefaultValue"
    }
  }
}
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", local.name]
  }
}