# DevOps Toolkit Controller

Kubernetes controller that provides resource tracking, event-driven remediation, and resource visibility.

## Overview

The controller manages five Custom Resource Definitions (CRDs):

1. **Solution**: Track and manage deployed resources as logical solutions
2. **RemediationPolicy**: Event-driven remediation with AI analysis
3. **ResourceSyncConfig**: Resource visibility through semantic search
4. **CapabilityScanConfig**: Autonomous capability discovery
5. **GitKnowledgeSource**: Documentation ingestion from Git repositories

## Features

- **Resource Tracking**: Groups related resources with automatic cleanup via ownerReferences
- **Health Monitoring**: Aggregates health status across all tracked resources
- **Event-Driven Remediation**: Automatically detect, analyze, and fix issues
- **Semantic Search**: Enable natural language queries across cluster resources
- **Capability Discovery**: Automatically discover and sync cluster capabilities

## Configuration

The controller is deployed to the `devops-toolkit` namespace and requires:
- Connection to the dot-ai MCP server for AI-powered features
- RBAC permissions to watch and manage cluster resources
- Secret containing MCP auth token (same as dot-ai server)

## Initial Setup

After deploying the controller, create the required CRD instances:

### 1. ResourceSyncConfig (Enable Resource Discovery)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: dot-ai.devopstoolkit.live/v1alpha1
kind: ResourceSyncConfig
metadata:
  name: default-sync
  namespace: devops-toolkit
spec:
  mcpEndpoint: http://devops-toolkit-dot-ai.devops-toolkit.svc.cluster.local:3456/api/v1/resources/sync
  mcpAuthSecretRef:
    name: dot-ai-secrets
    key: auth-token
  debounceWindowSeconds: 10
  resyncIntervalMinutes: 60
EOF
```

### 2. CapabilityScanConfig (Enable Capability Discovery)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: dot-ai.devopstoolkit.live/v1alpha1
kind: CapabilityScanConfig
metadata:
  name: default-scan
  namespace: devops-toolkit
spec:
  mcp:
    endpoint: http://devops-toolkit-dot-ai.devops-toolkit.svc.cluster.local:3456/api/v1/tools/manageOrgData
    authSecretRef:
      name: dot-ai-secrets
      key: auth-token
EOF
```

### 3. RemediationPolicy (Optional - Event Remediation)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: dot-ai.devopstoolkit.live/v1alpha1
kind: RemediationPolicy
metadata:
  name: auto-remediate
  namespace: devops-toolkit
spec:
  eventSelectors:
    - type: Warning
      reason: FailedScheduling
      mode: automatic
    - type: Warning
      reason: BackOff
      mode: manual
  mcpEndpoint: http://devops-toolkit-dot-ai.devops-toolkit.svc.cluster.local:3456/api/v1/tools/remediate
  mode: manual
EOF
```

## Verify Deployment

```bash
# Check controller pod
kubectl get pods -n devops-toolkit -l app.kubernetes.io/name=dot-ai-controller

# Check CRDs
kubectl get crds | grep dot-ai

# Check ResourceSyncConfig status
kubectl get resourcesyncconfig -n devops-toolkit

# Check CapabilityScanConfig status
kubectl get capabilityscanconfig -n devops-toolkit

# View controller logs
kubectl logs -n devops-toolkit -l app.kubernetes.io/name=dot-ai-controller
```

## Example: Create a Solution

Track a set of resources as a logical solution:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: dot-ai.devopstoolkit.live/v1alpha1
kind: Solution
metadata:
  name: my-app
  namespace: default
spec:
  intent: "Production web application with database"
  resources:
    - apiVersion: apps/v1
      kind: Deployment
      name: web-app
    - apiVersion: v1
      kind: Service
      name: web-app-service
    - apiVersion: apps/v1
      kind: StatefulSet
      name: postgresql
EOF
```

## Troubleshooting

### Controller Not Starting
```bash
# Check controller logs
kubectl logs -n devops-toolkit -l app.kubernetes.io/name=dot-ai-controller

# Verify RBAC permissions
kubectl auth can-i list pods --as=system:serviceaccount:devops-toolkit:dot-ai-controller
```

### ResourceSync Not Working
```bash
# Check ResourceSyncConfig status
kubectl describe resourcesyncconfig default-sync -n devops-toolkit

# Verify MCP endpoint is accessible
kubectl exec -n devops-toolkit deployment/devops-toolkit-controller-manager -- \
  curl -v http://devops-toolkit-dot-ai.devops-toolkit.svc.cluster.local:3456/healthz
```

### Capability Scan Not Triggering
```bash
# Check CapabilityScanConfig status
kubectl describe capabilityscanconfig default-scan -n devops-toolkit

# Check for CRD events
kubectl get events -n devops-toolkit --field-selector involvedObject.kind=CustomResourceDefinition
```

## Resources

- [Controller Documentation](https://devopstoolkit.ai/docs/controller)
- [Remediation Guide](https://devopstoolkit.ai/docs/controller/remediation-guide)
- [Resource Sync Guide](https://devopstoolkit.ai/docs/controller/resource-sync-guide)
- [Solution Guide](https://devopstoolkit.ai/docs/controller/solution-guide)
