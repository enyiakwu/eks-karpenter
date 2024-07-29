provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  region = local.region
  alias = "dublin"
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  load_config_file       = false

  token                  = data.aws_eks_cluster_auth.this.token

  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   command     = "aws"
  #   # This requires the awscli to be installed locally where Terraform is executed
  #   args = ["eks", "get-token", "--cluster-name", module.eks.this.cluster_name]
  # }
}

data "aws_availability_zones" "available" {}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.dublin
}


data "aws_eks_cluster" "this" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}


locals {
  name   = "ex-${basename(path.cwd)}"
  region = "eu-west-1"
  env_class = "dev"
  cluster_name = module.eks.cluster_name

  vpc_id  = "vpc-1ab9d472"
  vpc_cidr = "172.31.0.0/16"
  public_subnets = var.public_subnets # ["subnet-d1addab8", "subnet-e56bada9", "subnet-2f962555"]
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
}


######################################


# module "vpc" {
#   source             = "../../modules/vpc"
#   cidr_block         = local.vpc_cidr
#   vpc_name           = "dev-vpc"
#   public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
#   private_subnets    = ["10.0.3.0/24", "10.0.4.0/24"]
#   availability_zones = local.azs # ["eu-west-2a", "eu-west-2b"]
# }

# module "iam" {
#   source            = "terraform-aws-modules/terraform-aws-iam//modules/iam-eks-role" # "../../modules/iam"
#   cluster_role_name = "dev-eks-cluster-role"
#   node_role_name    = "dev-eks-node-role"
#   eks_module        = module.eks
# }


module "iam_assumable_role_karpenter" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.7.0"
  create_role                   = true
  role_name                     = "karpenter-controller-${local.env_class}-${local.region}"
  provider_url                  = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_fully_qualified_subjects = ["system:serviceaccount:${kubernetes_namespace.karpenter.id}:karpenter"]
}

# K8 namespace definition
resource "kubernetes_namespace" "karpenter" {
  metadata {
    annotations = {
      name = "karpenter"
    }

    labels = {
      mylabel = "ns-k"
    }

    name = "karpenter"
  }
}


resource "aws_iam_role_policy" "karpenter_contoller" {
  name = "karpenter-policy-eks"
  role = module.iam_assumable_role_karpenter.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
  role       = module.eks.worker_iam_role_name
  policy_arn = data.aws_iam_policy.ssm_managed_instance.arn
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${local.cluster_name}"
  role = module.eks.worker_iam_role_name
}

# Karpenter resource

resource "helm_release" "karpenter" {
  namespace = kubernetes_namespace.karpenter.id

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "0.9.0"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_karpenter.iam_role_arn
  }

  set {
    name  = "clusterName"
    value = local.cluster_name # var.cluster_name
  }

  set {
    name  = "clusterEndpoint"
    value = data.aws_eks_cluster.this.endpoint
  }
  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }
}


data "kubectl_path_documents" "provisioner_manifests" {
  pattern = "./karpenter*.yaml"
  vars = {
    cluster_name = local.cluster_name
  }
}

resource "kubectl_manifest" "provisioners" {
  for_each  = data.kubectl_path_documents.provisioner_manifests.manifests
  yaml_body = each.value
}



module "eks" {
  source               = "terraform-aws-modules/eks/aws" # "../../modules/eks"
  cluster_name         = "dev-eks-cluster"
  cluster_version = "latest"
  subnet_ids           = local.public_subnets
  vpc_id          = local.vpc_id
  enable_irsa     = true

  eks_managed_node_groups = {
    initial = {
      instance_types = ["c5.large", "c6g.large"]

      min_size     = 1
      max_size     = 5
      desired_size = 3
    }
  }

  # cluster_name         = "dev-eks-cluster"
  # cluster_role_arn     = module.iam.cluster_role_arn
  # node_role_arn        = module.iam.node_role_arn
  # subnet_ids           = local.public_subnets
  # kubernetes_version   = "1.30" # don't set this input to allow cluster use latest available kubernetes version
  # node_group_name      = "dev-eks-node-group"
  # desired_size         = 3
  # max_size             = 5
  # min_size             = 1
  # instance_types       = ["c5.large", "c6g.large"]
  # cluster_policy_attachment = module.iam.cluster_policy_attachment
}

module "karpenter" {
  source           = "terraform-aws-modules/eks/aws//modules/karpenter" # "../../modules/karpenter"
  cluster_name     = module.eks.cluster_name
  # cluster_endpoint = module.eks.cluster_endpoint
  # cluster_ca       = module.eks.cluster_certificate_authority

  create_node_iam_role = false
  node_iam_role_arn    = module.eks.eks_managed_node_groups["initial"].iam_role_arn
  create_access_entry = false
}




