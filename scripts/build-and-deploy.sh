#!/usr/bin/env bash
set -euo pipefail

export DOCKER_BUILDKIT=0

REGISTRY="004285426030.dkr.ecr.ap-southeast-1.amazonaws.com"
REGION="ap-southeast-1"

echo "========================================================"
echo "🚀 STEP 1: Login Docker to AWS ECR (${REGION})"
echo "========================================================"
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${REGISTRY}"

echo ""
echo "========================================================"
echo "📦 STEP 2: Build & Push Backend Microservices"
echo "========================================================"
cd /mnt/disk3/Microservice-E-Commerce

SERVICES=("catalog" "order" "payment" "users" "agent-service" "api-gateway")

for SVC in "${SERVICES[@]}"; do
  echo "--> Building ${SVC}..."
  docker build \
    --build-arg APP_NAME="${SVC}" \
    -t "${REGISTRY}/prod-ecommerce-${SVC}:latest" .
  echo "--> Pushing ${SVC} to ECR..."
  docker push "${REGISTRY}/prod-ecommerce-${SVC}:latest"
done

echo "--> Building & Pushing Python AI Agent..."
cd /mnt/disk3/Microservice-E-Commerce/agent-python
docker build -t "${REGISTRY}/prod-ecommerce-agent-python:latest" .
docker push "${REGISTRY}/prod-ecommerce-agent-python:latest"

echo ""
echo "========================================================"
echo "🎨 STEP 3: Build & Push Customer Storefront (Next.js 16)"
echo "========================================================"
cd /mnt/disk3/E-commerce
docker build \
  --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="${NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY:-}" \
  --build-arg NEXT_PUBLIC_API_URL="https://api.hieudev.click" \
  --build-arg NEXT_PUBLIC_ADMIN_DASHBOARD_URL="https://admin.hieudev.click" \
  --build-arg BACKEND_API_URL="http://api-gateway:3000" \
  -t "${REGISTRY}/prod-ecommerce-storefront:latest" .
docker push "${REGISTRY}/prod-ecommerce-storefront:latest"

echo ""
echo "========================================================"
echo "🛡️ STEP 4: Build & Push Admin Dashboard (React Vite)"
echo "========================================================"
cd /mnt/disk3/dashboard-admin-ecommern
docker build \
  --build-arg VITE_CLERK_PUBLISHABLE_KEY="${VITE_CLERK_PUBLISHABLE_KEY:-}" \
  --build-arg VITE_API_BASE_URL="https://api.hieudev.click/v1" \
  --build-arg VITE_STOREFRONT_URL="https://store.hieudev.click" \
  -t "${REGISTRY}/prod-ecommerce-admin-dashboard:latest" .
docker push "${REGISTRY}/prod-ecommerce-admin-dashboard:latest"

echo ""
echo "========================================================"
echo "☸️ STEP 5: Deploy All Microservices to AWS EKS"
echo "========================================================"
helm upgrade --install ecommerce /mnt/disk3/ecommerce-devops/gitops/ecommerce-chart \
  -f /mnt/disk3/ecommerce-devops/gitops/ecommerce-chart/values.prod.yaml \
  -n ecommerce \
  --create-namespace

echo ""
echo "========================================================"
echo "✅ DEPLOYMENT COMPLETE! Verifying running pods:"
echo "========================================================"
kubectl get pods -n ecommerce -o wide
