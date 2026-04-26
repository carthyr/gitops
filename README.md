# GitOps Repository - Technovise Infrastructure

Repository GitOps pour la gestion déclarative de l'infrastructure Kubernetes via ArgoCD.

## 📋 Vue d'ensemble

- **Cluster**: MicroK8s sur nuc-01 (192.168.10.106)
- **GitOps**: ArgoCD v3.3.6 avec argocd-autopilot
- **Service Mesh**: Istio v1.24.2 (mode ambient)
- **Ingress**: Gateway API Kubernetes v1.5.1 (experimental)
- **Load Balancer**: MetalLB v0.14.9
- **Certificats**: cert-manager v1.15.3
- **Progressive Delivery**: Argo Rollouts v2.38.2
- **Observabilité Mesh**: Kiali v2.3.0
- **Monitoring**: 
  - Prometheus (kube-prometheus-stack v68.2.2)
  - Grafana (inclus dans kube-prometheus-stack)
  - Loki v6.23.0 + Promtail v6.16.6
  - OpenTelemetry Collector v0.115.2

## 🏗️ Architecture

### Infrastructure déployée:

```
┌─────────────────────────────────────────────────────────────┐
│                   Gateway API Kubernetes                     │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  technovise-gateway (192.168.10.151)                  │  │
│  │  ├─ HTTP Listener (port 80)  → *.technovise.local    │  │
│  │  └─ HTTPS Listener (port 443) → TLS termination      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴──────────┐
                    │    HTTPRoutes       │
                    └─────────┬──────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼──────┐    ┌────────▼─────┐    ┌─────────▼────┐
│   httpbin    │    │  app-2       │    │  app-N       │
│ (demo-app)   │    │              │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
```

### Service Mesh Istio (Ambient Mode):

- **istio-base**: CRDs et configurations de base
- **istiod**: Plan de contrôle (certificates, configuration)
- **istio-cni**: Plugin CNI pour la capture du trafic
- **ztunnel**: Proxy L4 pour le mode ambient (un par noeud)

### Sécurité TLS:

- **CA auto-signée**: technovise-local-ca (ClusterIssuer)
- **Certificat wildcard**: `*.technovise.local` (valide pour tous les sous-domaines)

## 📁 Structure du repository

```
.
├── apps/                          # Applications et configurations
│   ├── argo-rollouts/             # Progressive delivery controller
│   │   ├── components/            # Manifests Argo Rollouts
│   │   └── argo-rollouts-app.yaml # Application ArgoCD
│   ├── cert-manager/              # Gestionnaire de certificats TLS
│   │   ├── components/            # Manifests cert-manager
│   │   └── cert-manager-app.yaml
│   ├── cert-manager-config/       # Configuration cert-manager
│   │   └── issuers/               # ClusterIssuers et certificats
│   ├── gateway-api-crds/          # CRDs Gateway API Kubernetes (v1.5.1)
│   │   ├── kustomization.yaml     # Installation CRDs via Kustomize
│   │   └── gateway-api-crds-app.yaml
│   ├── gateway-api/               # Ressources Gateway API
│   │   ├── gatewayclass.yaml      # Définition GatewayClass
│   │   ├── gateway.yaml           # Gateway technovise-gateway
│   │   ├── httproute-*.yaml       # HTTPRoutes (httpbin, argocd, kiali, grafana, prometheus, alertmanager)
│   │   └── gateway-api-config-app.yaml
│   ├── istio/                     # Service mesh Istio
│   │   ├── components/            # istio-base, istiod, cni, ztunnel
│   │   └── istio-app.yaml
│   ├── istio-gateway/             # Applications de démo
│   │   └── gateway-config/        # Déploiements demo (httpbin)
│   ├── kiali/                     # Observabilité Istio
│   │   ├── components/
│   │   └── kiali-app.yaml
│   ├── metallb/                   # Load balancer
│   │   ├── components/            # MetalLB manifests
│   │   └── config/                # IP pools et L2 advertisement
│   └── monitoring/                # Stack de monitoring (app-of-apps)
│       ├── components/            # Prometheus, Grafana, Loki, OpenTelemetry
│       └── monitoring-app.yaml
├── bootstrap/                     # Bootstrap ArgoCD
│   └── argo-cd.yaml
├── projects/                      # Projets ArgoCD
│   └── default.yaml
├── GATEWAY-ACCESS.md              # Guide d'accès Gateway API
└── README.md                      # Ce fichier
```

## 🚀 Démarrage rapide

