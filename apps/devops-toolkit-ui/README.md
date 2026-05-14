# DevOps Toolkit Web UI

Web interface for visual cluster management with AI-powered operations.

## Prerequisites

Before deploying, you must create the UI authentication secret:

```bash
# Generate a secure UI auth token
UI_AUTH_TOKEN=$(openssl rand -base64 32)

# Create the secret
kubectl create secret generic dot-ai-ui-secrets -n devops-toolkit \
  --from-literal=ui-auth-token="$UI_AUTH_TOKEN"
```

## Access

Once deployed, the service will be available at:
- **HTTPS**: https://devops-toolkit-ui.technovise.local

Make sure your DNS points `devops-toolkit-ui.technovise.local` to your gateway IP.

## Features

- **Kubernetes Dashboard**: Browse and manage cluster resources
- **AI-Powered Operations**: Query, Remediate, Operate, Recommend
- **Semantic Search**: Find resources using natural language (Cmd+K / Ctrl+K)
- **Resource Details**: View specs, status, YAML, events, and logs
- **Visualization**: Rich diagrams, charts, and tables

## Authentication

The UI supports two authentication methods:

1. **OAuth/SSO Login** (Recommended): If dot-ai MCP server has OAuth enabled
2. **Bearer Token Login**: Use the UI auth token created above

To get your token:
```bash
echo $UI_AUTH_TOKEN
# Or retrieve from secret:
kubectl get secret dot-ai-ui-secrets -n devops-toolkit -o jsonpath='{.data.ui-auth-token}' | base64 -d
```

## Configuration

The UI is configured to:
- Connect to the dot-ai MCP server at `http://devops-toolkit-dot-ai.devops-toolkit.svc.cluster.local:3456`
- Use the existing `technovise-gateway` in the `istio-ingress` namespace
- Enable HTTPS with the wildcard certificate

## Verify Deployment

```bash
# Check pods
kubectl get pods -n devops-toolkit -l app.kubernetes.io/name=dot-ai-ui

# Check HTTPRoute
kubectl get httproute -n devops-toolkit | grep ui

# Check service
kubectl get svc -n devops-toolkit -l app.kubernetes.io/name=dot-ai-ui

# View logs
kubectl logs -n devops-toolkit -l app.kubernetes.io/name=dot-ai-ui
```

## Troubleshooting

### Cannot Connect to MCP Server
```bash
# Check if dot-ai service is accessible
kubectl exec -n devops-toolkit deployment/devops-toolkit-ui -- \
  curl -v http://devops-toolkit-dot-ai.devops-toolkit.svc.cluster.local:3456/healthz
```

### Authentication Issues
```bash
# Verify UI auth secret exists
kubectl get secret dot-ai-ui-secrets -n devops-toolkit

# Check if UI is using the correct secret
kubectl get deployment devops-toolkit-ui -n devops-toolkit -o yaml | grep -A 5 secretRef
```

## Resources

- [Web UI Documentation](https://devopstoolkit.ai/docs/ui)
- [Kubernetes Setup Guide](https://devopstoolkit.ai/docs/ui/setup/kubernetes-setup)
- [Authentication Guide](https://devopstoolkit.ai/docs/ui/#authentication)
