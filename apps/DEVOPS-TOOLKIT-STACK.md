# DevOps Toolkit Stack - GitOps Installation

Complete DevOps AI Toolkit stack adapted for your GitOps workflow with Istio Gateway API.

## Components

This installation includes all three components of the DevOps AI Toolkit stack:

### 1. DevOps AI Toolkit (MCP Server)
- **Directory**: `apps/devops-toolkit/`
- **Access**: https://devops-toolkit.technovise.local
- **Purpose**: AI-powered Kubernetes operations via MCP protocol
- **Features**: Query, Remediate, Operate, Recommend tools

### 2. DevOps Toolkit Controller
- **Directory**: `apps/devops-toolkit-controller/`
- **Access**: Internal (no ingress)
- **Purpose**: Resource tracking, event remediation, semantic search
- **Features**: Solution CRD, RemediationPolicy, ResourceSyncConfig, CapabilityScanConfig

### 3. DevOps Toolkit Web UI
- **Directory**: `apps/devops-toolkit-ui/`
- **Access**: https://devops-toolkit-ui.technovise.local
- **Purpose**: Visual cluster management and AI operations
- **Features**: Dashboard, resource browser, AI action bar, visualizations

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Gateway API (technovise-gateway)                │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  HTTPS Listener (port 443) → *.technovise.local      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                    │                    │
        ┌───────────┴──────┐   ┌────────┴────────┐
        │                  │   │                  │
┌───────▼──────┐   ┌───────▼──────┐   ┌──────────▼─────────┐
│  dot-ai MCP  │◄──│  dot-ai-ui   │   │  dot-ai-controller │
│   (3456)     │   │   (3000)     │   │   (internal)       │
└──────┬───────┘   └──────────────┘   └──────────┬─────────┘
       │                                          │
       │           ┌──────────────────────────────┘
       │           │
       ▼           ▼
┌──────────────────────────────┐
│  Qdrant Vector Database      │
│  (6333, 6334, 6335)          │
└──────────────────────────────┘
```

## Prerequisites

Before deploying, create the required secrets:

### 1. MCP Server Secrets

```bash
# Generate auth token
export DOT_AI_AUTH_TOKEN=$(openssl rand -base64 32)

# Set your API keys
export ANTHROPIC_API_KEY="sk-ant-api03-..."
export OPENAI_API_KEY="sk-proj-..."

# Create namespace
kubectl create namespace devops-toolkit

# Create secret
kubectl create secret generic dot-ai-secrets \
  --namespace devops-toolkit \
  --from-literal=auth-token="$DOT_AI_AUTH_TOKEN" \
  --from-literal=anthropic-api-key="$ANTHROPIC_API_KEY" \
  --from-literal=openai-api-key="$OPENAI_API_KEY"
```

### 2. Web UI Secrets

```bash
# Generate UI auth token
export DOT_AI_UI_AUTH_TOKEN=$(openssl rand -base64 32)

# Create secret
kubectl create secret generic dot-ai-ui-secrets \
  --namespace devops-toolkit \
  --from-literal=ui-auth-token="$DOT_AI_UI_AUTH_TOKEN"
```

## Deployment

### Option 1: Deploy All Components

```bash
# Apply all ArgoCD applications
kubectl apply -f apps/devops-toolkit/devops-toolkit-app.yaml
kubectl apply -f apps/devops-toolkit-controller/devops-toolkit-controller-app.yaml
kubectl apply -f apps/devops-toolkit-ui/devops-toolkit-ui-app.yaml

# Apply HTTPRoutes
kubectl apply -f apps/gateway-api/httproute-devops-toolkit.yaml
kubectl apply -f apps/gateway-api/httproute-devops-toolkit-ui.yaml
```

### Option 2: Push to Git (GitOps Way)

```bash
# Commit all changes
git add apps/devops-toolkit* apps/gateway-api/httproute-devops-toolkit*.yaml
git commit -m "Add complete DevOps Toolkit stack"
git push origin main

