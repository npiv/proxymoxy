#!/bin/bash
set -e

echo "Installing ArgoCD..."

# Create argocd namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD components to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-dex-server -n argocd
kubectl wait --for=condition=available --timeout=600s deployment/argocd-redis -n argocd
kubectl wait --for=condition=available --timeout=600s deployment/argocd-repo-server -n argocd
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Patch ArgoCD server service to use NodePort for initial access
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"port":80,"nodePort":30080,"name":"http"},{"port":443,"nodePort":30443,"name":"https"}]}}'

echo "ArgoCD installed successfully!"
echo "Access ArgoCD at: https://192.168.1.120:30443"
echo ""
echo "Get admin password with:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"