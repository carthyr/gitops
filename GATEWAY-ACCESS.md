# Guide d'accès aux applications Istio Gateway

## Configuration actuelle

- **LoadBalancer IP**: 192.168.10.150
- **Domaine**: intra.technovise.com
- **Gateway**: intra-technovise-gateway (istio-ingress namespace)

## Problème réseau détecté

Votre Mac est sur le réseau **192.168.8.x** mais le LoadBalancer MetalLB distribue des IPs sur **192.168.10.150-160**.

### Solutions possibles:

### Option 1: Ajuster le pool d'IPs MetalLB (Recommandé)

Modifiez le fichier `apps/metallb/config/ipaddresspool.yaml` pour utiliser le réseau 192.168.8.x :

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  # Utilisez une plage d'IPs disponibles sur votre réseau 192.168.8.x
  - 192.168.8.240-192.168.8.250
```

Puis appliquez la modification:
```bash
git add apps/metallb/config/ipaddresspool.yaml
git commit -m "Update MetalLB IP pool to 192.168.8.x network"
git push
```

### Option 2: Configuration DNS (après avoir résolu le réseau)

Ajoutez à votre `/etc/hosts`:
```
192.168.10.150  httpbin.intra.technovise.com
192.168.10.150  intra.technovise.com
```

Ou configurez votre DNS local (dnsmasq, etc).

### Option 3: Tester avec NodePort (solution temporaire)

```bash
# Trouver le NodePort pour HTTP
kubectl get svc -n istio-ingress istio-ingressgateway

# Tester avec l'IP du noeud
curl -H "Host: httpbin.intra.technovise.com" http://<IP_DU_NOEUD>:<NODEPORT>/get
```

## Applications déployées

### httpbin (demo)
- URL: https://httpbin.intra.technovise.com
- Namespace: demo-app
- VirtualService: httpbin

## Tests

```bash
# HTTP (redirige vers HTTPS)
curl -v http://httpbin.intra.technovise.com/get

# HTTPS avec certificat auto-signé
curl -k https://httpbin.intra.technovise.com/get

# Vérifier les headers
curl -k https://httpbin.intra.technovise.com/headers
```

## Ajouter une nouvelle application

1. Créez un VirtualService dans `apps/istio-gateway/gateway-config/`
2. Référencez le Gateway: `istio-ingress/intra-technovise-gateway`
3. Le certificat wildcard `*.intra.technovise.com` est déjà configuré
