# ☁️ E-Commerce DevOps & GitOps Platform

Complete Infrastructure as Code (Terraform) and GitOps Continuous Delivery (ArgoCD & Helm) repository for the full-stack E-Commerce microservices ecosystem.

---

## 🔗 Ecosystem Repositories

| Repository | Tech Stack | Role & Link |
| :--- | :--- | :--- |
| **Backend Monorepo** | NestJS 11, gRPC, PostgreSQL, Prisma, Inngest | RESTful API Gateway, gRPC services, Stripe & Clerk webhooks. <br>🔗 Repo: [`ecommerce-backend`](https://github.com/Hieuej147/ecommerce-backend.git) |
| **Customer Storefront** | Next.js 16, React 19, Tailwind v4, Three.js | Customer shop, 3D interactive hero canvas, cart, Stripe checkout. <br>🔗 Repo: [`-E-commerce`](https://github.com/Hieuej147/-E-commerce.git) |
| **Admin Dashboard** | React 19, Vite, TypeScript, Cloudflare Zero Trust | Backoffice management, real-time KPI metrics, orders & catalog CRUD. <br>🔗 Repo: [`dashboard-admin-ecommern`](https://github.com/Hieuej147/dashboard-admin-ecommern.git) |
| **DevOps & GitOps** (This repo) | Terraform, Helm, ArgoCD, AWS EKS, AWS ECR | IaC, OIDC authentication, ECR registries, Kubernetes manifests. |

---

## 📌 Architecture Reference & Modernization

> 🔗 **Original Reference Project:** [Jayce-Anh/shopping-cart-project](https://github.com/Jayce-Anh/shopping-cart-project) (adapted from [sivaprasadreddy/spring-boot-microservices-series](https://github.com/sivaprasadreddy/spring-boot-microservices-series.git)).

This repository modernizes and upgrades the DevOps infrastructure from the reference project:
- **9 ECR Repositories** instead of 3 legacy Java services.
- **AWS IAM OIDC for GitHub Actions** instead of an expensive EC2 GitLab runner ($0 vs $30/mo).
- **PostgreSQL 16.3 RDS** instead of MySQL 8.0 for full Prisma ORM support.
- **Host-based ALB Ingress** (`api.`, `store.`, `admin.`, `argocd.`) instead of path-based routing.
- **Unified Helm Chart** deploying all 9 components via ArgoCD GitOps.

## 📁 Repository Structure

```
ecommerce-devops/
├── terraform/
│   ├── main.tf                       # Primary Terraform orchestration
│   ├── variable.tf                   # Input variable definitions
│   ├── outputs.tf                    # Outputs (AWS_ROLE_ARN, ECR URLs, ALB DNS)
│   ├── provider.tf                   # AWS provider and caller identity
│   ├── version.tf                    # Terraform version constraints
│   ├── terraform.tfvars.example      # Configuration template for your AWS account
│   └── modules/
│       ├── vpc/                      # Multi-AZ VPC with Public/Private subnets & NAT Gateway
│       ├── kms/                      # KMS Customer Managed Key for encryption
│       ├── ecr/                      # 9 ECR Repositories with lifecycle cleanup
│       ├── iam-github-oidc/          # AWS IAM OIDC Provider & Role for GitHub Actions (No static keys)
│       ├── database/rds/             # Amazon RDS PostgreSQL 16
│       ├── eks/                      # Amazon EKS v1.30 Cluster & Managed Node Group
│       ├── alb/                      # Application Load Balancer with Host-Based routing
│       ├── route53/                  # Route 53 DNS zone
│       ├── acm/                      # Wildcard SSL (*.yourdomain.com) certificate
│       ├── secret-manager/           # AWS Secrets Manager for credentials
│       └── helm/                     # EKS Addons: AWS Load Balancer Controller, ArgoCD
└── gitops/
    ├── argocd/
    │   └── apps.yaml                 # ArgoCD Root Application (App-of-Apps)
    └── ecommerce-chart/              # Production Helm Chart
        ├── Chart.yaml
        ├── values.yaml               # Values for all 9 components + in-cluster Redis
        └── templates/
            ├── namespace.yaml
            ├── services.yaml         # ClusterIP services
            ├── deployment-redis.yaml     # In-cluster Redis 7 Alpine cache ($0 free)
            ├── deployments-backend.yaml  # api-gateway, catalog, order, payment, users
            ├── deployments-ai.yaml       # agent-service, agent-python
            ├── deployments-frontend.yaml # storefront, admin-dashboard
            ├── ingress.yaml          # Host routing: api., store., admin.
            └── targetgroup-bindings.yaml # AWS TargetGroupBindings
```

---

## 🚀 Step-by-Step AWS Deployment Walkthrough

### Step 1: Configure Terraform Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars`:
- `account_id`: Your 12-digit AWS Account ID (e.g. `123456789012`).
- `domain`: Your registered domain (e.g. `yourdomain.com`).
- `admin_user`: Your IAM username (e.g. `admin`).
- `region`: Preferred AWS region (default: `ap-southeast-1` Singapore).

### Step 2: Initialize & Apply Infrastructure
```bash
terraform init
terraform plan
terraform apply
```
Review the planned resources and type `yes`. Terraform will provision:
- VPC & NAT Gateway
- EKS Cluster & Node Group
- RDS PostgreSQL 16 (In-cluster Redis 7 Pod for cache - $0 free)
- 9 ECR Repositories
- AWS IAM OIDC Provider for GitHub Actions
- Application Load Balancer & Target Groups
- ArgoCD GitOps Operator

### Step 3: Configure GitHub Actions Secrets
From the Terraform output, copy `github_actions_role_arn`:
Navigate to each of your 3 GitHub repositories -> **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**:

| Secret Name | Description / Value |
| :--- | :--- |
| `AWS_ROLE_ARN` | The ARN from Terraform output `github_actions_role_arn` |
| `AWS_REGION` | `ap-southeast-1` |
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | Clerk Publishable Key (`pk_test_...` or `pk_live_...`) |
| `STRIPE_SECRET_KEY` | Stripe Secret Key (`sk_test_...` or `sk_live_...`) |

### Step 4: Configure Perimeter Security (Cloudflare Zero Trust - Option 1)
1. Point your domain DNS to Cloudflare (Free tier).
2. Create CNAME records pointing `store.yourdomain.com`, `admin.yourdomain.com`, and `api.yourdomain.com` to the ALB DNS name from Terraform output `alb_dns_name`.
3. In Cloudflare Dashboard -> **Zero Trust** -> **Access** -> **Applications** -> **Add application**:
   - Application Type: **Self-hosted**
   - Application Name: `Admin Backoffice`
   - Domain: `admin.yourdomain.com`
   - Policy: Action `Allow`, Rule: Include `Emails` -> your administrator email.
   - *Result: All requests to `admin.yourdomain.com` require a 6-digit OTP sent to your email, blocking all unauthorized internet bots before they reach AWS.*

### Step 5: Configure Stripe & Clerk Webhooks
- **Stripe Webhook**: `https://api.yourdomain.com/v1/payments/webhook/stripe`
- **Clerk Webhook**: `https://api.yourdomain.com/v1/webhooks/clerk`

### Step 6: Trigger Automated CI/CD Deployment
Push code to `main` on any of your repositories:
- GitHub Actions automatically authenticates to AWS via OIDC.
- Builds multi-stage Docker images and pushes to Amazon ECR.
- ArgoCD detects updated images and performs rolling zero-downtime deployments on EKS!

---

## 🛑 Clean Up & Infrastructure Teardown
To destroy all AWS cloud resources and stop recurring billing:
```bash
cd terraform
terraform destroy
```
Type `yes` to confirm deletion.
