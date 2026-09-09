# 🗺️ Full Deployment Architecture & Network Topology

> This document provides an architectural deep dive into the production deployment topology on AWS, perimeter edge security via Cloudflare Zero Trust, internal gRPC/AG-UI inter-service communication, and automated CI/CD delivery pipelines via GitHub Actions.

---

## I. High-Level Infrastructure Diagram

```mermaid
flowchart TD
    %% ================= CLIENTS & TRAFFIC =================
    subgraph Clients["1. Clients & Internet Traffic"]
        Customer["🛒 Online Shoppers\n(Web Browser / Mobile)"]
        AdminUser["🛡️ Store Administrator\n(Email OTP Verified)"]
        Attacker["🤖 Attackers / Bots / Scanners\n(Vulnerability Probing)"]
    end

    %% ================= PERIMETER SECURITY =================
    subgraph EdgeSecurity["2. Perimeter Edge Security (Cloudflare Global Anycast)"]
        CF_DNS["Cloudflare DNS\n- store.yourdomain.com\n- api.yourdomain.com\n- admin.yourdomain.com"]
        CF_ZT["Cloudflare Zero Trust (Access)\n- Guard admin.yourdomain.com\n- Require 6-digit email OTP challenge\n- 100% Free (Up to 50 users)"]
        CF_Block["⛔ BLOCKED AT EDGE\n(HTTP 403 Forbidden)\nNever reaches AWS!"]
    end

    %% ================= AWS CLOUD INFRASTRUCTURE =================
    subgraph AWS["3. AWS Cloud (Region: ap-southeast-1 Singapore)"]
        subgraph PublicSubnets["Public Subnets (2 Availability Zones)"]
            ALB["AWS Application Load Balancer (ALB)\n- SSL Termination (*.yourdomain.com)\n- HTTP (80) to HTTPS (443) Redirect\n- Host-Based Routing (store., api., admin.)"]
            NAT["NAT Gateway (1 EIP)\nAllows private pods outbound internet access\n(Webhooks, OpenAI, Stripe, Clerk)"]
        end

        subgraph PrivateSubnets["Private Subnets (No Public IPs - 100% Isolated)"]
            subgraph EKS["Amazon EKS Cluster v1.30 (Managed Node Group: 2x-3x Instances)"]
                subgraph Frontends["Frontend Pods Tier"]
                    StorePod["storefront (Port 3001)\nNext.js 16 App Router\nReact 19, Tailwind v4"]
                    AdminPod["admin-dashboard (Port 80)\nReact 19 + Vite SPA\nNginx Alpine Web Server"]
                end

                subgraph Gateway["API Gateway Tier"]
                    GWPod["api-gateway (Port 3000)\nNestJS 11 REST API\n- Clerk Auth Guard & RBAC\n- Stripe & Clerk Webhook Listeners\n- Inngest Event Bus Dispatcher"]
                end

                subgraph Microservices["Microservices Tier (Private ClusterIP)"]
                    CatalogPod["catalog-service (gRPC 5001)\nProduct catalog, categories, inventory"]
                    OrderPod["order-service (gRPC 5002)\nOrder lifecycle, fulfillment, KPI metrics"]
                    PaymentPod["payment-service (gRPC 5003)\nStripe transactions, invoices, refunds"]
                    UsersPod["users-service (gRPC 5004)\nClerk user sync, Admin RBAC"]
                end

                subgraph AIAgent["AI Agent Tier (AG-UI Protocol)"]
                    AgentSvcPod["agent-service (Port 3010)\nNestJS Thread Manager\n- AG-UI Protocol Bridge (SSE)\n- CopilotKit chat session manager"]
                    AgentPyPod["agent-python (Port 8123)\nPython 3.12 FastAPI + LangGraph\n- 7 Query & Action Tools\n- Generative Dynamic UI (A2UI Schema)"]
                end
            end

            subgraph DataPersistence["Data Persistence Tier"]
                RDS[("Amazon RDS PostgreSQL 16.3\n(Port: 5432)\n- Prisma ORM Multi-Schema\n- db.t4g.micro")]
                RedisPod[("In-Cluster Redis 7 Alpine Pod\n(Port: 6379, ClusterIP)\n- AG-UI Run Coordinator & Cache\n- Zero SaaS Cost")]
            end
        end

        subgraph SecurityRegistries["Security & Registries Tier"]
            ECR["Amazon ECR (9 Private Repositories)\n- api-gateway, catalog, order, payment, users\n- agent-service, agent-python\n- storefront, admin-dashboard"]
            KMS["AWS KMS\nCustomer Managed Key (Database & ECR Encryption)"]
            OIDC["AWS IAM OIDC Provider\n(token.actions.githubusercontent.com)\nPasswordless ECR & EKS access for GitHub Actions"]
        end
    end

    %% ================= EXTERNAL 3RD-PARTY SERVICES =================
    subgraph ThirdParties["4. External SaaS Integrations"]
        Clerk["🔐 Clerk Authentication\n- Google OAuth & Email Login\n- Webhook sync: POST /v1/webhooks/clerk"]
        Stripe["💳 Stripe Payments\n- PaymentIntents & Checkout\n- Webhook sync: POST /v1/payments/webhook/stripe"]
        OpenAI["🧠 OpenAI API\n(gpt-4o-mini via API Key)"]
    end

    %% ================= CONNECTIONS & FLOW =================
    Customer -->|store.yourdomain.com| CF_DNS --> ALB
    AdminUser -->|admin.yourdomain.com| CF_ZT -->|Valid Email OTP| CF_DNS --> ALB
    Attacker -->|Probe admin.yourdomain.com| CF_ZT -->|NO OTP / UNAUTHORIZED| CF_Block

    ALB -->|Host: store.*| StorePod
    ALB -->|Host: admin.*| AdminPod
    ALB -->|Host: api.*| GWPod

    StorePod -->|Next.js Internal Rewrite /api/backend| GWPod
    AdminPod -->|REST API Calls| GWPod
    AdminPod <==>|AG-UI Protocol / SSE Stream| AgentSvcPod

    GWPod -->|gRPC 5001 / HTTP2| CatalogPod
    GWPod -->|gRPC 5002 / HTTP2| OrderPod
    GWPod -->|gRPC 5003 / HTTP2| PaymentPod
    GWPod -->|gRPC 5004 / HTTP2| UsersPod
    GWPod -->|HTTP REST / 3010| AgentSvcPod

    AgentSvcPod <==>|HTTP LangGraph / 8123| AgentPyPod
    AgentPyPod -.->|Call LLM via NAT Gateway| OpenAI

    CatalogPod & OrderPod & PaymentPod & UsersPod & AgentSvcPod -->|TCP 5432| RDS
    AgentSvcPod -->|TCP 6379| RedisPod

    GWPod -.->|Verify JWT & Webhook| Clerk
    PaymentPod -.->|Validate Payments via NAT| Stripe
```

