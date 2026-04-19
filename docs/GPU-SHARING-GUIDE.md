# Guide de Partage GPU Intel avec Kubernetes

## 🎯 Solutions de Partage GPU

### Option 1: DRA (Dynamic Resource Allocation) - Moderne ✨
**Status**: Stable depuis K8s 1.34, vous avez v1.35 ✅

#### Architecture DRA
```
ResourceClass (config partage)
    ↓
ResourceClaim (demande par pod)
    ↓
DRA Driver (allocation dynamique)
    ↓
GPU partagé entre pods
```

#### Avantages:
- ✅ Partage natif (jusqu'à 10 pods/GPU)
- ✅ Allocation dynamique (pas de pre-allocation)
- ✅ Monitoring granulaire
- ✅ Future-proof (remplace Device Plugins)

#### Inconvénients:
- ⚠️ Driver Intel DRA récent (v0.6.0+, avril 2026)
- ⚠️ Nécessite migration des déploiements
- ⚠️ Moins de documentation

---

### Option 2: Device Plugin avec `shared-dev-num` - Éprouvé 🔧
**Status**: Production-ready depuis des années

#### Configuration simple:
```yaml
# Dans intel-gpu-plugin DaemonSet, ajouter:
args:
  - -shared-dev-num=5  # Permet 5 "copies" du GPU
```

#### Avantages:
- ✅ Très simple (1 ligne)
- ✅ Compatible avec vos déploiements actuels
- ✅ Testé en production
- ✅ Aucune migration nécessaire

#### Inconvénients:
- ⚠️ Partage "simulé" (pas de vraie isolation mémoire)
- ⚠️ Scheduler pense qu'il y a 5 GPUs (illusion)
- ⚠️ Deprecated à long terme

---

## 🚀 Recommandation pour VOTRE cas

### Scénario 1: Production rapide → **Device Plugin shared**
Si vous voulez une solution qui marche **maintenant**:

```bash
# apps/intel-gpu-plugin/manifests/intel-gpu-plugin.yaml
# Ajoutez simplement: -shared-dev-num=5
```

**Résultat immédiat**:
- `gpu.intel.com/i915: 5` (au lieu de 1)
- Ollama et OpenVINO peuvent tous deux demander 1 GPU
- Fonctionne en < 5 minutes

### Scénario 2: Architecture moderne → **DRA**
Si vous investissez pour l'avenir:

```yaml
# Les pods utilisent ResourceClaims au lieu de resources
resourceClaims:
  - name: gpu
    resourceClaimTemplateName: intel-gpu-shared
```

**Nécessite**:
- Migration des déploiements Ollama + OpenVINO
- Test du driver Intel DRA (nouveau)
- 1-2 heures de configuration

---

## 📊 Comparaison Technique

| Critère | Device Plugin Shared | DRA |
|---------|---------------------|-----|
| **Temps setup** | 5 min | 1-2h |
| **Compatibilité** | 100% | Nécessite migration |
| **Isolation mémoire** | ❌ Non | ✅ Oui |
| **Monitoring** | Basic | Avancé |
| **Future-proof** | 2-3 ans | 10+ ans |
| **Risk** | Zéro | Moyen (nouveau) |

---

## 💡 Ma Recommandation

**Pour votre use case (Ollama + OpenVINO prototype)**:

### Phase 1: Quick Win (NOW)
```bash
# Modifier Device Plugin avec shared-dev-num=5
# Réactiver GPU sur OpenVINO
# Total: 10 minutes
```

### Phase 2: Migration DRA (Q3 2026)
```bash
# Quand Intel DRA sera plus mature
# Migrer progressivement vers ResourceClaims
```

---

## 🛠️ Quelle option voulez-vous ?

**A**: Device Plugin Shared (5 min, zéro risque) 
**B**: DRA moderne (1-2h, architecture future-proof)
**C**: Les deux (Device Plugin maintenant, DRA en test parallèle)
