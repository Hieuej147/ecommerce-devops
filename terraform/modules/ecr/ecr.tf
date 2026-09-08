########################### ECR MODULE ##############################

#================= ECR Repositories ================#
resource "aws_ecr_repository" "ecr" {
  for_each             = toset(var.repositories)
  name                 = "${var.project.env}-${var.project.name}-${each.key}"
  force_delete         = true
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key
  }

  tags = merge(var.tags, {
    Name      = "${var.project.env}-${var.project.name}-${each.key}"
    Component = each.key
  })
}

#================= ECR Lifecycle Policy ================#
resource "aws_ecr_lifecycle_policy" "ecr" {
  for_each   = aws_ecr_repository.ecr
  repository = aws_ecr_repository.ecr[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 2 tagged and untagged images to optimize storage costs"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 2
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