### Prérequis

- MicroK8s installé et configuré
- kubectl configuré pour accéder au cluster
- Git et accès au repository GitHub

### Installation initiale (déjà fait)

```bash
# Bootstrap avec argocd-autopilot (patché pour --server-side)
argocd-autopilot repo bootstrap --repo https://github.com/carthyr/gitops

# Récupérer le mot de passe admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

**Mot de passe admin ArgoCD**: `eU8VbFAoOFBVMjPI`

### Accès ArgoCD

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Ouvrir: https://localhost:8080
- User: `admin`
- Password: `eU8VbFAoOFBVMjPI`

## 🌐 Applications déployées

Total: **24 applications ArgoCD** 

### Infrastructure core:
- **argocd** - GitOps controller (https://argocd.technovise.local)
- **cert-manager** + cert-manager-config - Gestion TLS/certificats
- **metallb** + metallb-config - Load balancer bare-metal
- **istio** (app-of-apps) - Service mesh ambient mode
  - istio-base, istiod, istio-cni, ztunnel
- **gateway-api-crds** - CRDs Gateway API v1.5.1
- **gateway-api-config** - Gateway et HTTPRoutes
- **istio-gateway-config** - Configurations ingress
- **argo-rollouts** + argo-rollouts-dashboard - Progressive delivery
- **kiali** - Observabilité Istio (https://kiali.technovise.local)

### Stack monitoring (app-of-apps):
- **kube-prometheus-stack** - Prometheus + Grafana + Alertmanager
  - Prometheus: https://prometheus.technovise.local
  - Grafana: https://grafana.technovise.local (admin/admin123)
  - Alertmanager: https://alertmanager.technovise.local
- **loki** - Agrégation de logs
- **promtail** - Collecteur de logs → Loki
- **opentelemetry-collector** - Traces et métriques distribuées

### Applications demo:
- **httpbin** - Service de test (https://httpbin.technovise.local)

### Applications AI/ML:
- **ollama** - Serveur de modèles LLM avec support GPU Intel (https://ollama.technovise.local)
- **open-webui** - Interface web ChatBox pour Ollama (https://chat.technovise.local)

## 🔒 Sécurité et certificats

### Vérifier les certificats:

```bash
kubectl get certificate -A
```

Devrait afficher:
- `selfsigned-ca` (cert-manager): CA racine
- `technovise-wildcard-cert` (istio-ingress): `*.technovise.local`

### Inspecter le certificat:

```bash
kubectl get secret technovise-wildcard-tls -n istio-ingress -o jsonpath='{.data.tls\.crt}' \
  | base64 -d | openssl x509 -text -noout
```

## 🌐 Gateway API - Guide d'utilisation

### Vérifier l'état du Gateway:

```bash
# GatewayClasses disponibles
kubectl get gatewayclass

# Gateway déployé
kubectl get gateway -n istio-ingress

# Routes configurées
kubectl get httproute -A
```

### Ajouter une nouvelle application:

1. Créer votre deployment/service dans un namespace
2. Ajouter un HTTPRoute:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app
  namespace: my-namespace
spec:
  parentRefs:
  - name: technovise-gateway
    namespace: istio-ingress
  hostnames:
  - "my-app.technovise.local"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: my-service
      port: 8080
```

3. Ajouter le DNS local (`/etc/hosts`):
```
192.168.10.151  my-app.technovise.local
```

4. Tester:
```bash
curl -k https://my-app.technovise.local
```

### Voir [GATEWAY-ACCESS.md](GATEWAY-ACCESS.md) pour plus de détails

## 🛠️ Outils utiles

### Diagnostics Istio:

```bash
# Vérifier l'état du mesh
istioctl proxy-status

# Analyser la configuration
istioctl analyze -A

# Vérifier les policies ambient
kubectl get authorizationpolicies -A
```

### Diagnostics Gateway API:

```bash
# Détails du Gateway
kubectl describe gateway technovise-gateway -n istio-ingress

# Logs du Gateway controller (Istio)
kubectl logs -n istio-system -l app=istiod --tail=100
```

### MetalLB:

```bash
# Vérifier les IPs assignées
kubectl get svc -A | grep LoadBalancer

# Voir les IP pools
kubectl get ipaddresspool -n metallb-system

# Logs MetalLB
kubectl logs -n metallb-system -l app=metallb
```

## 📊 Observabilité

### Kiali (Istio Dashboard):

```bash
kubectl port-forward svc/kiali -n istio-system 20001:20001
```