# ArgoCD will automatically sync the applications
```

### 3. Initialize Controller CRDs

After the controller is running, create the CRD instances:

```bash
# Enable resource discovery and capability scanning
kubectl apply -f apps/devops-toolkit-controller/manifests/resource-sync-config.yaml
kubectl apply -f apps/devops-toolkit-controller/manifests/capability-scan-config.yaml
```

## DNS Configuration

Add these DNS entries pointing to your gateway IP (`192.168.10.151`):

```
devops-toolkit.technovise.local       → 192.168.10.151
devops-toolkit-ui.technovise.local    → 192.168.10.151
```

Or add to your `/etc/hosts`:

```
192.168.10.151  devops-toolkit.technovise.local devops-toolkit-ui.technovise.local
```

## Verification

### Check ArgoCD Applications

```bash
kubectl get application -n argocd | grep devops-toolkit
```

Expected output:
```
devops-toolkit             Synced    Healthy
devops-toolkit-controller  Synced    Healthy
devops-toolkit-ui          Synced    Healthy
```

### Check Pods

```bash
kubectl get pods -n devops-toolkit
```

Expected output:
```
NAME                                                 READY   STATUS    RESTARTS   AGE
devops-toolkit-dot-ai-xxxxx                          1/1     Running   0          2m
devops-toolkit-controller-manager-xxxxx              1/1     Running   0          2m
devops-toolkit-ui-xxxxx                              1/1     Running   0          2m
devops-toolkit-qdrant-0                              1/1     Running   0          2m
```

### Check HTTPRoutes

```bash
kubectl get httproute -n devops-toolkit
```

Expected output:
```
NAME                 HOSTNAMES                            AGE
devops-toolkit       ["devops-toolkit.technovise.local"]       2m
devops-toolkit-ui    ["devops-toolkit-ui.technovise.local"]    2m
```

### Test MCP Server

```bash
curl -H "Authorization: Bearer $DOT_AI_AUTH_TOKEN" \
  https://devops-toolkit.technovise.local/healthz
```

Expected output:
```json
{"status":"ok"}
```

### Access Web UI

Open in browser: https://devops-toolkit-ui.technovise.local

Login with the UI auth token:
```bash
echo $DOT_AI_UI_AUTH_TOKEN
```

## MCP Client Configuration

Configure your MCP client (e.g., Claude Desktop) in `.mcp.json`:

```json
{
  "mcpServers": {
    "devops-toolkit": {
      "url": "https://devops-toolkit.technovise.local",
      "transport": {
        "type": "http"
      },
      "headers": {
        "Authorization": "Bearer YOUR_DOT_AI_AUTH_TOKEN"
      }
    }
  }
}
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod -n devops-toolkit <pod-name>

# Check logs
kubectl logs -n devops-toolkit <pod-name>
```

### HTTPRoute Not Working

```bash
# Check HTTPRoute status
kubectl describe httproute -n devops-toolkit

# Verify gateway is accepting routes
kubectl get gateway technovise-gateway -n istio-ingress
```

### MCP Server Connection Issues

```bash
# Test internal connectivity
kubectl exec -n devops-toolkit deployment/devops-toolkit-ui -- \
  curl -v http://devops-toolkit-dot-ai.devops-toolkit.svc.cluster.local:3456/healthz
```

### Controller Not Syncing Resources

```bash
# Check ResourceSyncConfig status
kubectl describe resourcesyncconfig default-sync -n devops-toolkit

# Check controller logs
kubectl logs -n devops-toolkit -l app.kubernetes.io/name=dot-ai-controller
```

## Next Steps

1. **Configure AI Operations**: Set up patterns and policies in the MCP server
2. **Create Solutions**: Use Solution CRDs to track your applications
3. **Enable Remediation**: Configure RemediationPolicy for automatic issue fixing
4. **Explore Web UI**: Browse resources and try AI-powered operations
5. **Integrate with Agents**: Connect your coding agent to the MCP server

## Resources

- [Stack Documentation](https://devopstoolkit.ai/docs/stack)
- [MCP Server Docs](https://devopstoolkit.ai/docs/ai-engine)
- [Controller Docs](https://devopstoolkit.ai/docs/controller)
- [Web UI Docs](https://devopstoolkit.ai/docs/ui)
- [Gateway API Setup](https://devopstoolkit.ai/docs/ai-engine/setup/gateway-api)
