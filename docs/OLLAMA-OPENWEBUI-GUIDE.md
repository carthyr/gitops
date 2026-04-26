# Guide d'utilisation - Ollama + Open WebUI

## 📋 Vue d'ensemble

Configuration d'un serveur LLM local avec Ollama et interface web ChatBox (Open WebUI) sur Kubernetes avec accélération GPU Intel.

### Composants déployés:

- **Ollama**: Serveur de modèles LLM (Large Language Models)
  - Support GPU Intel (i915)
  - Stockage persistant 100Gi pour les modèles
  - API REST sur port 11434
  - URL: https://ollama.technovise.local

- **Open WebUI**: Interface web type ChatGPT
  - Interface utilisateur moderne et intuitive
  - Gestion multi-utilisateurs avec authentification
  - Historique des conversations persisté
  - Support multi-modèles
  - URL: https://chat.technovise.local

## 🚀 Déploiement

### 1. Appliquer les configurations

Les fichiers de configuration sont déjà créés dans le repository GitOps:

```bash
# Applications ArgoCD
kubectl apply -f apps/ollama/ollama-app.yaml
kubectl apply -f apps/open-webui/open-webui-app.yaml

# HTTPRoutes (déjà incluses dans gateway-api)
kubectl apply -f apps/gateway-api/httproute-ollama.yaml
kubectl apply -f apps/gateway-api/httproute-open-webui.yaml
```

Ou via ArgoCD UI/CLI:
```bash
argocd app sync ollama
argocd app sync open-webui
```

### 2. Vérifier le déploiement

```bash
# Status des pods
kubectl get pods -n ollama
kubectl get pods -n open-webui

# Status des services
kubectl get svc -n ollama
kubectl get svc -n open-webui

# HTTPRoutes
kubectl get httproute -n ollama
kubectl get httproute -n open-webui
```

### 3. Configuration DNS locale

Ajouter à `/etc/hosts`:
```
192.168.10.151  ollama.technovise.local
192.168.10.151  chat.technovise.local
```

## 💻 Utilisation

### Accès à Open WebUI

1. Ouvrir le navigateur: https://chat.technovise.local

2. **Première connexion** - Créer un compte administrateur:
   - Cliquer sur "Sign up"
   - Entrer email et mot de passe
   - Le premier utilisateur créé devient automatiquement admin

3. **Interface principale**:
   - Sélectionner un modèle dans le menu déroulant
   - Démarrer une conversation
   - L'historique est automatiquement sauvegardé

### Gestion des modèles via Open WebUI

Open WebUI permet de télécharger et gérer les modèles Ollama directement depuis l'interface:

1. Cliquer sur votre profil (coin supérieur droit)
2. Aller dans **Settings** → **Models**
3. Dans "Pull a model from Ollama.com":
   - Entrer le nom du modèle (ex: `llama3.2`, `mistral`, `codellama`)
   - Cliquer sur le bouton de téléchargement
4. Attendre la fin du téléchargement (visible dans les notifications)

### Gestion des modèles via API Ollama

#### Lister les modèles disponibles:
```bash
curl https://ollama.technovise.local/api/tags
```

#### Télécharger un modèle:
```bash
# Modèles populaires
curl https://ollama.technovise.local/api/pull -d '{
  "name": "llama3.2"
}'

# Modèle plus léger (3B params)
curl https://ollama.technovise.local/api/pull -d '{
  "name": "llama3.2:3b"
}'

# Modèle de code
curl https://ollama.technovise.local/api/pull -d '{
  "name": "codellama"
}'

# Modèle français optimisé
curl https://ollama.technovise.local/api/pull -d '{
  "name": "mistral"
}'
```

#### Générer une complétion:
```bash
curl https://ollama.technovise.local/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

#### Utiliser le chat endpoint:
```bash
curl https://ollama.technovise.local/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    {
      "role": "user",
      "content": "Explique-moi le concept de GitOps"
    }
  ],
  "stream": false
}'
```

### Gestion des modèles via CLI (exec dans le pod)

```bash
# Se connecter au pod Ollama
kubectl exec -it -n ollama deployment/ollama -- /bin/sh

# Lister les modèles installés
ollama list

# Télécharger un modèle
ollama pull llama3.2

# Supprimer un modèle
ollama rm llama3.2

