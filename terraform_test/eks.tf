
################################################################################
# EKS Module
################################################################################

module "eks" {
  source                    = "terraform-aws-modules/eks/aws"
  version                   = "18.26.3"
  create_aws_auth_configmap = false
  # manage_aws_auth_configmap = true
  cluster_name                    = local.name
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  # Encryption key
  create_kms_key = true
  cluster_encryption_config = [
    {
      resources = ["secrets"]
    }
  ]
  kms_key_deletion_window_in_days = 7
  enable_kms_key_rotation         = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_ntp_ipv4_cidr_block = ["169.254.169.123/32"]
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    vpc_security_group_ids = [aws_security_group.additional.id]
    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
  }

  self_managed_node_groups = {
    spot = {
      instance_type = "m5.large"
      instance_market_options = {
        market_type = "spot"
      }

      pre_bootstrap_user_data = <<-EOT
      echo "foo"
      export FOO=bar
      EOT

      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

      post_bootstrap_user_data = <<-EOT
      cd /tmp
      sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
      sudo systemctl enable amazon-ssm-agent
      sudo systemctl start amazon-ssm-agent
      EOT
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]

    attach_cluster_primary_security_group = true
    vpc_security_group_ids                = [aws_security_group.additional.id]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
      labels = {
        Environment = "test"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }

      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "gpuGroup"
          effect = "NO_SCHEDULE"
        }
      }

      update_config = {
        max_unavailable_percentage = 50 # or set `max_unavailable`
      }

      tags = {
        ExtraTag = "example"
      }
    }
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        },
        {
          namespace = "default"
        }
      ]

      tags = {
        Owner = "test"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = false

  aws_auth_node_iam_role_arns_non_windows = [
    module.eks_managed_node_group.iam_role_arn,
    module.self_managed_node_group.iam_role_arn,
  ]
  aws_auth_fargate_profile_pod_execution_role_arns = [
    module.fargate_profile.fargate_profile_pod_execution_role_arn
  ]

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::66666666666:role/role1"
      username = "role1"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::66666666666:user/user1"
      username = "user1"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::66666666666:user/user2"
      username = "user2"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [
    "777777777777",
    "888888888888",
  ]

  tags = local.tags
}

################################################################################
# Sub-Module Usage on Existing/Separate Cluster
################################################################################

module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  # source  = "terraform-aws-modules/eks/aws"
  version         = "18.26.3"
  name            = "separate-eks-mng"
  cluster_name    = module.eks.cluster_id
  cluster_version = module.eks.cluster_version

  vpc_id                            = module.vpc.vpc_id
  subnet_ids                        = module.vpc.private_subnets
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids = [
    module.eks.cluster_security_group_id,
  ]

  tags = merge(local.tags, { Separate = "eks-managed-node-group" })
}

module "self_managed_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/self-managed-node-group"
  version = "18.26.3"

  name                = "separate-self-mng"
  cluster_name        = module.eks.cluster_id
  cluster_version     = module.eks.cluster_version
  cluster_endpoint    = module.eks.cluster_endpoint
  cluster_auth_base64 = module.eks.cluster_certificate_authority_data

  instance_type = "m5.large"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  vpc_security_group_ids = [
    module.eks.cluster_primary_security_group_id,
    module.eks.cluster_security_group_id,
  ]

  use_default_tags = true

  tags = merge(local.tags, { Separate = "self-managed-node-group" })
}

module "fargate_profile" {
  source  = "terraform-aws-modules/eks/aws//modules/fargate-profile"
  version = "18.26.3"

  name         = "separate-fargate-profile"
  cluster_name = module.eks.cluster_id

  subnet_ids = module.vpc.private_subnets
  selectors = [
    {
      namespace = "kube-system"
    }
  ]

  tags = merge(local.tags, { Separate = "fargate-profile" })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  intra_subnets   = ["10.0.7.0/28", "10.0.7.16/28", "10.0.7.32/28"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }

  tags = local.tags
}

resource "aws_security_group" "additional" {
  name_prefix = "${local.name}-additional"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  tags = local.tags
}


#provider "helm" {
#  kubernetes {
#    config_path = "~/.kube/config"
#  }
#}
#provider "helm" {
#  kubernetes {
#    host                   = module.eks.cluster_endpoint #cluster.endpoint
#    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#    # .aws_eks_cluster.cluster.certificate_authority.0.data)
#    exec {
#      api_version = "client.authentication.k8s.io/v1alpha1"
#      args        = [
#        "eks", "get-token", "--cluster-name", module.eks.cluster_id
#      ]
#      command     = "aws"
#    }
#  }
#}
#
#
#resource "helm_release" "nginx_ingress" {
#  name  = "nginx-ingress-controller"
#  #  verify = true
#  #  repository = "https://charts.bitnami.com/bitnami"
#  chart = "https://charts.bitnami.com/bitnami/nginx-ingress-controller-9.2.17.tgz"
#
#  set {
#    name  = "service.type"
#    value = "ClusterIP"
#  }
#}


#module "eks-ingress-nginx" {
#  source  = "lablabs/eks-ingress-nginx/aws"
#
#  version = "0.4.1"
#}


#resource "helm_release" "ingress-nginx" {
#  name = "ingress-nginx"
#  repository = "https://kubernetes.github.io/ingress-nginx"
#  chart = "ingress-nginx"
#  namespace = "ingress"
#  version = "4.0.13"
#  create_namespace = true
#  timeout = 300
#
#  values = [
#    "${file("./chart_values.yaml")}"
#  ]
#
#  set {
#    name  = "cluster.enabled"
#    value = "true"
#  }
#
#  set {
#    name  = "metrics.enabled"
#    value = "true"
#  }
#
##  depends_on = [local_file.kubeconfig_EKS_Cluster]
#
#}

#resource "helm_release" "nginx_ingress_chart" {
#  name       = "nginx-ingress-controller"
#  repository = "https://charts.bitnami.com/bitnami"
#  chart      = "nginx-ingress-controller"
#  verify = false
##  values = [
##    file("${path.module}/kubewatch-values.yaml")
##  ]
##
##  set_sensitive {
##    name  = "slack.token"
##    value = var.slack_app_token
##  }
#}
##nginx-ingress-controller
