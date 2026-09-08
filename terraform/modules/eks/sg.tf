######################## EKS SECURITY GROUPS ########################

#========================== Node Group Security Group ===========================#
resource "aws_security_group" "node_group" {
  name_prefix = "${var.project.env}-${var.project.name}-eks-node-"
  description = "Security group for EKS node group"
  vpc_id      = var.eks_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-eks-node-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Allow nodes to talk to each other
resource "aws_security_group_rule" "node_group_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.node_group.id
  description       = "Allow node-to-node communication"
}

# Allow cluster security group to reach nodes
resource "aws_security_group_rule" "node_group_from_cluster" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow traffic from EKS cluster security group"
}

# Allow external ALB to reach specific pod ports (Least Privilege: Admin: 80, API Gateway: 3000, Storefront: 3001)
resource "aws_security_group_rule" "node_group_from_alb" {
  for_each = toset(["80", "3000", "3001"])

  type                     = "ingress"
  from_port                = tonumber(each.value)
  to_port                  = tonumber(each.value)
  protocol                 = "tcp"
  source_security_group_id = var.eks_alb_sg_id
  security_group_id        = aws_security_group.node_group.id
  description              = "Allow traffic from external ALB to pod port ${each.value}"
}

#========================== Cluster API Access ===========================#
resource "aws_security_group_rule" "cluster_ingress_from_sg" {
  count = length(var.eks_allowed_sg)

  type                     = "ingress"
  security_group_id        = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  source_security_group_id = var.eks_allowed_sg[count.index]
  description              = "Allow EKS API access from ${var.eks_allowed_sg[count.index]}"

  depends_on = [aws_eks_cluster.eks]
}
