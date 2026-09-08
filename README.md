# ☁️ E-Commerce Cloud DevOps & GitOps Platform

[![AWS EKS](https://img.shields.io/badge/Amazon%20EKS-v1.30-FF9900?logo=amazoneks&logoColor=white)](https://aws.amazon.com/eks/)
[![Terraform](https://img.shields.io/badge/Terraform-v1.9+-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.30-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20OIDC-2088FF?logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![Cloudflare](https://img.shields.io/badge/Edge%20Security-Cloudflare%20Zero%20Trust-F38020?logo=cloudflare&logoColor=white)](https://www.cloudflare.com/)

> **Complete Infrastructure as Code (IaC) & Continuous Delivery Platform** for an enterprise-grade, event-driven E-Commerce microservices ecosystem running on **Amazon Web Services (AWS)** with **Cloudflare Edge SSL & Zero Trust**.

---

## 📑 Table of Contents
- [1. System Architecture](#1-system-architecture)
- [2. The 4 Ecosystem Repositories](#2-the-4-ecosystem-repositories)
- [3. Key Architectural Decisions & Optimizations](#3-key-architectural-decisions--optimizations)
- [4. Cost Breakdown & Budget Management](#4-cost-breakdown--budget-management)
- [5. Repository Structure](#5-repository-structure)
- [6. Complete Step-by-Step Deployment Guide](#6-complete-step-by-step-deployment-guide)
  - [Prerequisites](#prerequisites)
  - [Phase 1: Terraform Infrastructure Provisioning](#phase-1-terraform-infrastructure-provisioning)
  - [Phase 2: EKS Access & Cluster Connectivity](#phase-2-eks-access--cluster-connectivity)
  - [Phase 3: Deploy In-Cluster Services (Redis & Inngest)](#phase-3-deploy-in-cluster-services-redis--inngest)
  - [Phase 4: Cloudflare DNS, SSL & Zero Trust Security](#phase-4-cloudflare-dns-ssl--zero-trust-security)
  - [Phase 5: GitHub Actions CI/CD Configuration](#phase-5-github-actions-cicd-configuration)
  - [Phase 6: Verification & Health Checks](#phase-6-verification--health-checks)
- [7. Operational Runbook & Common Commands](#7-operational-runbook--common-commands)
- [8. Infrastructure Teardown & Clean Up](#8-infrastructure-teardown--clean-up)

---

## 1. System Architecture

```
                                [ End Users & Admins ]
                                          │
                        ┌─────────────────┴─────────────────┐
                        │   Cloudflare Edge Network (SSL)   │
                        │    - store.hieudev.click (Public) │
                        │    - api.hieudev.click (Public)   │
                        │    - admin.hieudev.click (OTP)    │
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
   │ store.tg (3001) │  │ admin.tg (80)│ │ api.tg  │  │ inngest.tg    │
   └────────┬────────┘  └──────┬──────┘  └───┬─────┘  └──────┬────────┘
            │                  │             │               │
════════════╪══════════════════╪═════════════╪═══════════════╪══════════════
AWS VPC     │                  │             │               │
  EKS Cluster: ecommerce (v1.30)             │               │
  Namespace: ecommerce                       │               │
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

## 2. The 4 Ecosystem Repositories

| Repository | Tech Stack | Role & Link |
| :--- | :--- | :--- |
| **DevOps & GitOps** *(This Repo)* | Terraform, Helm, AWS EKS, AWS ECR, Bash | Infrastructure as Code, OIDC authentication, ECR registries, Kubernetes manifests. <br>🔗 [`ecommerce-devops`](https://github.com/Hieuej147/ecommerce-devops.git) |
| **Backend Monorepo** | NestJS 11, gRPC, PostgreSQL, Prisma, Inngest | RESTful API Gateway, 5 gRPC microservices, Python AI agent, Stripe & Clerk webhooks. <br>🔗 [`ecommerce-backend`](https://github.com/Hieuej147/ecommerce-backend.git) |
| **Customer Storefront** | Next.js 16, React 19, Tailwind v4, Three.js | Customer storefront, 3D interactive hero canvas, cart, Stripe checkout, internal proxy. <br>🔗 [`-E-commerce`](https://github.com/Hieuej147/-E-commerce.git) |
| **Admin Dashboard** | React 19, Vite, TypeScript, Cloudflare Zero Trust | Backoffice management, real-time KPI metrics, orders/catalog CRUD, CopilotKit AI. <br>🔗 [`dashboard-admin-ecommern`](https://github.com/Hieuej147/dashboard-admin-ecommern.git) |

---

## 3. Key Architectural Decisions & Optimizations

1. **AWS IAM OIDC for GitHub Actions (Zero Static Keys)**:
   - Traditional setups use long-lived `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` stored in CI/CD secrets (high security liability).
   - This platform implements **AWS IAM OpenID Connect (OIDC)**. GitHub Actions runners assume `arn:aws:iam::<ACCOUNT_ID>:role/prod-ecommerce-github-actions-role` via cryptographic JWT tokens. No credentials are stored.
2. **Lean EKS Cluster Management (Direct GitOps Rollout)**:
   - Rather than running heavy GitOps operators like ArgoCD (which consume >1.2GB RAM across Redis, Repo Server, Application Controller, and Dex), deployments are updated directly by GitHub Actions using `kubectl rollout restart` with rolling zero-downtime Pod replacement.
   - Saves ~$20/month and keeps EKS nodes lean and stable.
3. **Self-Hosted Inngest Server**:
   - Inngest is deployed inside the EKS cluster (`inngest start`) backed by Amazon RDS PostgreSQL and in-cluster Redis for event persistence.
   - Zero external SaaS subscription cost; fully capable of running durable background workflows, retries, and step functions.
4. **Cloudflare Zero Trust Perimeter Defense**:
   - The Admin Dashboard is protected behind Cloudflare Access Edge.
   - Any access to `admin.hieudev.click` requires an email One-Time Passcode (OTP). Unauthorized bots, scanners, and attackers are blocked before their packets ever reach AWS.
5. **In-Cluster Redis 7 (Alpine)**:
   - Replaced managed AWS ElastiCache ($17+/month) with a lightweight, persistent in-cluster Redis Pod, saving 100% of managed caching costs.
6. **Next.js Standalone Mode + Internal Rewrites**:
   - The Storefront uses Next.js standalone output, reducing container image size from 1.2GB to under 180MB.
   - All backend API calls go through internal Next.js rewrites (`/api/backend/*` -> `http://api-gateway:3000/*`), eliminating CORS errors completely.

---

## 4. Cost Breakdown & Budget Management

This infrastructure was designed to fit comfortably within the AWS promotional credit budget ($139.00 credit allocation):

| Service | Configuration / Tier | Estimated Monthly Cost | Notes |
| :--- | :--- | :--- | :--- |
| **Amazon EKS** | 1 Control Plane Cluster | ~$73.00 / month | Standard EKS control plane fee ($0.10/hour). |
| **EKS Node Group** | 2x `t3.small` (2 vCPU, 2GB RAM each) | ~$30.40 / month | Spot/On-Demand Singapore (`ap-southeast-1`). |
| **Amazon RDS PostgreSQL** | 1x `db.t4g.micro` (Single-AZ, 20GB gp3) | ~$17.50 / month | Micro instance hosting all service schemas. |
| **AWS Application Load Balancer** | 1 ALB (Shared by all services) | ~$18.00 / month | Single ALB with host-based rules (avoids paying per-service ALB). |
| **Amazon ECR** | 9 Repositories with Lifecycle Policy | ~$0.10 / month | Lifecycle policy keeps only the latest 2 image tags per repo. |
| **In-Cluster Redis** | Lightweight container on EKS | **$0.00** | Eliminates $17/mo AWS ElastiCache. |
| **Cloudflare Edge SSL & Zero Trust** | Free Plan (Up to 50 users) | **$0.00** | Provides Edge SSL, CDN caching, and OTP firewall. |
| **GitHub Actions Runners** | Public Repositories (Ubuntu-latest) | **$0.00** | Free tier for standard CI/CD builds. |
| **Total Estimated Cost** | | **~$139.00 / month** | Covered by AWS Credits. |

---

## 5. Repository Structure

```
ecommerce-devops/
├── terraform/
│   ├── main.tf                       # Root infrastructure orchestration
│   ├── variable.tf                   # Input variable definitions
│   ├── outputs.tf                    # Generated ARNs, ALB DNS, and Role info
│   ├── provider.tf                   # AWS provider and caller identity
│   ├── version.tf                    # Terraform & provider version constraints
│   ├── terraform.tfvars.example      # Configuration template
│   └── modules/
│       ├── vpc/                      # Multi-AZ VPC, Public/Private subnets, NAT Gateway
│       ├── kms/                      # KMS Customer Managed Keys for encryption
│       ├── ecr/                      # 9 ECR Repositories with 2-image lifecycle policy
│       ├── iam-github-oidc/          # AWS IAM OIDC Provider & GitHub Actions Role
│       ├── database/rds/             # Amazon RDS PostgreSQL 16.15
│       ├── eks/                      # Amazon EKS v1.30 & Node Group (t3.small)
│       ├── alb/                      # Application Load Balancer with Host-Based routing
│       └── secret-manager/           # AWS Secrets Manager
├── gitops/
│   └── ecommerce-chart/              # Kubernetes Helm Manifests
│       ├── Chart.yaml
│       ├── values.yaml               # Config for 9 microservices + Redis + Inngest
│       └── templates/
│           ├── namespace.yaml        # ecommerce namespace
│           ├── services.yaml         # Internal ClusterIP & NodePort services
│           ├── deployment-redis.yaml # In-cluster Redis 7 Alpine cache
│           ├── deployment-inngest.yaml # Self-hosted Inngest Server
│           ├── deployments-backend.yaml# api-gateway, catalog, order, payment, users
│           ├── deployments-ai.yaml   # agent-service, agent-python
│           ├── deployments-frontend.yaml # storefront (Next.js), admin-dashboard (Nginx)
│           ├── ingress.yaml          # Ingress routing rules
│           └── targetgroup-bindings.yaml # AWS ALB TargetGroupBindings
└── scripts/                          # Automated setup and maintenance scripts
```

---

## 6. Complete Step-by-Step Deployment Guide

### Prerequisites
Before running commands, ensure you have the following CLI tools installed:
- **AWS CLI v2** (`aws --version`) configured with your credentials.
- **Terraform v1.9+** (`terraform version`).
- **kubectl v1.30+** (`kubectl version --client`).
- **Helm v3+** (`helm version`).
- A registered domain name on **Cloudflare** (e.g. `hieudev.click`).

---

### Phase 1: Terraform Infrastructure Provisioning

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your AWS details:
   ```hcl
   account_id  = "004285426030"
   admin_user  = "hieubc"
   region      = "ap-southeast-1"
   domain      = "hieudev.click"
   environment = "prod"
   ```

3. Initialize and apply the Terraform configuration:
   ```bash
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. Upon completion, note the important outputs:
   - `github_actions_role_arn`: `arn:aws:iam::<ACCOUNT_ID>:role/prod-ecommerce-github-actions-role`
   - `alb_dns_name`: `prod-ecommerce-alb-xxxx.ap-southeast-1.elb.amazonaws.com`
   - `rds_endpoint`: PostgreSQL endpoint hostname.

---

### Phase 2: EKS Access & Cluster Connectivity

1. Generate your local kubeconfig to connect to the EKS cluster:
   ```bash
   aws eks update-kubeconfig --region ap-southeast-1 --name ecommerce
   ```

2. Verify cluster communication:
   ```bash
   kubectl get nodes -o wide
   ```
   *Expected result: 2 nodes in `Ready` status.*

3. Verify that the GitHub Actions IAM Role has standard Admin Access via EKS Access Entry:
   ```bash
   aws eks list-access-entries --cluster-name ecommerce
   ```

---

### Phase 3: Deploy In-Cluster Services (Redis & Inngest)

1. Create the `ecommerce` namespace:
   ```bash
   kubectl create namespace ecommerce || true
   ```

2. Deploy Redis 7 cache and Inngest Server:
   ```bash
   kubectl apply -f ../gitops/ecommerce-chart/templates/deployment-redis.yaml
   kubectl apply -f ../gitops/ecommerce-chart/templates/deployment-inngest.yaml
   ```

3. Verify Redis and Inngest are running:
   ```bash
   kubectl get pods -n ecommerce -l app=redis
   kubectl get pods -n ecommerce -l app=inngest
   ```

---

### Phase 4: Cloudflare DNS, SSL & Zero Trust Security

1. **DNS CNAME Records**:
   In your Cloudflare DNS Management console for `hieudev.click`, add the following 4 CNAME records:
   - `store` -> `prod-ecommerce-alb-xxxx.ap-southeast-1.elb.amazonaws.com` (Proxy status: **Proxied 🟧**)
   - `api` -> `prod-ecommerce-alb-xxxx.ap-southeast-1.elb.amazonaws.com` (Proxy status: **Proxied 🟧**)
   - `admin` -> `prod-ecommerce-alb-xxxx.ap-southeast-1.elb.amazonaws.com` (Proxy status: **Proxied 🟧**)
   - `inngest` -> `prod-ecommerce-alb-xxxx.ap-southeast-1.elb.amazonaws.com` (Proxy status: **Proxied 🟧**)

2. **Cloudflare SSL Encryption**:
   - Go to **SSL/TLS** -> Select **Flexible** mode.
   - Cloudflare provides free SSL to browsers (`https://`), and communicates with the AWS ALB over Port 80 HTTP.

3. **Cloudflare Zero Trust (Admin Backoffice Protection)**:
   - Open **Zero Trust Dashboard** -> **Access** -> **Applications** -> Click **Add an application**.
   - Select **Self-hosted**.
   - Application Name: `Admin Backoffice`.
   - Domain: `admin.hieudev.click`.
   - Policy: Action `Allow`, Rule: Include `Emails` -> enter your admin email.
   - *Result: Access to `admin.hieudev.click` now requires an email verification PIN.*

---

### Phase 5: GitHub Actions CI/CD Configuration

Configure the required Repository Secrets in each of your 3 GitHub repositories:

#### 1. Repository: `ecommerce-backend`
Navigate to **Settings** > **Secrets and variables** > **Actions** > **New repository secret**:
- `AWS_ROLE_ARN`: `arn:aws:iam::004285426030:role/prod-ecommerce-github-actions-role`

#### 2. Repository: `-E-commerce` (Storefront)
Navigate to **Settings** > **Secrets and variables** > **Actions** > **New repository secret**:
- `AWS_ROLE_ARN`: `arn:aws:iam::004285426030:role/prod-ecommerce-github-actions-role`
- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`: `pk_test_...`
- `NEXT_PUBLIC_API_URL`: `/api/backend`
- `NEXT_PUBLIC_ADMIN_DASHBOARD_URL`: `https://admin.hieudev.click`

#### 3. Repository: `dashboard-admin-ecommern` (Admin Dashboard)
Navigate to **Settings** > **Secrets and variables** > **Actions** > **New repository secret**:
- `AWS_ROLE_ARN`: `arn:aws:iam::004285426030:role/prod-ecommerce-github-actions-role`
- `VITE_CLERK_PUBLISHABLE_KEY`: `pk_test_...`
- `VITE_API_BASE_URL`: `https://api.hieudev.click/v1`
- `VITE_STOREFRONT_URL`: `https://store.hieudev.click`

---

### Phase 6: Verification & Health Checks

Once GitHub Actions completes its automated build and deployment:

1. Check all running Pods in the `ecommerce` namespace:
   ```bash
   kubectl get pods -n ecommerce
   ```
   *Expected: All 11 pods running (`1/1 Running`).*

2. Verify endpoint connectivity:
   - Storefront: `https://store.hieudev.click`
   - Admin Dashboard: `https://admin.hieudev.click`
   - API Gateway Health: `https://api.hieudev.click/health`
   - Inngest Dashboard: `https://inngest.hieudev.click`

---

## 7. Operational Runbook & Common Commands

### View Live Pod Logs
```bash
# API Gateway logs
kubectl logs -n ecommerce -l app=api-gateway -f --tail=100

# Order service logs
kubectl logs -n ecommerce -l app=order -f --tail=100

# Inngest event worker logs
kubectl logs -n ecommerce -l app=inngest -f --tail=100
```

### Manually Restart a Service
```bash
kubectl rollout restart deployment/<service-name> -n ecommerce
kubectl rollout status deployment/<service-name> -n ecommerce
```

### Port Forwarding for Local Debugging
```bash
# Access in-cluster Redis directly
kubectl port-forward svc/redis 6379:6379 -n ecommerce

# Access in-cluster Inngest UI directly
kubectl port-forward svc/inngest 8288:8288 -n ecommerce
```

---

## 8. Infrastructure Teardown & Clean Up

> [!CAUTION]
> Running `terraform destroy` will terminate all AWS resources (EKS Cluster, RDS Database, VPC, Load Balancer) and permanently delete data. Only perform this when you are done demonstrating the project and wish to stop all AWS billing.

### Step 1: Clean up Kubernetes Services & Load Balancers
Before destroying Terraform, delete the Kubernetes namespace to release TargetGroup bindings:
```bash
kubectl delete namespace ecommerce --timeout=120s
```

### Step 2: Destroy Terraform Resources
```bash
cd terraform
terraform destroy -auto-approve
```

### Step 3: Remove ECR Images (Optional)
If any ECR repositories contain images that block deletion:
```bash
for repo in api-gateway catalog order payment users agent-service agent-python storefront admin-dashboard; do
  aws ecr batch-delete-image --repository-name prod-ecommerce-$repo \
    --image-ids "$(aws ecr list-images --repository-name prod-ecommerce-$repo --query 'imageIds[*]' --output json)" 2>/dev/null || true
done
```
