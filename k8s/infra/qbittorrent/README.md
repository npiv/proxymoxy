# qBittorrent with Tailscale VPN Exit Nodes

This setup routes **only** qBittorrent traffic through Tailscale exit nodes (via Mullvad) while keeping other services like Sonarr on the local network.

## Architecture

```
qBittorrent ──→ Tailscale Sidecar ──→ Mullvad Exit Node ──→ Internet
Sonarr ──→ Local k3s Network ──→ qBittorrent API (cluster internal)
```

## Features

- ✅ Complete traffic isolation for qBittorrent
- ✅ Kill-switch prevents IP leaks if VPN fails  
- ✅ Sonarr maintains local network access
- ✅ Automatic VPN reconnection and monitoring
- ✅ DNS leak prevention
- ✅ Health checks and IP leak detection
- ✅ Network policies for additional security

## Prerequisites

1. **Tailscale Account** with Mullvad partnership access
2. **k3s cluster** with proper networking
3. **kubectl** configured to access your cluster

## Setup Instructions

### 1. Get Tailscale Authentication

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Generate an **ephemeral auth key** with:
   - ✅ Ephemeral (recommended for security)
   - ✅ Exit node access
   - ✅ Reusable (optional)

### 2. Choose Mullvad Exit Node

List available Mullvad exit nodes:
```bash
tailscale exit-node list | grep mullvad
```

Example nodes:
- `mullvad-us-nyc-01` (New York)
- `mullvad-nl-ams-01` (Amsterdam) 
- `mullvad-se-sto-01` (Stockholm)

### 3. Create Kubernetes Secret

**Important**: The secret must be created manually as it's not managed by ArgoCD to prevent credentials from being stored in Git.

```bash
kubectl create secret generic tailscale-auth \
  --namespace=infra \
  --from-literal=TS_AUTHKEY="tskey-auth-YOUR-ACTUAL-KEY-HERE" \
  --from-literal=TS_EXIT_NODE="mullvad-us-nyc-01" \
  --from-literal=TS_API_KEY=""
```

If the secret already exists (from a previous deployment attempt), delete it first:
```bash
kubectl delete secret tailscale-auth -n infra
# Then create the new one with real values
```

### 4. Apply Kubernetes Manifests

Apply the files in order:

```bash
# Note: Secrets are created manually (see step 3 above)

# Apply ConfigMaps
kubectl apply -f 01-configmap.yaml

# Apply storage (if not already present)
kubectl apply -f 02-storage.yaml

# Apply deployment with VPN sidecar
kubectl apply -f 03-deployment.yaml

# Apply services
kubectl apply -f 04-services.yaml

# Apply network policies (optional but recommended)
kubectl apply -f 05-network-policies.yaml
```

### 5. Verify Setup

Run the validation script:

```bash
chmod +x test-setup.sh
./test-setup.sh
```

This will test:
- Pod status and health
- Tailscale connection
- VPN interface availability
- IP leak detection
- DNS configuration
- Web UI accessibility
- Exit node verification

## Usage

### Accessing qBittorrent

- **Web UI**: `http://192.168.1.205:8080` (external)
- **Cluster Internal**: `qbittorrent-internal.infra.svc.cluster.local:8080`

### Configuring Sonarr

Update Sonarr's Download Client settings:
- **Host**: `qbittorrent-internal.infra.svc.cluster.local`
- **Port**: `8080`
- **Username/Password**: As configured in qBittorrent

### Monitoring VPN Status

Check Tailscale connection:
```bash
kubectl exec -n infra deployment/qbittorrent -c tailscale -- tailscale status
```

Check current IP:
```bash
kubectl exec -n infra deployment/qbittorrent -c qbittorrent -- curl -s --interface tun0 https://ipinfo.io/json
```

## Troubleshooting

### Pod Won't Start

1. Check secret exists:
   ```bash
   kubectl get secret tailscale-auth -n infra
   ```

2. Check auth key validity:
   ```bash
   kubectl logs -n infra deployment/qbittorrent -c tailscale
   ```

### VPN Connection Issues

1. Check Tailscale logs:
   ```bash
   kubectl logs -n infra deployment/qbittorrent -c tailscale
   ```

2. Verify exit node availability:
   ```bash
   tailscale exit-node list | grep mullvad
   ```

3. Test connectivity:
   ```bash
   kubectl exec -n infra deployment/qbittorrent -c tailscale -- tailscale ping your-exit-node
   ```

### IP Leak Detection

Run IP leak test manually:
```bash
# Should show Mullvad IP
kubectl exec -n infra deployment/qbittorrent -c qbittorrent -- curl -s --interface tun0 https://ipinfo.io/json

# Should fail (timeout or blocked)
kubectl exec -n infra deployment/qbittorrent -c qbittorrent -- curl -s --max-time 5 https://ipinfo.io/json
```

### Sonarr Can't Connect

1. Test internal service:
   ```bash
   kubectl run test-pod --rm -i --tty --image=busybox --restart=Never \
     -- wget -qO- http://qbittorrent-internal.infra.svc.cluster.local:8080
   ```

2. Check network policies:
   ```bash
   kubectl get networkpolicy -n infra
   ```

## Security Notes

1. **Kill Switch**: If VPN fails, qBittorrent container will restart
2. **Network Binding**: qBittorrent is configured to bind only to VPN interface
3. **IP Leak Prevention**: Health checks monitor for IP leaks
4. **Network Policies**: Additional layer of traffic control
5. **Ephemeral Keys**: Use ephemeral auth keys for better security

## Performance Considerations

- **Bandwidth**: Depends on chosen Mullvad exit node location
- **Latency**: Choose geographically close exit nodes for better performance
- **Resources**: VPN sidecar uses minimal resources (~50m CPU, 128Mi RAM)

## Cleanup

To remove the VPN setup and revert to standard qBittorrent:

```bash
# Remove network policies
kubectl delete -f 05-network-policies.yaml

# Remove VPN deployment  
kubectl delete -f 03-deployment.yaml

# Remove secrets
kubectl delete secret tailscale-auth -n infra

# Apply original deployment (backup recommended)
# kubectl apply -f 03-deployment-original.yaml
```