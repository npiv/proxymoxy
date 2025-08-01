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

# Apply infrastructure manifests directly first
print_status "Applying infrastructure manifests..."
kubectl apply -k k8s-manifests/infrastructure/

# Wait for infrastructure to be ready
print_status "Waiting for infrastructure components..."
kubectl wait --for=condition=available --timeout=300s deployment/traefik -n traefik || true

# Deploy ArgoCD applications
print_status "Deploying ArgoCD applications..."
kubectl apply -f argocd/app-of-apps.yaml
kubectl apply -f argocd/applications/

print_status "Deployment completed!"
echo ""
echo "Access URLs (update /etc/hosts or use your domain):"
echo "- ArgoCD: https://192.168.1.120:30443"
echo "- Traefik Dashboard: http://192.168.1.120:30808"
echo "- Plex: http://192.168.1.121:32400"
echo "- Sonarr: http://sonarr.local.example.com (via Traefik)"
echo "- Radarr: http://radarr.local.example.com (via Traefik)"
echo "- qBittorrent: http://qbittorrent.local.example.com (via Traefik)"
echo ""
echo "Get ArgoCD admin password:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"