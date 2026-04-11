# Guide d'accès aux applications via Gateway API Kubernetes

## Configuration actuelle

- **Gateway API**: v1.5.1 (experimental)
- **LoadBalancer IP**: 192.168.10.151
- **Domaine**: technovise.local  
- **Gateway**: technovise-gateway (namespace: istio-ingress)
- **GatewayClass**: istio (Istio implementation)

## Architecture

**Gateway API Kubernetes**  
au lieu de l'ancienne API Istio `VirtualService`. Cette nouvelle architecture suit le standard Kubernetes et est plus portable.

### Ressources déployées:

1. **GatewayClass**: `istio` - Implémentation Istio du Gateway API
2. **Gateway**: `technovise-gateway` - Point d'entrée HTTP/HTTPS
3. **HTTPRoute**: Routes pour exposer les services (ex: httpbin)
4. **Certificats**: Wildcard `*.technovise.local` (auto-signé)

## Configuration DNS locale requise

Ajoutez dans votre `/etc/hosts` (macOS/Linux) ou `C:\Windows\System32\drivers\etc\hosts` (Windows) :

```
192.168.10.151  technovise.local
192.168.10.151  httpbin.technovise.local
192.168.10.151  argocd.technovise.local
192.168.10.151  kiali.technovise.local
192.168.10.151  grafana.technovise.local
192.168.10.151  prometheus.technovise.local
192.168.10.151  alertmanager.technovise.local
```

Ou configurez votre DNS local avec un wildcard pour `*.technovise.local → 192.168.10.151`

## Applications déployées

### Infrastructure:
- **ArgoCD**: https://argocd.technovise.local
  - Username: admin
  - Password: eU8VbFAoOFBVMjPI
  - HTTPRoute: `argocd` (namespace: argocd)

### Observabilité:
- **Kiali** (Istio Dashboard): https://kiali.technovise.local
  - HTTPRoute: `kiali` (namespace: istio-system)

### Monitoring:
- **Grafana**: https://grafana.technovise.local
  - Username: admin
  - Password: admin123 ⚠️ (à changer en production)
  - HTTPRoute: `grafana` (namespace: monitoring)

- **Prometheus**: https://prometheus.technovise.local
  - HTTPRoute: `prometheus` (namespace: monitoring)

- **Alertmanager**: https://alertmanager.technovise.local
  - HTTPRoute: `alertmanager` (namespace: monitoring)

### Demo:
- **httpbin**: https://httpbin.technovise.local
  - HTTPRoute: `httpbin` (namespace: demo-app)

## Tests

```bash
# Vérifier le Gateway
kubectl get gateway -n istio-ingress

# Vérifier les HTTPRoutes
kubectl get httproute -A

# Test HTTP (port 80)
curl -v --resolve httpbin.technovise.local:80:192.168.10.151 http://httpbin.technovise.local/get

# Test HTTPS avec certificat auto-signé (port 443)
curl -k --resolve httpbin.technovise.local:443:192.168.10.151 https://httpbin.technovise.local/get

# Vérifier les headers
curl -k --resolve httpbin.technovise.local:443:192.168.10.151 https://httpbin.technovise.local/headers
```

## Ajouter une nouvelle application

### Étape 1: Créer un HTTPRoute

Créez un fichier dans `apps/gateway-api/`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: mon-app
  namespace: mon-namespace
spec:
  parentRefs:
  - name: technovise-gateway
    namespace: istio-ingress
  hostnames:
  - "mon-app.technovise.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: mon-service
      port: 8080
```

### Étape 2: Le certificat wildcard gérera automatiquement le TLS

Le certificat `*.technovise.local` est déjà configuré et couvrira toutes vos applications.

## Comparaison Istio Gateway vs Gateway API

| Ancienne API Istio | Gateway API Kubernetes |
|-------------------|------------------------|
| `VirtualService` | `HTTPRoute` |
| `Gateway (Istio)` | `Gateway (K8s)` |
| - | `GatewayClass` |
| API propriétaire Istio | Standard Kubernetes |

## Avantages de Gateway API

- ✅ **Standard Kubernetes**: Portable entre différents service meshes
- ✅ **Plus expressif**: Support natif pour gRPC, TCP, TLS routes
- ✅ **Role-based**: Séparation des responsabilités (infra vs app teams)
- ✅ **Extensible**: Via policies et filtres
- ✅ **Future-proof**: Direction officielle de Kubernetes

## Ressources

- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [Istio Gateway API Guide](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/)