Ouvrir: http://localhost:20001

### Argo Rollouts Dashboard:

```bash
kubectl port-forward svc/argo-rollouts-dashboard -n argo-rollouts 3100:3100
```

Ouvrir: http://localhost:3100

## 🔄 Workflow GitOps

### Modification d'une application:

```bash
# 1. Modifier les manifests dans apps/
vim apps/gateway-api/httproute-my-app.yaml

# 2. Commit et push
git add apps/gateway-api/httproute-my-app.yaml
git commit -m "Add HTTPRoute for my-app"
git push

# 3. ArgoCD sync automatique (ou manuel via UI)
argocd app sync gateway-api-config
```

### Ajouter une nouvelle application:

```bash
# 1. Créer le répertoire et manifests
mkdir -p apps/my-new-app/components
vim apps/my-new-app/components/deployment.yaml

# 2. Créer l'application ArgoCD
vim apps/my-new-app/my-new-app.yaml

# 3. Commit et push
git add apps/my-new-app
git commit -m "Add my-new-app"
git push

# 4. Créer l'application dans ArgoCD
kubectl apply -f apps/my-new-app/my-new-app.yaml
```

## 🏷️ Notes importantes

### Gateway API vs Istio Gateway:

Ce projet utilise désormais **Gateway API Kubernetes** (standard) au lieu de l'API propriétaire Istio `VirtualService/Gateway`. 

**Avantages**:
- ✅ Standard Kubernetes portable
- ✅ Support natif pour HTTP, gRPC, TCP, TLS, UDP routes
- ✅ Séparation des rôles (infra vs dev)
- ✅ Extensible via policies et filtres

### Mode Ambient Istio:

Le mode "ambient" est une architecture sidecar-less:
- ✅ Pas de sidecars automatiques (moins de ressources)
- ✅ ztunnel pour proxy L4 (un par noeud)
- ✅ waypoint (optionnel) pour proxy L7
- ✅ Meilleure performance et sécurité

Pour activer ambient sur un namespace:
```bash
kubectl label namespace my-namespace istio.io/dataplane-mode=ambient
```

### Load Balancer IPs:

MetalLB distribue des IPs du pool **192.168.10.150-160**:
- `192.168.10.151`: **technovise-gateway-istio** (Gateway API - service automatiquement créé par Istio)

## � Guides de configuration

Documentation détaillée disponible dans le dossier `docs/`:

- **[GATEWAY-ACCESS.md](GATEWAY-ACCESS.md)** - Guide d'accès et configuration Gateway API
- **[docs/GPU-SHARING-GUIDE.md](docs/GPU-SHARING-GUIDE.md)** - Partage GPU Intel avec DRA et GPU Plugin
- **[docs/OPENVINO-GUIDE.md](docs/OPENVINO-GUIDE.md)** - Déploiement d'applications OpenVINO
- **[docs/OLLAMA-OPENWEBUI-GUIDE.md](docs/OLLAMA-OPENWEBUI-GUIDE.md)** - Configuration Ollama + Open WebUI (ChatBox AI)

## �📚 Ressources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Gateway API Official Docs](https://gateway-api.sigs.k8s.io/)
- [Istio Ambient Mode](https://istio.io/latest/docs/ambient/)
- [cert-manager](https://cert-manager.io/)
- [MetalLB](https://metallb.universe.tf/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)

## 🐛 Troubleshooting

### Gateway pas accessible:

```bash
# 1. Vérifier que le Gateway est programmé
kubectl get gateway -n istio-ingress

# 2. Vérifier le service LoadBalancer
kubectl get svc -n istio-ingress

# 3. Tester depuis le cluster
kubectl run test-curl --rm -i --image=curlimages/curl -- \
  curl -v http://192.168.10.151/get -H 'Host: httpbin.technovise.local'
```

### Certificat non valide:

```bash
# Vérifier le certificat
kubectl get certificate -n istio-ingress technovise-wildcard-cert

# Supprimer et recréer si nécessaire
kubectl delete certificate technovise-wildcard-cert -n istio-ingress
# ArgoCD va le recréer automatiquement
```

### Application pas Synced dans ArgoCD:

```bash
# Voir les détails
argocd app get <app-name>

# Forcer le sync
argocd app sync <app-name> --force

# Voir les logs
argocd app logs <app-name>
```

---

**Créé par**: Bilal Ismail  
**Dernière mise à jour**: Décembre 2024  
**Repository**: https://github.com/carthyr/gitops
