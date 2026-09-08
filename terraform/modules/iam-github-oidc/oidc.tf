########################### GITHUB ACTIONS OIDC ROLE ###########################

# GitHub Actions OIDC Thumbprint
# Reference: https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-github-oidc"
  })
}

# Trust policy allowing specified GitHub repos on any branch/tag
data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = flatten([
        [for repo in var.github_repositories : "repo:${repo}:*"],
        [for repo in var.github_repositories : "repo:${split("/", repo)[0]}*${trimprefix(split("/", repo)[1], "-")}*:*"]
      ])
    }
  }
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name               = "${var.project.env}-${var.project.name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-github-actions-role"
  })
}

# ECR Push & KMS permissions policy
data "aws_iam_policy_document" "github_actions_ecr" {
  statement {
    sid    = "ECRAuthToken"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = ["arn:aws:ecr:*:*:repository/${var.project.env}-${var.project.name}-*"]
  }

  statement {
    sid    = "KMSAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [var.kms_key_arn]
  }

  statement {
    sid    = "EKSAccess"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions_ecr_policy" {
  name   = "${var.project.env}-${var.project.name}-github-actions-policy"
  role   = aws_iam_role.github_actions_role.id
  policy = data.aws_iam_policy_document.github_actions_ecr.json
}
