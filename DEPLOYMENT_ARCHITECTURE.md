# 🗺️ TỔNG QUAN KIẾN TRÚC TOÀN BỘ HỆ THỐNG KHI DEPLOY (DEPLOYMENT ARCHITECTURE)

> Tài liệu này mô tả chi tiết sơ đồ luồng dữ liệu, phân tầng hạ tầng mạng trên AWS, cơ chế bảo vệ cổng Admin bằng Cloudflare Zero Trust, luồng giao tiếp gRPC/AG-UI giữa các microservices và quy trình tự động hóa CI/CD qua GitHub Actions.

---

## I. SƠ ĐỒ KIẾN TRÚC TỔNG THỂ (HIGH-LEVEL INFRASTRUCTURE DIAGRAM)

```mermaid
flowchart TD
    %% ================= CLIENTS & TRAFFIC =================
    subgraph Clients["1. Clients & Internet Traffic"]
        Customer["🛒 Khách hàng Mua sắm\n(Web Browser / Mobile)"]
        AdminUser["🛡️ Quản trị viên (Admin)\n(Email xác thực OTP)"]
        Attacker["🤖 Kẻ tấn công / Bots / Scanners\n(Mò quét lỗ hổng)"]
    end

    %% ================= PERIMETER SECURITY =================
    subgraph EdgeSecurity["2. Perimeter Edge Security (Cloudflare Global Anycast)"]
        CF_DNS["Cloudflare DNS\n- store.yourdomain.com\n- api.yourdomain.com\n- admin.yourdomain.com"]
        CF_ZT["Cloudflare Zero Trust (Access)\n- Chặn cửa ngõ admin.yourdomain.com\n- Bắt buộc nhập mã OTP 6 số qua Email\n- Miễn phí 100% (Up to 50 users)"]
        CF_Block["⛔ CHẶN ĐỨNG NGAY TẠI EDGE\n(HTTP 403 Forbidden)\nKhông chạm được tới AWS!"]
    end

    %% ================= AWS CLOUD INFRASTRUCTURE =================
    subgraph AWS["3. AWS Cloud (Region: ap-southeast-1 Singapore)"]
        subgraph PublicSubnets["Public Subnets (2 Availability Zones)"]
            ALB["AWS Application Load Balancer (ALB)\n- Wildcard SSL (*.yourdomain.com) qua ACM\n- Redirect HTTP (80) ➔ HTTPS (443)\n- Host-Based Routing (store., api., admin.)"]
            NAT["NAT Gateway (1 EIP)\nCho phép Private Pods gọi ra ngoài Internet\n(Gửi Webhook, gọi OpenAI, Stripe, Clerk)"]
        end

        subgraph PrivateSubnets["Private Subnets (Không có Public IP - Bảo mật 100%)"]
            subgraph EKS["Amazon EKS Cluster v1.30 (Managed Node Group: 2x Spot Instances)"]
                subgraph Frontends["Tầng Giao Diện (Frontend Pods)"]
                    StorePod["storefront (Port 3001)\nNext.js 16 App Router\nReact 19, Tailwind v4"]
                    AdminPod["admin-dashboard (Port 80)\nReact 19 + Vite SPA\nNginx Alpine Web Server"]
                end

                subgraph Gateway["Tầng Cửa Ngõ (API Gateway Pod)"]
                    GWPod["api-gateway (Port 3000)\nNestJS 11 REST API\n- Clerk Auth Guard & RBAC\n- Stripe & Clerk Webhook Listeners\n- Inngest Event Bus Dispatcher"]
                end

                subgraph Microservices["Tầng Nghiệp Vụ Microservices (Private ClusterIP)"]
                    CatalogPod["catalog-service (gRPC 5001)\nQuản lý sản phẩm, danh mục, tồn kho"]
                    OrderPod["order-service (gRPC 5002)\nQuản lý đơn hàng, quy trình xử lý"]
                    PaymentPod["payment-service (gRPC 5003)\nGiao dịch Stripe, hóa đơn, hoàn tiền"]
                    UsersPod["users-service (gRPC 5004)\nĐồng bộ user Clerk, phân quyền Admin"]
                end

                subgraph AIAgent["Tầng AI Agent (AG-UI Protocol)"]
                    AgentSvcPod["agent-service (Port 3010)\nNestJS Thread Manager\n- AG-UI Protocol Bridge (SSE)\n- Quản lý session chat CopilotKit"]
                    AgentPyPod["agent-python (Port 8123)\nPython 3.12 FastAPI + LangGraph\n- 7 Tools truy vấn DB & Microservices\n- Sinh Generative UI (A2UI Schema)"]
                end
            end

            subgraph DataPersistence["Tầng Lưu Trữ Dữ Liệu (Data Tier)"]
                RDS[("Amazon RDS PostgreSQL 16.3\n(Engine: postgres, Port: 5432)\n- Prisma ORM Data Storage\n- db.t4g.micro (Free Tier)")]
                RedisPod[("In-Cluster Redis 7 Alpine Pod\n(Port: 6379, ClusterIP)\n- AG-UI Run Coordinator & Cache\n- 100% Miễn phí ($0/tháng)")]
            end
        end

        subgraph SecurityRegistries["Tầng Quản Trị & Đăng Ký (Security & ECR)"]
            ECR["Amazon ECR (9 Private Repositories)\n- api-gateway, catalog, order, payment, users\n- agent-service, agent-python\n- storefront, admin-dashboard"]
            KMS["AWS KMS\nCustomer Managed Key (Mã hóa toàn bộ DB & ECR)"]
            OIDC["AWS IAM OIDC Provider\n(token.actions.githubusercontent.com)\nCấp quyền push ECR cho GitHub Actions"]
        end
    end

    %% ================= EXTERNAL 3RD-PARTY SERVICES =================
    subgraph ThirdParties["4. Dịch vụ bên thứ ba (External SaaS)"]
        Clerk["🔐 Clerk Authentication\n- Google OAuth & Email Login\n- Webhook sync user: POST /v1/webhooks/clerk"]
        Stripe["💳 Stripe Payments\n- PaymentIntents & Checkout\n- Webhook sync: POST /v1/payments/webhook/stripe"]
        OpenAI["🧠 OpenAI / Gemini API\n(gpt-4o-mini qua API Key)"]
    end

    %% ================= CONNECTIONS & FLOW =================
    Customer -->|store.yourdomain.com| CF_DNS --> ALB
    AdminUser -->|admin.yourdomain.com| CF_ZT -->|Nhập đúng mã OTP Email| CF_DNS --> ALB
    Attacker -->|Quét dò admin.yourdomain.com| CF_ZT -->|KHÔNG CÓ MÃ OTP| CF_Block

    ALB -->|Host: store.*| StorePod
    ALB -->|Host: admin.*| AdminPod
    ALB -->|Host: api.*| GWPod

    StorePod -->|Next.js Rewrite Internal| GWPod
    AdminPod -->|REST API Calls| GWPod
    AdminPod <==>|AG-UI Protocol / SSE Stream| AgentSvcPod

    GWPod -->|gRPC 5001 / HTTP2| CatalogPod
    GWPod -->|gRPC 5002 / HTTP2| OrderPod
    GWPod -->|gRPC 5003 / HTTP2| PaymentPod
    GWPod -->|gRPC 5004 / HTTP2| UsersPod
    GWPod -->|HTTP REST / 3010| AgentSvcPod

    AgentSvcPod <==>|HTTP LangGraph / 8123| AgentPyPod
    AgentPyPod -.->|Gọi LLM qua NAT Gateway| OpenAI

    CatalogPod & OrderPod & PaymentPod & UsersPod & AgentSvcPod -->|TCP 5432| RDS
    AgentSvcPod -->|TCP 6379| RedisPod

    GWPod -.->|Verify JWT & Webhook| Clerk
    PaymentPod -.->|Xác thực thanh toán qua NAT| Stripe
```

