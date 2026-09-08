# ☁️ E-Commerce DevOps & Cloud Infrastructure

[![AWS EKS](https://img.shields.io/badge/Amazon%20EKS-v1.30-FF9900?logo=amazoneks&logoColor=white)](https://aws.amazon.com/eks/)
[![Terraform](https://img.shields.io/badge/Terraform-v1.9+-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20OIDC-2088FF?logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![Cloudflare](https://img.shields.io/badge/Edge%20Security-Cloudflare%20Zero%20Trust-F38020?logo=cloudflare&logoColor=white)](https://www.cloudflare.com/)

> **Note from the author:** I'm a **Fullstack Web Developer**, not a DevOps engineer. This repository documents how I set up a production AWS infrastructure for my e-commerce project. The deployment is fully automated — once provisioned, you only need to `git push` your code and GitHub Actions handles the rest.

---

## 📌 Architecture Reference

> **Architecture Reference:** Infrastructure patterns inspired by [Jayce-Anh/shopping-cart-project](https://github.com/Jayce-Anh/shopping-cart-project) (originally based on [sivaprasadreddy/spring-boot-microservices-series](https://github.com/sivaprasadreddy/spring-boot-microservices-series.git)).
>
> Key differences from the reference:
> - Replaced ArgoCD with lightweight **GitHub Actions + kubectl rollout** (saves ~$20/month RAM on small clusters).
> - Added **Cloudflare Zero Trust** email OTP protection for the Admin Dashboard ($0 cost).
> - Added **self-hosted Inngest** for durable background jobs (no external SaaS subscription).
> - Replaced AWS ElastiCache with **in-cluster Redis 7 Alpine** ($0 cost).

---

## 🔗 Ecosystem Repositories

This project is part of an integrated 4-part microservices platform:

| Repository | Tech Stack | Role & Link |
| :--- | :--- | :--- |
| **Backend Monorepo** | NestJS 11, gRPC, PostgreSQL, Prisma, Inngest | RESTful API Gateway, gRPC microservices, Stripe & Clerk webhooks. <br>🔗 Repo: [`ecommerce-backend`](https://github.com/Hieuej147/ecommerce-backend.git) |
| **Customer Storefront** | Next.js 16, React 19, Tailwind v4, Three.js | Customer shop, 3D interactive hero canvas, cart, Stripe checkout. <br>🔗 Repo: [`-E-commerce`](https://github.com/Hieuej147/-E-commerce.git) |
| **Admin Dashboard** | React 19, Vite, TypeScript, Cloudflare Zero Trust | Backoffice management, real-time KPI metrics, orders & catalog CRUD. <br>🔗 Repo: [`dashboard-admin-ecommern`](https://github.com/Hieuej147/dashboard-admin-ecommern.git) |
| **DevOps & GitOps** *(This Repo)* | Terraform, Helm, AWS EKS, AWS ECR, OIDC | Infrastructure as Code, OIDC authentication, ECR registries, Kubernetes manifests. <br>🔗 Repo: [`ecommerce-devops`](https://github.com/Hieuej147/ecommerce-devops.git) |

---

## 🏗️ System Architecture

```
                                [ End Users & Admins ]
                                          │
                        ┌─────────────────┴─────────────────┐
                        │   Cloudflare Edge Network (SSL)   │
                        │  - store.yourdomain.com (Public)  │
                        │  - api.yourdomain.com (Public)    │
                        │  - admin.yourdomain.com (OTP)     │
                        └─────────────────┬─────────────────┘
                                          │ HTTP (Port 80)
                                          ▼
                   ┌─────────────────────────────────────────────┐
                   │   AWS Application Load Balancer (Public)    │
                   │           Host-Based Routing Rules          │
                   └──────┬───────────────────┬────────────┬─────┘
                          │                   │            │
            ┌─────────────┴──────┐            │            │
            ▼                    ▼            ▼            ▼
   ┌─────────────────┐  ┌─────────────┐  ┌─────────┐  ┌───────────────┐
   │ Storefront:3001 │  │ Admin:80    │  │ API:3000│  │ Inngest:8288  │
   └────────┬────────┘  └──────┬──────┘  └───┬─────┘  └──────┬────────┘
            │                  │             │               │
════════════╪══════════════════╪═════════════╪═══════════════╪══════════════
AWS VPC     │                  │             │               │
  EKS Cluster (v1.30)         │             │               │
  Namespace: ecommerce        │             │               │
            │                  │             │               │
            ▼                  ▼             ▼               ▼
     ┌─────────────┐    ┌─────────────┐ ┌─────────┐    ┌─────────────┐
     │ Storefront  │    │ Admin Dash  │ │ API-GW  │    │   Inngest   │
     │  (Next.js)  │    │ (Nginx SPA) │ │(NestJS) │    │(Self-Hosted)│
     └──────┬──────┘    └─────────────┘ └───┬─────┘    └──────┬──────┘
            │ (Internal Proxy /api/backend) │                 │
            └───────────────────────────────┤                 │
                                            │ gRPC (HTTP/2)   │ Event Bus
                                            ▼                 ▼
                        ┌──────────────────────────────────────────┐
                        │        Backend Microservices             │
                        │  - Catalog Service    - Order Service    │
                        │  - Payment Service    - Users Service    │
                        │  - Agent Service      - Agent Python     │
                        └──────────────┬──────────────────┬────────┘
                                       │ Prisma           │ Cache
                                       ▼                  ▼
                        ┌────────────────────────┐  ┌──────────────┐
                        │  Amazon RDS PostgreSQL │  │ In-Cluster   │
                        │    (Multi-Database)    │  │   Redis 7    │
                        └────────────────────────┘  └──────────────┘
```

---

## 💰 Estimated Monthly Cost

| Service | Estimated Cost | Notes |
| :--- | :--- | :--- |
| **Amazon EKS** (Control Plane) | ~$73/month | Standard EKS fee |
| **EKS Node Group** (2x `t3.small`) | ~$30/month | 2 vCPU, 2GB RAM each |
| **Amazon RDS PostgreSQL** (`db.t4g.micro`) | ~$18/month | Single-AZ, 20GB gp3 |
| **Application Load Balancer** | ~$18/month | Single shared ALB |
| **Amazon ECR** (9 repos) | ~$0.10/month | Lifecycle policy: keep 2 latest |
| **In-Cluster Redis** | **$0** | Replaces $17/mo ElastiCache |
| **Cloudflare SSL + Zero Trust** | **$0** | Free tier (up to 50 users) |
| **GitHub Actions CI/CD** | **$0** | Free for public repos |
| **Total** | **~$139/month** | |

---

## 📁 Repository Structure

```
ecommerce-devops/
├── terraform/
│   ├── main.tf                       # Root infrastructure orchestration
│   ├── variable.tf                   # Input variable definitions
│   ├── outputs.tf                    # Generated ARNs, ALB DNS, and Role info
│   ├── provider.tf                   # AWS provider configuration
│   ├── version.tf                    # Terraform & provider version constraints
│   ├── terraform.tfvars.example      # Configuration template (copy this)
│   └── modules/
│       ├── vpc/                      # Multi-AZ VPC, Public/Private subnets, NAT
│       ├── kms/                      # KMS encryption keys
│       ├── ecr/                      # 9 ECR repositories with lifecycle policy
│       ├── iam-github-oidc/          # AWS IAM OIDC for GitHub Actions (no static keys)
│       ├── database/rds/             # Amazon RDS PostgreSQL 16
│       ├── eks/                      # Amazon EKS v1.30 & Node Group
│       ├── alb/                      # Application Load Balancer with host-based routing
│       └── secret-manager/           # AWS Secrets Manager
└── gitops/
    └── ecommerce-chart/              # Helm chart for all Kubernetes resources
        ├── Chart.yaml
        ├── values.yaml               # Default values for 11 pods
        ├── values.prod.yaml          # Production overrides
        └── templates/
            ├── namespace.yaml
            ├── services.yaml          # ClusterIP & NodePort services
            ├── deployment-redis.yaml   # In-cluster Redis 7 Alpine
            ├── deployment-inngest.yaml # Self-hosted Inngest server
            ├── deployments-backend.yaml # api-gateway, catalog, order, payment, users
            ├── deployments-ai.yaml     # agent-service, agent-python
            ├── deployments-frontend.yaml # storefront, admin-dashboard
            └── targetgroup-bindings.yaml # AWS ALB TargetGroupBindings
```

---

## 🚀 Step-by-Step Deployment Guide

### Prerequisites

Install the following CLI tools:
- **AWS CLI v2** ([docs.aws.amazon.com/cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **Terraform v1.9+** ([terraform.io/downloads](https://www.terraform.io/downloads))
- **kubectl v1.30+** ([kubernetes.io/docs](https://kubernetes.io/docs/tasks/tools/))
- **Helm v3+** ([helm.sh/docs](https://helm.sh/docs/intro/install/))
- A registered domain name on **Cloudflare** (e.g. `yourdomain.com`)

---

### Phase 1: Provision AWS Infrastructure (Terraform)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your details:
```hcl
account_id  = "123456789012"        # Your 12-digit AWS Account ID
admin_user  = "your-iam-username"   # Your AWS IAM username
region      = "ap-southeast-1"      # Your preferred AWS region
domain      = "yourdomain.com"      # Your registered domain
environment = "prod"
```

Then run:
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Note the outputs — you'll need `github_actions_role_arn`, `alb_dns_name`, and `rds_endpoint`.

---

### Phase 2: Connect to Your EKS Cluster

```bash
# Generate kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name ecommerce

# Verify nodes are ready
kubectl get nodes -o wide
```

Expected: 2 nodes in `Ready` status.

---

### Phase 3: Deploy In-Cluster Services

```bash
# Create namespace
kubectl create namespace ecommerce || true

# Deploy Redis cache and Inngest event server
kubectl apply -f ../gitops/ecommerce-chart/templates/deployment-redis.yaml
kubectl apply -f ../gitops/ecommerce-chart/templates/deployment-inngest.yaml

# Verify they're running
kubectl get pods -n ecommerce
```

---

### Phase 4: Configure Cloudflare DNS & Zero Trust

1. **DNS Records** — In your Cloudflare dashboard, add 4 CNAME records pointing to your ALB DNS name:
   - `store` → `<alb_dns_name>` (Proxied 🟧)
   - `api` → `<alb_dns_name>` (Proxied 🟧)
   - `admin` → `<alb_dns_name>` (Proxied 🟧)
   - `inngest` → `<alb_dns_name>` (Proxied 🟧)

2. **SSL Mode** — Go to **SSL/TLS** → Select **Flexible** mode (Cloudflare handles HTTPS, ALB receives HTTP).

3. **Zero Trust Protection** (for Admin Dashboard) — Go to **Zero Trust** → **Access** → **Applications** → **Add application**:
   - Type: Self-hosted
   - Domain: `admin.yourdomain.com`
   - Policy: Allow emails matching your admin email
   - *Result: Admin access requires email OTP verification*

---

### Phase 5: Configure GitHub Actions Secrets

In each of your 3 application repositories, go to **Settings** > **Secrets and variables** > **Actions** > **New repository secret**:

#### `ecommerce-backend`
- `AWS_ROLE_ARN`: `arn:aws:iam::<YOUR_ACCOUNT_ID>:role/prod-ecommerce-github-actions-role`

#### `-E-commerce` (Storefront)
- `AWS_ROLE_ARN`: *(same as above)*
- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`: `pk_test_...`
- `NEXT_PUBLIC_API_URL`: `/api/backend`
- `NEXT_PUBLIC_ADMIN_DASHBOARD_URL`: `https://admin.yourdomain.com`

#### `dashboard-admin-ecommern` (Admin Dashboard)
- `AWS_ROLE_ARN`: *(same as above)*
- `VITE_CLERK_PUBLISHABLE_KEY`: `pk_test_...`
- `VITE_API_BASE_URL`: `https://api.yourdomain.com/v1`
- `VITE_STOREFRONT_URL`: `https://store.yourdomain.com`

---

### Phase 6: Deploy & Verify

Push code to `main` on any of the 3 repositories. GitHub Actions will automatically:
1. Authenticate to AWS via OIDC (no static keys)
2. Build Docker images and push to Amazon ECR
3. Connect to EKS and execute a zero-downtime rolling restart

Verify everything is running:
```bash
kubectl get pods -n ecommerce
# Expected: 11 pods in Running status (1/1)
```

Test your endpoints:
- Storefront: `https://store.yourdomain.com`
- Admin Dashboard: `https://admin.yourdomain.com`
- API Health: `https://api.yourdomain.com/health`

---

## 🔧 Useful Commands

```bash
# View pod logs
kubectl logs -n ecommerce -l app=api-gateway -f --tail=100

# Restart a specific service
kubectl rollout restart deployment/<service-name> -n ecommerce

# Port-forward Redis for local debugging
kubectl port-forward svc/redis 6379:6379 -n ecommerce

# Port-forward Inngest UI
kubectl port-forward svc/inngest 8288:8288 -n ecommerce
```

---

## 🗑️ Infrastructure Teardown

> [!CAUTION]
> Running `terraform destroy` will **permanently delete** all AWS resources (EKS, RDS, VPC, ALB) and all data. Only do this when you're completely done with the project.

```bash
# Step 1: Delete Kubernetes namespace (releases ALB TargetGroup bindings)
kubectl delete namespace ecommerce --timeout=120s

# Step 2: Destroy all Terraform resources
cd terraform
terraform destroy -auto-approve

# Step 3 (Optional): Clear ECR images if deletion fails
for repo in api-gateway catalog order payment users agent-service agent-python storefront admin-dashboard; do
  aws ecr batch-delete-image --repository-name prod-ecommerce-$repo \
    --image-ids "$(aws ecr list-images --repository-name prod-ecommerce-$repo --query 'imageIds[*]' --output json)" 2>/dev/null || true
done
```