# Tester un modèle en interactif
ollama run llama3.2
```

## 🎯 Modèles recommandés

### Par taille et performance:

| Modèle | Taille | RAM requise | Usage |
|--------|--------|-------------|-------|
| `llama3.2:1b` | ~1.3GB | 2GB | Tests rapides, appareils limités |
| `llama3.2:3b` | ~2GB | 4GB | Équilibre performance/ressources |
| `llama3.2` (7B) | ~4.7GB | 8GB | **Recommandé** - Bon équilibre |
| `mistral` | ~4.1GB | 8GB | Excellent pour le français |
| `codellama` | ~3.8GB | 8GB | Génération de code |
| `llama3.1:8b` | ~4.7GB | 8GB | Version améliorée de llama3 |
| `deepseek-coder-v2` | ~8.9GB | 16GB | Code avancé |

### Pour votre GPU Intel (16GB RAM alloués):
- Vous pouvez charger des modèles jusqu'à ~13B paramètres
- Recommandé: 1-2 modèles 7B simultanés
- Optimal: Llama3.2 (7B) + Mistral

## 🔧 Configuration avancée

### Variables d'environnement Ollama

Modifiable dans `apps/ollama/ollama-app.yaml`:

```yaml
extraEnv:
  - name: OLLAMA_INTEL_GPU
    value: "1"
  - name: OLLAMA_NUM_GPU
    value: "1"
  - name: OLLAMA_MAX_LOADED_MODELS
    value: "2"  # Nombre de modèles en mémoire
  - name: OLLAMA_NUM_PARALLEL
    value: "4"  # Requêtes parallèles
```

### Paramètres Open WebUI

Modifiable dans `apps/open-webui/open-webui-app.yaml`:

```yaml
extraEnvVars:
  - name: WEBUI_AUTH
    value: "true"  # Activer l'authentification
  - name: WEBUI_NAME
    value: "Technovise Chat"  # Nom de l'interface
  - name: ENABLE_SIGNUP
    value: "true"  # Permettre l'inscription
  - name: DEFAULT_MODELS
    value: "llama3.2,mistral"  # Modèles par défaut
```

### Augmenter le stockage

Si 100Gi n'est pas suffisant pour vos modèles:

```yaml
# Dans apps/ollama/ollama-app.yaml
persistentVolume:
  enabled: true
  size: 200Gi  # Augmenter ici
  storageClass: "microk8s-hostpath"
```

## 📊 Monitoring

### Vérifier l'utilisation du GPU

```bash
# Dans le pod Ollama
kubectl exec -it -n ollama deployment/ollama -- sh

# Installer intel-gpu-tools si nécessaire
apk add intel-gpu-tools

# Monitorer le GPU
intel_gpu_top
```

### Logs Ollama

```bash
# Logs en temps réel
kubectl logs -f -n ollama deployment/ollama

# Logs récents
kubectl logs -n ollama deployment/ollama --tail=100
```

### Logs Open WebUI

```bash
kubectl logs -f -n open-webui deployment/open-webui
```

### Métriques via Prometheus

Les métriques sont disponibles via le stack de monitoring:
- Prometheus: https://prometheus.technovise.local
- Grafana: https://grafana.technovise.local

Requêtes PromQL utiles:
```promql
# Utilisation CPU Ollama
rate(container_cpu_usage_seconds_total{namespace="ollama"}[5m])

# Utilisation mémoire
container_memory_working_set_bytes{namespace="ollama"}

# Utilisation GPU Intel
gpu_usage_percent{namespace="ollama"}
```

## 🐛 Dépannage

### Ollama ne démarre pas

```bash
# Vérifier les events
kubectl describe pod -n ollama -l app.kubernetes.io/name=ollama

# Vérifier si le GPU est accessible
kubectl exec -it -n ollama deployment/ollama -- ls -la /dev/dri

# Devrait afficher:
# drwxr-xr-x ... /dev/dri/
# crw-rw---- ... /dev/dri/card0
# crw-rw---- ... /dev/dri/renderD128
```

### Open WebUI ne peut pas contacter Ollama

```bash
# Tester la connectivité depuis le pod Open WebUI
kubectl exec -it -n open-webui deployment/open-webui -- sh

# Installer curl si nécessaire
apk add curl

# Tester l'API Ollama
curl http://ollama.ollama.svc.cluster.local:11434/api/tags
```

### Modèle trop grand pour la RAM

Si vous obtenez une erreur "out of memory":

1. Utiliser un modèle plus petit:
   ```bash
   # Au lieu de llama3.2 (7B), essayer:
   ollama pull llama3.2:3b
   ```

2. Ou augmenter les limites mémoire dans `ollama-app.yaml`:
   ```yaml
   resources:
     limits:
       memory: 24Gi  # Augmenter si disponible sur le noeud
   ```

### HTTPRoute ne fonctionne pas

```bash
# Vérifier le status du HTTPRoute
kubectl get httproute -n ollama -o yaml
kubectl get httproute -n open-webui -o yaml

