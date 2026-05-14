# Web UI Secret Creation Template

⚠️ **DO NOT COMMIT SECRETS TO GIT**

Create the required secret before deploying the application:

## Quick Setup

```bash
# 1. Generate UI auth token
export DOT_AI_UI_AUTH_TOKEN=$(openssl rand -base64 32)

# 2. Create namespace (if not already exists)
kubectl create namespace devops-toolkit --dry-run=client -o yaml | kubectl apply -f -

# 3. Create the secret
kubectl create secret generic dot-ai-ui-secrets \
  --namespace devops-toolkit \
  --from-literal=ui-auth-token="$DOT_AI_UI_AUTH_TOKEN"
```

## Verify Secret

```bash
kubectl get secret dot-ai-ui-secrets -n devops-toolkit
kubectl describe secret dot-ai-ui-secrets -n devops-toolkit
```

## Retrieve Token

If you need to retrieve the token later:

```bash
kubectl get secret dot-ai-ui-secrets -n devops-toolkit \
  -o jsonpath='{.data.ui-auth-token}' | base64 -d && echo
```

## Using Sealed Secrets (Alternative)

If you use sealed-secrets in your cluster:

```bash
# 1. Create a temporary secret file
cat <<EOF > /tmp/dot-ai-ui-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: dot-ai-ui-secrets
  namespace: devops-toolkit
type: Opaque
stringData:
  ui-auth-token: "$(openssl rand -base64 32)"
EOF

# 2. Seal it
kubeseal -f /tmp/dot-ai-ui-secret.yaml -w sealed-secret.yaml

# 3. Commit the sealed secret to git
git add sealed-secret.yaml
git commit -m "Add sealed secret for devops-toolkit-ui"

# 4. Clean up temporary file
rm /tmp/dot-ai-ui-secret.yaml
```

## Using External Secrets Operator (Alternative)

If you use External Secrets Operator:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: dot-ai-ui-secrets
  namespace: devops-toolkit
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: your-secret-store
    kind: SecretStore
  target:
    name: dot-ai-ui-secrets
    creationPolicy: Owner
  data:
    - secretKey: ui-auth-token
      remoteRef:
        key: devops-toolkit-ui/auth-token
```

## Security Best Practices

1. Never commit secrets to Git
2. Use a secrets management solution (Sealed Secrets, External Secrets, Vault)
3. Rotate auth tokens regularly
4. Use separate tokens for different environments
5. Limit token permissions to minimum required
