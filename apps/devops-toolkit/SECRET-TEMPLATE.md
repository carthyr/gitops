# Secret Creation Template

⚠️ **DO NOT COMMIT SECRETS TO GIT**

Create the required secret before deploying the application:

## Quick Setup

```bash
# 1. Generate auth token
export DOT_AI_AUTH_TOKEN=$(openssl rand -base64 32)

# 2. Set your API keys (get these from your AI provider accounts)
export ANTHROPIC_API_KEY="sk-ant-api03-..."  # From https://console.anthropic.com/
export OPENAI_API_KEY="sk-proj-..."          # From https://platform.openai.com/

# 3. Create namespace
kubectl create namespace devops-toolkit

# 4. Create the secret
kubectl create secret generic dot-ai-secrets \
  --namespace devops-toolkit \
  --from-literal=auth-token="$DOT_AI_AUTH_TOKEN" \
  --from-literal=anthropic-api-key="$ANTHROPIC_API_KEY" \
  --from-literal=openai-api-key="$OPENAI_API_KEY"
```

## Verify Secret

```bash
kubectl get secret dot-ai-secrets -n devops-toolkit
kubectl describe secret dot-ai-secrets -n devops-toolkit
```

## Using Sealed Secrets (Alternative)

If you use sealed-secrets in your cluster, you can create a SealedSecret:

```bash
# 1. Create a temporary secret file
cat <<EOF > /tmp/dot-ai-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: dot-ai-secrets
  namespace: devops-toolkit
type: Opaque
stringData:
  auth-token: "$(openssl rand -base64 32)"
  anthropic-api-key: "YOUR_ANTHROPIC_KEY"
  openai-api-key: "YOUR_OPENAI_KEY"
EOF

# 2. Seal it
kubeseal -f /tmp/dot-ai-secret.yaml -w sealed-secret.yaml

# 3. Commit the sealed secret to git
git add sealed-secret.yaml
git commit -m "Add sealed secret for devops-toolkit"

# 4. Clean up temporary file
rm /tmp/dot-ai-secret.yaml
```

## Using External Secrets Operator (Alternative)

If you use External Secrets Operator:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: dot-ai-secrets
  namespace: devops-toolkit
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: your-secret-store
    kind: SecretStore
  target:
    name: dot-ai-secrets
    creationPolicy: Owner
  data:
    - secretKey: auth-token
      remoteRef:
        key: devops-toolkit/auth-token
    - secretKey: anthropic-api-key
      remoteRef:
        key: devops-toolkit/anthropic-api-key
    - secretKey: openai-api-key
      remoteRef:
        key: devops-toolkit/openai-api-key
```

## API Key Sources

- **Anthropic API Key**: https://console.anthropic.com/settings/keys
- **OpenAI API Key**: https://platform.openai.com/api-keys

## Security Best Practices

1. Never commit secrets to Git
2. Use a secrets management solution (Sealed Secrets, External Secrets, Vault)
3. Rotate API keys regularly
4. Use separate API keys for different environments
5. Limit API key permissions to minimum required
