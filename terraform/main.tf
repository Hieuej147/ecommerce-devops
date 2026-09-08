######################################## MAIN ##########################################

#================= Route 53 Hosted Zone =================#
module "hosted_zone" {
  source          = "./modules/route53"
  project         = var.project
  tags            = var.tags
  r53_domain_name = var.project.domain
}

#================= ACM Certificate =================#
module "acm" {
  source             = "./modules/acm"
  project            = var.project
  tags               = var.tags
  acm_hosted_zone_id = module.hosted_zone.hosted_zone_id
}

#================= KMS Key =================#
module "kms" {
  source  = "./modules/kms"
  project = var.project
  tags    = var.tags
}

#================= VPC =================#
module "vpc" {
  source  = "./modules/vpc"
  project = var.project
  tags    = var.tags
}

#================= Secret Manager =================#
module "secret_manager" {
  source     = "./modules/secret-manager"
  project    = var.project
  tags       = var.tags
  kms_key    = module.kms.key_arn
  secret_rds = module.rds.rds_credentials
}

#================= GitHub Actions OIDC Role =================#
module "github_oidc" {
  source              = "./modules/iam-github-oidc"
  project             = var.project
  tags                = var.tags
  kms_key_arn         = module.kms.key_arn
  github_repositories = var.github_repositories
}

#================= ECR (9 Microservices & Apps) =================#
module "ecr" {
  source  = "./modules/ecr"
  project = var.project
  tags    = var.tags
  kms_key = module.kms.key_arn
  repositories = [
    "api-gateway",
    "catalog",
    "order",
    "payment",
    "users",
    "agent-service",
    "agent-python",
    "storefront",
    "admin-dashboard"
  ]
}

#================= External Application Load Balancer =================#
module "alb" {
  source         = "./modules/alb"
  project        = var.project
  tags           = var.tags
  alb_vpc_id     = module.vpc.vpc_id
  alb_subnet_ids = module.vpc.public_subnet_ids
  alb_dns_cert   = module.acm.cert_arns
  allowed_cidrs  = var.allowed_cidrs
}

#================= Database (PostgreSQL 16 RDS) =================#
module "rds" {
  source         = "./modules/database/rds"
  project        = var.project
  tags           = var.tags
  rds_vpc_id     = module.vpc.vpc_id
  rds_subnet_ids = module.vpc.private_subnet_ids
  rds_allowed_sg = [module.eks.node_group_sg_id]
  kms_key        = module.kms.key_arn
}

# Note: Cache is hosted directly inside EKS using a lightweight redis:7-alpine Pod (100% Free, saving $15/mo)

#================= EKS Cluster =================#
module "eks" {
  source         = "./modules/eks"
  project        = var.project
  tags           = var.tags
  eks_vpc_id     = module.vpc.vpc_id
  eks_subnet_ids = module.vpc.private_subnet_ids
  kms_key        = module.kms.key_arn
  eks_allowed_sg = []
  allowed_cidrs  = var.allowed_cidrs
  eks_alb_sg_id  = module.alb.lb_sg_id
  eks_admin_access = {
    admin_user = data.aws_iam_user.admin_user.arn
  }
}

#================= Helm Addons & ArgoCD =================#
module "helm" {
  source                 = "./modules/helm"
  project                = var.project
  tags                   = var.tags
  helm_eks_cluster       = module.eks.eks_cluster_name
  helm_eks_node_group_id = module.eks.node_group_id
  helm_vpc_id            = module.vpc.vpc_id
  kms_key                = module.kms.key_arn
  helm_repo_url          = var.helm_repo
  helm_argocd_tg_arn     = module.alb.tg_arns["argocd"]
  helm_sqs_queue_arn     = ""
  helm_rds_secret        = module.secret_manager.secret_arn["rds-credentials"]
  helm_addon_secret      = module.secret_manager.secret_arn["helm-addon-credentials"]
  helm_git_token_secret  = module.secret_manager.secret_arn["helm-git-token"]
}
