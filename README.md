# ☁️ E-Commerce DevOps & Cloud Infrastructure

[![AWS EKS](https://img.shields.io/badge/Amazon%20EKS-v1.30-FF9900?logo=amazoneks&logoColor=white)](https://aws.amazon.com/eks/)
[![Terraform](https://img.shields.io/badge/Terraform-v1.9+-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20OIDC-2088FF?logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![Cloudflare](https://img.shields.io/badge/Edge%20Security-Cloudflare%20Zero%20Trust-F38020?logo=cloudflare&logoColor=white)](https://www.cloudflare.com/)

> **Note from the author:** I'm a **Fullstack Web Developer**, not a dedicated DevOps engineer. This repository documents how I designed and automated a cloud-native AWS production infrastructure for my e-commerce ecosystem. The platform is completely automated: once provisioned, you simply `git push` code changes and GitHub Actions handles testing, containerization, and zero-downtime rolling updates.

---

## 📌 Architecture Reference & Enhancements

> **Architecture Reference:** Inspired by and adapted from the e-commerce architecture patterns in [Jayce-Anh/shopping-cart-project](https://github.com/Jayce-Anh/shopping-cart-project) (originally based on [sivaprasadreddy/spring-boot-microservices-series](https://github.com/sivaprasadreddy/spring-boot-microservices-series.git)).

### Key Adaptations & Customizations:
1. **Decoupled 4-Repository Ecosystem**: Separated the single monorepo into 4 focused repositories (Backend, Storefront, Admin Dashboard, and DevOps) with independent CI/CD lifecycles.
2. **Modern Web Stack**: Replaced legacy Java 8 / Spring Boot with **NestJS 11 (TypeScript)**, **gRPC (Protocol Buffers)**, **Next.js 16 (React 19)**, and **Vite SPA**.
3. **Lean Direct GitOps Rollout (No Heavy ArgoCD)**: Rather than running ArgoCD controllers inside EKS (which consume significant RAM on small clusters), deployments use **GitHub Actions with AWS IAM OIDC** to build, push to ECR, and execute `kubectl rollout restart` with zero downtime.
4. **Cloudflare Zero Trust Edge Protection**: Added an edge OTP email verification firewall for the Admin Dashboard (`admin.yourdomain.com`), blocking port scans and brute-force attacks before traffic touches AWS.
5. **Self-Hosted Inngest Server**: Deployed an in-cluster Inngest server backed by PostgreSQL and Redis for durable background workflows without SaaS subscriptions.
6. **In-Cluster Redis Caching**: Replaced managed AWS ElastiCache with a lightweight, high-performance in-cluster Redis 7 container.

---

## 🔗 Ecosystem Repositories

This project is part of an integrated 4-part microservices platform:

| Repository | Tech Stack | Role & Link |
| :--- | :--- | :--- |
| **Backend Monorepo** | NestJS 11, gRPC, PostgreSQL, Prisma, Inngest | REST API Gateway, 5 gRPC microservices, Python AI agent, Stripe & Clerk webhooks. <br>🔗 Repo: [`ecommerce-backend`](https://github.com/Hieuej147/ecommerce-backend.git) |
| **Customer Storefront** | Next.js 16, React 19, Tailwind v4 | Customer shop, responsive featured hero banner, cart, Stripe checkout. <br>🔗 Repo: [`-E-commerce`](https://github.com/Hieuej147/-E-commerce.git) |
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
            ▼                    ▼            ▼            │
   ┌─────────────────┐  ┌─────────────┐  ┌─────────┐       │
   │ Storefront:3001 │  │ Admin:80    │  │ API:3000│       │
   └────────┬────────┘  └──────┬──────┘  └───┬─────┘       │
            │                  │             │             │
════════════╪══════════════════╪═════════════╪═════════════╪════════════════════
AWS VPC     │                  │             │             │
  EKS Cluster (v1.30)          │             │             │
  Namespace: ecommerce         │             │             │
            │                  │             │             │
            ▼                  ▼             ▼             │
     ┌─────────────┐    ┌─────────────┐ ┌─────────┐        │ (Private / Internal)
     │ Storefront  │    │ Admin Dash  │ │ API-GW  │        ▼
     │  (Next.js)  │    │ (Nginx SPA) │ │(NestJS) │  ┌─────────────┐
     └──────┬──────┘    └─────────────┘ └───┬─────┘  │   Inngest   │
            │ (Internal Proxy /api/backend) │        │(Port-forward│
            └───────────────────────────────┤        │ or Private) │
                                            │ gRPC   └──────┬──────┘
                                            ▼               │ Event Bus
                        ┌───────────────────────────────────┼──────┐
                        │        Backend Microservices      │      │
                        │  - Catalog Service (5001)         │      │
                        │  - Order Service (5002)           │      │
                        │  - Payment Service (5003)         │      │
                        │  - Users Service (5004)           │      │
                        │  - Agent Service & Python (3010)  │      │
                        └──────────────┬──────────────────┬─┘      │
                                       │ Prisma           │ Cache  │
                                       ▼                  ▼        ▼
                        ┌────────────────────────┐  ┌──────────────┐
                        │  Amazon RDS PostgreSQL │  │ In-Cluster   │
                        │    (Multi-Database)    │  │   Redis 7    │
                        └────────────────────────┘  └──────────────┘
```

> **Security Note:** Only **3 public endpoints** exist on the ALB: `store.yourdomain.com`, `admin.yourdomain.com` (guarded by Cloudflare Zero Trust OTP), and `api.yourdomain.com`. Inngest, Redis, and internal gRPC microservices are completely private within the VPC and never exposed to the public internet.

---

## 🛠️ AWS Services & Architectural Optimizations

| AWS Component | Configuration | Architectural Strategy & Purpose |
| :--- | :--- | :--- |
| **Amazon EKS** | v1.30 Cluster + Managed Node Group | Elastic container orchestration hosting 11 pods across frontend, backend, and data services. |
| **Worker Nodes** | 2x `t3.small` Instances | Balanced CPU/memory allocation with resource limits per container to maximize density. |
| **Amazon RDS PostgreSQL** | `db.t4g.micro` (PostgreSQL 16) | Shared multi-database setup (`ecommerce_catalog`, `ecommerce_orders`, etc.) with `skip_final_snapshot` and zero unattached storage waste. |
| **Application Load Balancer** | 1 Shared Public ALB | Host-based routing directs traffic to 3 services via `TargetGroupBinding` without provisioning multiple costly load balancers. |
| **Amazon ECR** | 9 Private Repositories | Lifecycle policies automatically keep only the latest 2 image tags per repository to minimize storage costs. |
| **In-Cluster Redis 7** | Alpine Linux container on EKS | Replaces expensive managed cache services while keeping latency under 2ms for internal caching. |
| **Cloudflare Edge** | Universal SSL + Zero Trust | Free SSL termination and email OTP authentication layer protecting backoffice access. |
| **GitHub Actions OIDC** | Short-lived AWS IAM Web Identity | Eliminates static `AWS_ACCESS_KEY_ID` storage in GitHub; runners assume temporary roles securely. |

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
│   ├── terraform.tfvars.example      # Configuration template (copy to terraform.tfvars)
│   └── modules/
│       ├── vpc/                      # Multi-AZ VPC, Public/Private subnets, NAT Gateway
│       ├── kms/                      # KMS Customer Managed Keys for encryption
│       ├── ecr/                      # 9 ECR repositories with 2-image lifecycle policy
│       ├── iam-github-oidc/          # AWS IAM OIDC for GitHub Actions (no static keys)
│       ├── database/rds/             # Amazon RDS PostgreSQL 16
│       ├── eks/                      # Amazon EKS v1.30 & Node Group
│       ├── alb/                      # Application Load Balancer with host-based routing
│       └── secret-manager/           # AWS Secrets Manager
└── gitops/
    └── ecommerce-chart/              # Helm chart for all Kubernetes resources
        ├── Chart.yaml
        ├── values.yaml               # Default values for microservices, Redis, Inngest
        ├── values.prod.yaml          # Production overrides
        └── templates/
            ├── namespace.yaml        # ecommerce namespace
            ├── services.yaml         # Internal ClusterIP services
            ├── deployment-redis.yaml  # In-cluster Redis 7 Alpine
            ├── deployment-inngest.yaml# Self-hosted Inngest server (internal)
            ├── deployments-backend.yaml# api-gateway, catalog, order, payment, users
            ├── deployments-ai.yaml    # agent-service, agent-python
            ├── deployments-frontend.yaml # storefront, admin-dashboard
            └── targetgroup-bindings.yaml # AWS ALB TargetGroupBindings (3 endpoints)
```

---

## 🚀 Step-by-Step Deployment Guide

### Prerequisites

Install the following tools on your machine:
- **AWS CLI v2** ([docs.aws.amazon.com/cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)) — run `aws configure` with your credentials.
- **Terraform v1.9+** ([terraform.io/downloads](https://www.terraform.io/downloads)).
- **kubectl v1.30+** ([kubernetes.io/docs](https://kubernetes.io/docs/tasks/tools/)).
- A registered domain name on **Cloudflare** (e.g. `yourdomain.com`).

---

### Phase 1: Provision AWS Infrastructure (Terraform)

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars`:
   ```hcl
   project = {
     name       = "ecommerce"
     env        = "prod"
     region     = "ap-southeast-1"
     account_id = "123456789012"            # Your 12-digit AWS Account ID
     domain     = "yourdomain.com"          # Your registered domain
     admin_user = "your-iam-username"       # Your AWS IAM username
   }

   # IMPORTANT: Replace 'your-github-username' with your actual GitHub username!
   github_repositories = [
     "your-github-username/ecommerce-backend",
     "your-github-username/-E-commerce",
     "your-github-username/dashboard-admin-ecommern"
   ]
   ```

3. Initialize and provision:
   ```bash
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. Note down the outputs printed in your terminal:
   - `github_actions_role_arn`: Used in GitHub Secrets.
   - `alb_dns_name`: Used in Cloudflare DNS.
   - `rds_endpoint`: PostgreSQL endpoint hostname.

---

### Phase 2: Connect to Your EKS Cluster

```bash
# Update local kubeconfig to connect to EKS
aws eks update-kubeconfig --region ap-southeast-1 --name ecommerce

# Verify nodes are ready
kubectl get nodes -o wide
```
*Expected: 2 nodes in `Ready` status.*

---

### Phase 3: Setup Cluster Secrets & In-Cluster Services

In Kubernetes, environment variables are managed securely via Secrets rather than a plain `.env` file.

1. **Create the Namespace**:
   ```bash
   kubectl create namespace ecommerce || true
   ```

2. **Create Kubernetes Secrets (`ecommerce-secrets`)**:
   This secret acts as the production `.env` for all microservices in the cluster. Replace placeholders with your real values:
   ```bash
   kubectl create secret generic ecommerce-secrets -n ecommerce \
     --from-literal=DATABASE_URL="postgresql://postgres:<RDS_PASSWORD>@<RDS_ENDPOINT>:5432/ecommerce?schema=public" \
     --from-literal=STRIPE_SECRET_KEY="sk_test_..." \
     --from-literal=STRIPE_WEBHOOK_SECRET="whsec_..." \
     --from-literal=CLERK_PUBLISHABLE_KEY="pk_test_..." \
     --from-literal=CLERK_SECRET_KEY="sk_test_..." \
     --from-literal=CLERK_JWT_KEY="-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----" \
     --from-literal=CLERK_AUTHORIZED_PARTIES="https://store.yourdomain.com,https://admin.yourdomain.com" \
     --from-literal=CLERK_WEBHOOK_SIGNING_SECRET="whsec_..." \
     --from-literal=INNGEST_EVENT_KEY="inngest-event-key" \
     --from-literal=INNGEST_SIGNING_KEY="inngest-signing-key" \
     --from-literal=OPENAI_API_KEY=""
   ```

3. **Deploy In-Cluster Redis & Inngest**:
   ```bash
   kubectl apply -f ../gitops/ecommerce-chart/templates/deployment-redis.yaml
   kubectl apply -f ../gitops/ecommerce-chart/templates/deployment-inngest.yaml

   # Verify pods are running
   kubectl get pods -n ecommerce
   ```

---

### Phase 4: Configure Cloudflare DNS & Zero Trust

Only **3 CNAME records** are needed (Inngest and internal services remain completely private):

1. **DNS CNAME Records**:
   In your Cloudflare DNS dashboard for `yourdomain.com`, add 3 CNAME records pointing to your ALB DNS name (`<alb_dns_name>`):
   - `store` → `<alb_dns_name>` (Proxy status: **Proxied 🟧**)
   - `api` → `<alb_dns_name>` (Proxy status: **Proxied 🟧**)
   - `admin` → `<alb_dns_name>` (Proxy status: **Proxied 🟧**)

2. **SSL Mode**:
   Go to **SSL/TLS** → Select **Flexible** mode (Cloudflare provides HTTPS to visitors; ALB receives HTTP on port 80).

3. **Zero Trust Access (Admin Backoffice Protection)**:
   Go to Cloudflare **Zero Trust** → **Access** → **Applications** → **Add an application**:
   - Type: **Self-hosted**
   - Application Name: `Admin Backoffice`
   - Application Domain: `admin.yourdomain.com`
   - Policy: Action `Allow`, Rule: Include `Emails` → enter your administrator email.
   - *Result: Anyone opening `admin.yourdomain.com` must enter a 6-digit email OTP PIN before accessing the application.*

---

### Phase 5: Configure GitHub Actions Secrets

In each of your 3 application repositories, go to **Settings** > **Secrets and variables** > **Actions** > **New repository secret**:

#### 1. Repository: `ecommerce-backend`
- `AWS_ROLE_ARN`: `arn:aws:iam::<YOUR_ACCOUNT_ID>:role/prod-ecommerce-github-actions-role`

#### 2. Repository: `-E-commerce` (Storefront)
- `AWS_ROLE_ARN`: `arn:aws:iam::<YOUR_ACCOUNT_ID>:role/prod-ecommerce-github-actions-role`
- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`: `pk_test_...`
- `NEXT_PUBLIC_API_URL`: `/api/backend`
- `NEXT_PUBLIC_ADMIN_DASHBOARD_URL`: `https://admin.yourdomain.com`

#### 3. Repository: `dashboard-admin-ecommern` (Admin Dashboard)
- `AWS_ROLE_ARN`: *(same as above)*
- `VITE_CLERK_PUBLISHABLE_KEY`: `pk_test_...`
- `VITE_API_BASE_URL`: `https://api.yourdomain.com/v1`
- `VITE_STOREFRONT_URL`: `https://store.yourdomain.com`

---

### Phase 6: Push & Verify Automated Deployment

Commit and push to `main` on any of the 3 repositories. GitHub Actions will automatically:
1. Authenticate to AWS via OIDC (zero static keys).
2. Build multi-stage Docker images and push to Amazon ECR.
3. Connect to Amazon EKS and execute a zero-downtime rolling update (`kubectl rollout restart`).

Verify all 11 pods are running:
```bash
kubectl get pods -n ecommerce
# Expected: All 11 pods in '1/1 Running' status
```

Verify your public endpoints:
- Customer Storefront: `https://store.yourdomain.com`
- Admin Dashboard: `https://admin.yourdomain.com` (OTP prompted)
- API Gateway Health: `https://api.yourdomain.com/health`

---

## 🔧 Operational Commands

```bash
# View live logs of any service
kubectl logs -n ecommerce -l app=api-gateway -f --tail=100
kubectl logs -n ecommerce -l app=order -f --tail=100

# Manually trigger a rolling restart
kubectl rollout restart deployment/<service-name> -n ecommerce

# Access in-cluster Redis directly (local port-forward)
kubectl port-forward svc/redis 6379:6379 -n ecommerce

# Access in-cluster Inngest Dashboard securely (local port-forward)
kubectl port-forward svc/inngest 8288:8288 -n ecommerce
# Open http://localhost:8288 in your browser
```

---

## 🗑️ Infrastructure Teardown & Clean Up

> [!CAUTION]
> Running `terraform destroy` will **permanently delete** all AWS resources (EKS, RDS, VPC, ALB, ECR) and all data. Only perform this when you are completely finished with demonstrations.

```bash
# Step 1: Delete the Kubernetes namespace (releases ALB TargetGroup bindings)
kubectl delete namespace ecommerce --timeout=120s

# Step 2: Destroy all AWS infrastructure via Terraform
cd terraform
terraform destroy -auto-approve
```