---

## II. BẢNG CHI TIẾT GIAO THỨC & CỔNG KẾT NỐI (NETWORK PROTOCOL MATRIX)

| Luồng giao tiếp | Nguồn (Source) | Đích (Destination) | Giao thức / Port | Mục đích & Đặc tính kỹ thuật |
| :--- | :--- | :--- | :--- | :--- |
| **Storefront Web** | Trình duyệt khách | Cloudflare Edge ➔ ALB | HTTPS / Port 443 | Tải mã nguồn SSR Next.js 16, hiển thị giao diện mua sắm |
| **Admin Backoffice** | Trình duyệt Admin | Cloudflare Zero Trust | HTTPS / Port 443 | Chặn cửa ngõ tại Edge, yêu cầu mã OTP email |
| **API Gateway Ingress**| Web / Webhook | ALB ➔ Pod `api-gateway` | HTTP / Port 3000 | Định tuyến các request REST API công khai |
| **Catalog gRPC** | Pod `api-gateway` | Pod `catalog-service` | **gRPC (HTTP/2) / 5001** | Truy vấn kho hàng, danh mục sản phẩm (< 5ms) |
| **Order gRPC** | Pod `api-gateway` | Pod `order-service` | **gRPC (HTTP/2) / 5002** | Tạo đơn hàng, cập nhật trạng thái đơn |
| **Payment gRPC** | Pod `api-gateway` | Pod `payment-service` | **gRPC (HTTP/2) / 5003** | Khởi tạo phiên Stripe Checkout, xử lý hoàn tiền |
| **Users gRPC** | Pod `api-gateway` | Pod `users-service` | **gRPC (HTTP/2) / 5004** | Đồng bộ tài khoản Clerk, gán quyền Admin |
| **AG-UI Event Stream**| Admin Dashboard | Pod `agent-service` | **AG-UI / SSE (Port 3010)** | Stream sự kiện chat và sinh giao diện động A2UI |
| **LangGraph Engine** | Pod `agent-service`| Pod `agent-python` | HTTP / Port 8123 | Thực thi LangGraph graph và 7 tools nghiệp vụ |
| **Database Connection**| Các Microservices | Amazon RDS | TCP / Port 5432 | Prisma ORM giao tiếp với PostgreSQL 16 |
| **Cache Connection** | Agent Service | In-Cluster Redis Pod | TCP / Port 6379 | Bộ nhớ tạm Redis 7 Alpine cho AG-UI Run Coordinator ($0) |

