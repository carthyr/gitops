#!/bin/bash

# DevOps Toolkit Stack Deployment Script
# This script deploys the complete DevOps AI Toolkit stack with proper dependency ordering

set -e

echo "🚀 DevOps Toolkit Stack Deployment"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if namespace exists
if ! kubectl get namespace devops-toolkit &> /dev/null; then
    echo -e "${YELLOW}Creating namespace devops-toolkit...${NC}"
    kubectl create namespace devops-toolkit
fi

# Check for required secrets
echo ""
echo "Checking required secrets..."
echo "----------------------------"

if ! kubectl get secret dot-ai-secrets -n devops-toolkit &> /dev/null; then
    echo -e "${RED}❌ Secret 'dot-ai-secrets' not found!${NC}"
    echo ""
    echo "Create it with:"
    echo "  export DOT_AI_AUTH_TOKEN=\$(openssl rand -base64 32)"
    echo "  export ANTHROPIC_API_KEY=\"sk-ant-api03-...\""
    echo "  export OPENAI_API_KEY=\"sk-proj-...\""
    echo ""
    echo "  kubectl create secret generic dot-ai-secrets \\"
    echo "    --namespace devops-toolkit \\"
    echo "    --from-literal=auth-token=\"\$DOT_AI_AUTH_TOKEN\" \\"
    echo "    --from-literal=anthropic-api-key=\"\$ANTHROPIC_API_KEY\" \\"
    echo "    --from-literal=openai-api-key=\"\$OPENAI_API_KEY\""
    exit 1
else
    echo -e "${GREEN}✓ dot-ai-secrets found${NC}"
fi

if ! kubectl get secret dot-ai-ui-secrets -n devops-toolkit &> /dev/null; then
    echo -e "${RED}❌ Secret 'dot-ai-ui-secrets' not found!${NC}"
    echo ""
    echo "Create it with:"
    echo "  export DOT_AI_UI_AUTH_TOKEN=\$(openssl rand -base64 32)"
    echo ""
    echo "  kubectl create secret generic dot-ai-ui-secrets \\"
    echo "    --namespace devops-toolkit \\"
    echo "    --from-literal=ui-auth-token=\"\$DOT_AI_UI_AUTH_TOKEN\""
    exit 1
else
    echo -e "${GREEN}✓ dot-ai-ui-secrets found${NC}"
fi

# Deploy ArgoCD Applications
echo ""
echo "Deploying ArgoCD Applications..."
echo "--------------------------------"

echo -e "${YELLOW}1. Deploying DevOps Toolkit MCP Server...${NC}"
kubectl apply -f apps/devops-toolkit/devops-toolkit-app.yaml
echo -e "${GREEN}✓ DevOps Toolkit MCP Server application created${NC}"

echo -e "${YELLOW}2. Deploying DevOps Toolkit Controller...${NC}"
kubectl apply -f apps/devops-toolkit-controller/devops-toolkit-controller-app.yaml
echo -e "${GREEN}✓ DevOps Toolkit Controller application created${NC}"

echo -e "${YELLOW}3. Deploying DevOps Toolkit Web UI...${NC}"
kubectl apply -f apps/devops-toolkit-ui/devops-toolkit-ui-app.yaml
echo -e "${GREEN}✓ DevOps Toolkit Web UI application created${NC}"

# Wait for MCP server to be ready
echo ""
echo "Waiting for MCP Server to be ready..."
echo "--------------------------------------"
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=dot-ai \
    -n devops-toolkit \
    --timeout=300s || echo -e "${YELLOW}⚠ Timeout waiting for MCP server, continuing...${NC}"

# Deploy HTTPRoutes
echo ""
echo "Deploying HTTPRoutes..."
echo "-----------------------"

echo -e "${YELLOW}1. Creating HTTPRoute for MCP Server...${NC}"
kubectl apply -f apps/gateway-api/httproute-devops-toolkit.yaml
echo -e "${GREEN}✓ HTTPRoute for MCP Server created${NC}"

echo -e "${YELLOW}2. Creating HTTPRoute for Web UI...${NC}"
kubectl apply -f apps/gateway-api/httproute-devops-toolkit-ui.yaml
echo -e "${GREEN}✓ HTTPRoute for Web UI created${NC}"

# Wait for controller to be ready
echo ""
echo "Waiting for Controller to be ready..."
echo "--------------------------------------"
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=dot-ai-controller \
    -n devops-toolkit \
    --timeout=300s || echo -e "${YELLOW}⚠ Timeout waiting for controller, continuing...${NC}"

# Deploy Controller CRD configurations
echo ""
echo "Deploying Controller CRD configurations..."
echo "------------------------------------------"

echo -e "${YELLOW}1. Creating ResourceSyncConfig...${NC}"
kubectl apply -f apps/devops-toolkit-controller/manifests/resource-sync-config.yaml
echo -e "${GREEN}✓ ResourceSyncConfig created${NC}"

echo -e "${YELLOW}2. Creating CapabilityScanConfig...${NC}"
kubectl apply -f apps/devops-toolkit-controller/manifests/capability-scan-config.yaml
echo -e "${GREEN}✓ CapabilityScanConfig created${NC}"

# Summary
echo ""
echo "🎉 Deployment Complete!"
echo "======================"
echo ""
echo "Check deployment status:"
echo "  kubectl get application -n argocd | grep devops-toolkit"
echo "  kubectl get pods -n devops-toolkit"
echo "  kubectl get httproute -n devops-toolkit"
echo ""
echo "Access URLs:"
echo "  MCP Server: https://devops-toolkit.technovise.local"
echo "  Web UI:     https://devops-toolkit-ui.technovise.local"
echo ""
echo "Test MCP Server:"
echo "  curl -H 'Authorization: Bearer \$DOT_AI_AUTH_TOKEN' https://devops-toolkit.technovise.local/healthz"
echo ""
echo "Retrieve UI Auth Token:"
echo "  kubectl get secret dot-ai-ui-secrets -n devops-toolkit -o jsonpath='{.data.ui-auth-token}' | base64 -d"
echo ""