---

## II. Network Protocol Matrix

| Communication Flow | Source | Destination | Protocol / Port | Technical Purpose & Characteristics |
| :--- | :--- | :--- | :--- | :--- |
| **Storefront Web** | User Browser | Cloudflare Edge ➔ ALB | HTTPS / Port 443 | Serves Next.js 16 SSR pages and assets to shoppers |
| **Admin Backoffice** | Admin Browser | Cloudflare Zero Trust | HTTPS / Port 443 | Edge firewall gate requiring 6-digit email OTP verification |
| **API Gateway Ingress**| Web / Webhooks | ALB ➔ Pod `api-gateway` | HTTP / Port 3000 | Public RESTful API routing, Clerk JWT validation, CORS proxy |
| **Catalog gRPC** | Pod `api-gateway` | Pod `catalog-service` | **gRPC (HTTP/2) / 5001** | Sub-millisecond product queries, categories, stock levels |
| **Order gRPC** | Pod `api-gateway` | Pod `order-service` | **gRPC (HTTP/2) / 5002** | Order placement, state transitions, customer history |
| **Payment gRPC** | Pod `api-gateway` | Pod `payment-service` | **gRPC (HTTP/2) / 5003** | Stripe Checkout session creation, webhooks, refund processing |
| **Users gRPC** | Pod `api-gateway` | Pod `users-service` | **gRPC (HTTP/2) / 5004** | Clerk user profile synchronization, Admin RBAC management |
| **AG-UI Event Stream**| Admin Dashboard | Pod `agent-service` | **AG-UI / SSE (Port 3010)** | Real-time chat streaming and generative A2UI dynamic schema |
| **LangGraph Engine** | Pod `agent-service`| Pod `agent-python` | HTTP / Port 8123 | Executes LangGraph state graph with 7 enterprise tool bindings |
| **Database Connection**| Microservices | Amazon RDS | TCP / Port 5432 | Prisma ORM connecting to PostgreSQL 16 multi-schema database |
| **Cache Connection** | Agent Service | In-Cluster Redis Pod | TCP / Port 6379 | Redis 7 Alpine in-memory store for AG-UI session coordinating ($0) |

---

## III. Automated CI/CD Delivery Pipeline

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Developer
    participant GH as GitHub Repositories (Backend, Store, Admin)
    participant GHA as GitHub Actions Runner (OIDC)
    participant ECR as Amazon ECR (9 Repositories)
    participant EKS as Amazon EKS (Kubernetes Cluster)
    participant Pods as Kubernetes Pods (Rollout Restart)

    Dev->>GH: git push origin main
    GH->>GHA: Trigger CI/CD Workflow
    GHA->>GHA: Run Unit Tests & Build TypeScript
    GHA->>GHA: Authenticate to AWS via IAM OIDC (Zero static keys)
    GHA->>ECR: Build Multi-stage Docker & Push image tags (SHA commit & latest)
    GHA->>EKS: Connect to EKS via IAM Access Entry & trigger rollout
    EKS->>ECR: Pull newly pushed Docker image
    EKS->>Pods: Perform zero-downtime rolling update (RollingUpdate)
    Pods-->>Dev: Deployment complete with zero service disruption!
```

---

## IV. Security Perimeter & Access Boundaries

1. **Edge Perimeter (Cloudflare Global Network)**:
   - All inbound internet traffic must transit through Cloudflare's Anycast edge network.
   - The `admin.yourdomain.com` endpoint is guarded by **Cloudflare Zero Trust Access**: Unauthorized visitors and automated bot scanners are terminated at the nearest Cloudflare edge PoP with `403 Forbidden` before packets ever reach AWS.
2. **Public Network Boundary (AWS Public Subnets)**:
   - Only the **Application Load Balancer (ALB)** and **NAT Gateway** possess public IP addresses.
   - The ALB exposes only port `80` (redirects to 443) and `443` (encrypted HTTPS using ACM wildcard certificates).
3. **Private Network Boundary (AWS Private Subnets)**:
   - All Microservices pods, Amazon RDS PostgreSQL, and In-Cluster Redis reside in private subnets with **no public IPs**.
   - Direct external inbound connection to database instances or internal gRPC ports is architecturally impossible.
4. **Cloud Authentication Boundary (AWS IAM OIDC)**:
   - GitHub Actions connects to AWS using short-lived OpenID Connect (OIDC) Web Identity Tokens.
   - No permanent `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` credentials are saved on GitHub, eliminating credential leak risks.