# Vérifier que le Gateway est prêt
kubectl get gateway -n istio-ingress technovise-gateway

# Tester l'accès direct au service (sans gateway)
kubectl port-forward -n ollama svc/ollama 11434:11434
curl http://localhost:11434/api/tags

kubectl port-forward -n open-webui svc/open-webui 8080:8080
# Ouvrir http://localhost:8080 dans le navigateur
```

## 🔐 Sécurité

### Authentification Open WebUI

Par défaut, l'authentification est activée. Options:

1. **Inscription libre** (défaut):
   - Premier utilisateur = admin
   - Autres utilisateurs peuvent s'inscrire

2. **Désactiver l'inscription** (après création admin):
   ```yaml
   extraEnvVars:
     - name: ENABLE_SIGNUP
       value: "false"
   ```

3. **Authentification externe** (OAuth, LDAP):
   Voir: https://docs.openwebui.com/tutorials/authentication

### Isolation réseau

Les services sont en ClusterIP par défaut:
- Accessible uniquement via le Gateway
- Pas d'exposition directe sur NodePort/LoadBalancer

Pour ajouter des NetworkPolicies:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ollama-allow-openwebui
  namespace: ollama
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ollama
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: open-webui
      ports:
      - protocol: TCP
        port: 11434
```

## 📚 Ressources

- **Ollama**:
  - Documentation: https://ollama.ai/
  - Modèles disponibles: https://ollama.ai/library
  - API Reference: https://github.com/ollama/ollama/blob/main/docs/api.md

- **Open WebUI**:
  - Documentation: https://docs.openwebui.com/
  - GitHub: https://github.com/open-webui/open-webui
  - Helm Chart: https://helm.openwebui.com/

- **Intel GPU Plugin**:
  - Guide déjà disponible: `docs/GPU-SHARING-GUIDE.md`

## 🎓 Exemples d'utilisation

### Cas d'usage 1: Assistant de code

```bash
# Via API
curl https://ollama.technovise.local/api/chat -d '{
  "model": "codellama",
  "messages": [
    {
      "role": "system",
      "content": "Tu es un assistant de code Python expert."
    },
    {
      "role": "user",
      "content": "Écris une fonction Python pour parser des logs Kubernetes"
    }
  ]
}'
```

### Cas d'usage 2: Documentation GitOps

Via Open WebUI (https://chat.technovise.local):
```
Prompt: "Explique-moi comment ajouter une nouvelle application dans ce 
repository GitOps avec ArgoCD. Inclus un exemple de HTTPRoute pour le 
Gateway API."
```

### Cas d'usage 3: Analyse de YAML

```bash
curl https://ollama.technovise.local/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    {
      "role": "user",
      "content": "Analyse ce manifest Kubernetes et identifie les problèmes potentiels:\n\n<coller votre YAML ici>"
    }
  ]
}'
```

## 🔄 Maintenance

### Mise à jour des versions

```bash
# Modifier la version du Helm chart dans les fichiers *-app.yaml:
# apps/ollama/ollama-app.yaml
targetRevision: 1.54.0  # → nouvelle version

# apps/open-webui/open-webui-app.yaml
targetRevision: 3.1.8  # → nouvelle version

# Sync via ArgoCD
argocd app sync ollama
argocd app sync open-webui
```

### Backup des données

#### Ollama (modèles):
```bash
# Les modèles sont dans le PVC
kubectl get pvc -n ollama

# Snapshot du PVC (si votre storage class le supporte)
# Ou copier manuellement:
kubectl exec -n ollama deployment/ollama -- tar czf /tmp/models.tar.gz /root/.ollama
kubectl cp ollama/ollama-pod:/tmp/models.tar.gz ./ollama-models-backup.tar.gz
```

#### Open WebUI (conversations):
```bash
# Conversations stockées dans le PVC
kubectl get pvc -n open-webui

# Export depuis l'UI: Settings → Data Export
```

---

**Dernière mise à jour**: 26 avril 2026
**Testé avec**:
- Ollama Helm Chart v1.54.0
- Open WebUI Helm Chart v3.1.8
- Kubernetes Gateway API v1.5.1
- Intel GPU Plugin + DRA