---

## III. QUY TRÌNH TỰ ĐỘNG HÓA CI/CD (DELIVERY PIPELINE)

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Lập trình viên
    participant GH as GitHub Repositories (Backend, Store, Admin)
    participant GHA as GitHub Actions Runner (OIDC)
    participant ECR as Amazon ECR (9 Repositories)
    participant EKS as Amazon EKS (Kubernetes Cluster)
    participant Pods as Kubernetes Pods (Rollout Restart)

    Dev->>GH: git push origin main
    GH->>GHA: Kích hoạt CI/CD Workflow
    GHA->>GHA: Chạy kiểm thử Unit Tests & Build TypeScript
    GHA->>GHA: Xác thực với AWS qua IAM OIDC (Không cần mật khẩu)
    GHA->>ECR: Build Docker Multi-stage & Push image tag (SHA commit & latest)
    GHA->>EKS: Kết nối EKS qua Access Entry & trigger rollout
    EKS->>ECR: Kéo Docker image mới về
    EKS->>Pods: Thực hiện Rolling Update (Zero-Downtime)
    Pods-->>Dev: Hệ thống cập nhật bản mới thành công 100%!
```

---

## IV. BẢN ĐỒ BẢO MẬT & PHÂN QUYỀN (SECURITY PERIMETER)

1. **Vành đai ngoài cùng (Edge Perimeter)**:
   - Toàn bộ lưu lượng truy cập phải đi qua mạng lưới Cloudflare.
   - Domain `admin.yourdomain.com` được bảo vệ bằng **Cloudflare Zero Trust Access**: Người ngoài hoặc bot quét cổng bị chặn đứng 100% với mã `403 Forbidden` ngay tại máy chủ biên gần nhất của Cloudflare trước khi gói tin chạm đến AWS.
2. **Vành đai mạng công cộng (AWS Public Subnet)**:
   - Chỉ duy nhất **Application Load Balancer (ALB)** và **NAT Gateway** có Public IP.
   - ALB chỉ mở 2 cổng `80` (tự động redirect sang 443) và `443` (mã hóa SSL HTTPS với chứng chỉ wildcard ACM `*.yourdomain.com`).
3. **Vành đai mạng nội bộ (AWS Private Subnet)**:
   - Toàn bộ các Pod Microservices, Database RDS PostgreSQL và In-Cluster Redis **hoàn toàn KHÔNG có Public IP**.
   - Hacker trên Internet không có bất kỳ cách nào kết nối trực tiếp vào Database hoặc các Pod gRPC.
4. **Vành đai phân quyền Cloud (AWS IAM OIDC)**:
   - GitHub Actions kết nối tới AWS bằng chứng chỉ ngắn hạn (Ephemeral Web Identity Token) thông qua OpenID Connect.
   - Không lưu trữ bất kỳ `AWS_ACCESS_KEY_ID` tĩnh nào trên GitHub, triệt tiêu hoàn toàn nguy cơ lộ khóa API.
