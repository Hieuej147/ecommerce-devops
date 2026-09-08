############################# HELM PROVIDERS #############################

resource "terraform_data" "eks_nodes" {
  input = var.helm_eks_node_group_id
}

data "aws_eks_cluster_auth" "main" {
  name = var.helm_eks_cluster
}

provider "kubernetes" {
  host                   = var.helm_eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.helm_eks_cluster_ca_cert)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes = {
    host                   = var.helm_eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.helm_eks_cluster_ca_cert)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}
