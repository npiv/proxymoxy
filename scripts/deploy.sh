#!/bin/bash
set -e

echo "Deploying Proxmox k3s homelab infrastructure..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available and cluster is accessible
print_status "Checking k3s cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to k3s cluster. Please ensure k3s is running and kubeconfig is set."
    exit 1
fi

# Install ArgoCD
print_status "Installing ArgoCD..."
./argocd/install-argocd.sh

# Wait for ArgoCD to be ready
print_status "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Apply infrastructure manifests in correct order
print_status "Creating namespaces first..."
kubectl apply -f k8s-manifests/infrastructure/storage/namespace.yaml
kubectl apply -f k8s-manifests/infrastructure/pihole/namespace.yaml

print_status "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml

print_status "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager

print_status "Applying cert-manager cluster issuers..."
kubectl apply -f k8s-manifests/infrastructure/cert-manager/cluster-issuer.yaml

print_status "Applying storage configuration..."
kubectl apply -f k8s-manifests/infrastructure/storage/

print_status "Applying Pi-hole manifests..."
kubectl apply -f k8s-manifests/infrastructure/pihole/

# Wait for infrastructure to be ready
print_status "Waiting for infrastructure components..."
kubectl wait --for=condition=available --timeout=300s deployment/pihole -n infrastructure || true

print_status "Note: Using k3s built-in Traefik (already running)"

# Deploy ArgoCD applications
print_status "Deploying ArgoCD applications..."
kubectl apply -f argocd/app-of-apps.yaml
kubectl apply -f argocd/applications/

print_status "Deployment completed!"
echo ""
echo "=== Initial Setup Required ==="
echo "1. Configure Pi-hole as primary DNS in your DHCP server"
echo "2. Use 8.8.8.8 as secondary DNS"
echo "3. Pi-hole will resolve *.homelab.local domains"
echo ""
echo "=== Access URLs ==="
echo "Direct NodePort Access:"
echo "- ArgoCD: https://any-node-ip:30443"
echo "- Traefik (k3s built-in): http://any-node-ip:80 or https://any-node-ip:443"
echo "- Pi-hole: http://any-node-ip:30850"
echo "- Pi-hole DNS: Configure devices to use any-node-ip:30853"
echo "- Plex: http://any-node-ip:32400"
echo ""
echo "Via Pi-hole DNS (after DNS setup):"
echo "- ArgoCD: https://argocd.homelab.local"
echo "- Traefik: https://traefik.homelab.local" 
echo "- Pi-hole: https://pihole.homelab.local"
echo "- Plex: https://plex.homelab.local"
echo "- Sonarr: https://sonarr.homelab.local"
echo "- Radarr: https://radarr.homelab.local"
echo "- Bazarr: https://bazarr.homelab.local"
echo "- Prowlarr: https://prowlarr.homelab.local"
echo "- qBittorrent: https://qbittorrent.homelab.local"
echo "- Paperless: https://paperless.homelab.local"
echo ""
echo "=== Next Steps ==="
echo "1. Get ArgoCD admin password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "2. Configure Pi-hole custom DNS entries (if needed):"
echo "   Access Pi-hole admin → Local DNS → Add entries for *.homelab.local"
echo ""
echo "3. Update DHCP server to use Pi-hole IP as primary DNS"