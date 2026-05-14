# DevOps Toolkit (dot-ai)

DevOps AI Toolkit deployment using Gateway API with Istio.

## Prerequisites

Before deploying, you must create the secrets manually:

```bash
# Generate a secure auth token
AUTH_TOKEN=$(openssl rand -base64 32)

# Create the secret (replace with your actual API keys)
kubectl create namespace devops-toolkit
kubectl create secret generic dot-ai-secrets -n devops-toolkit \
  --from-literal=auth-token="$AUTH_TOKEN" \
  --from-literal=anthropic-api-key="YOUR_ANTHROPIC_KEY" \
  --from-literal=openai-api-key="YOUR_OPENAI_KEY"
```

## Access

Once deployed, the service will be available at:
- **HTTPS**: https://devops-toolkit.technovise.local

Make sure your DNS points `devops-toolkit.technovise.local` to your gateway IP.

## Configuration

The deployment is configured to:
- Use the existing `technovise-gateway` in the `istio-ingress` namespace
- Enable HTTPS with the wildcard certificate
- Use Anthropic as the default AI provider
- Enable local embeddings
- Deploy Qdrant for vector storage

## Verify Deployment

```bash
# Check pods
kubectl get pods -n devops-toolkit

# Check HTTPRoute
kubectl get httproute -n devops-toolkit

# Check service
kubectl get svc -n devops-toolkit

# View logs
kubectl logs -n devops-toolkit -l app.kubernetes.io/name=dot-ai
```

## Troubleshooting

### Check Gateway Status
```bash
kubectl get gateway technovise-gateway -n istio-ingress
```

### Check HTTPRoute Status
```bash
kubectl describe httproute -n devops-toolkit
```

### Check if Secret Exists
```bash
kubectl get secret dot-ai-secrets -n devops-toolkit
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
      }
    }
  }
}
```

## Resources

- [DevOps Toolkit Documentation](https://devopstoolkit.ai/docs/ai-engine)
- [Gateway API Setup Guide](https://devopstoolkit.ai/docs/ai-engine/setup/gateway-api)
- [Authentication Setup](https://devopstoolkit.ai/docs/ai-engine/setup/authentication)
