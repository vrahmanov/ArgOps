module "eks-helm-argocd" {
  source  = "rallyware/eks-helm-argocd/aws"
  version = "0.1.1"

  eks_cluster_id = module.eks.cluster_id
  name           = "argocd"
  namespace      = "argops"
}
module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
  version = "2.0.4"
  depends_on = [module.eks]
  publish_service =true
  additional_set = [
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "nlb"
      type  = "string"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
      value = "true"
      type  = "string"
    }
  ]
}
#https://github.com/hagzag/argocd-tf
#module "argo" {
#  source = "https://github.com/hagzag/argocd-tf"
#}

#module "nginx_ingress_controller" {
#  source = "./cloud-platform-terraform-ingress-controller/"
#  cluster_domain_name = "argopstest.com"
#  controller_name = "nginx-argops"
#  replica_count = 2
#}
#module "web_ssl" {
#  depends_on = [
#    module.eks,
#  ]
#  providers = {
#    aws        = aws
#    kubernetes = kubernetes
#    helm       = helm
#  }
#  source = "dabble-of-devops-bioanalyze/eks-bitnami-nginx-ingress/aws"
#  version = "0.6.0"
#  letsencrypt_email                     = "vladi.rahmanov@gmail.com"
##  helm_values_dir                       = abspath("helm_charts/web_app")
#  helm_release_name = "web_app"
#}


#resource "kubernetes_namespace" "argocd" {
#  metadata {
#    annotations = {
#      created-by = "terraform"
#    }
#
#    labels = {
#      purpose = "ArgoCD-IAC"
#    }
#
#    name = "argocd"
#  }
#}

#resource "helm_release" "argsqocd" {
#  name       = "argo-cd"
#  repository = "https://argoproj.github.io/argo-helm"
#  chart      = "argo-cd"
#  version    = "3.11.2"
#  namespace  = kubernetes_namespace.argocd.metadata.0.name
#
#  set {
#    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
#    value = var.acm_cert_arn
#    type  = "string"
#  }
#
#  set {
#    name  = "server.service.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
#    value = var.argocd_fqdn
#    type  = "string"
#  }
#
#  set {
#    name  = "configs.secret.argocdServerAdminPassword"
#    value = local.password
#  }
#
#  set {
#    name  = "configs.secret.argocdServerAdminPasswordMtime"
#    value = var.argocd_admin_password_timestamp
#  }
#
#  set {
#    name  = "server.config.url"
#    value = "https://${var.argocd_fqdn}"
#  }
#
#  values = [var.helm_values]
#
#  /* values = [
#    file("${path.module}/argocd-values.yaml"),
#  ] */
#
#
#}


