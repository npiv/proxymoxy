# Proxmox k3s Homelab

Infrastructure as Code setup for a Kubernetes homelab running Plex, Arr services, and document management on Proxmox VMs.

## Architecture

- **k3s-master** (192.168.1.120): 2 CPU, 4GB RAM - Kubernetes control plane
- **k3s-worker-1** (192.168.1.121): 4 CPU, 8GB RAM - Plex Media Server
- **k3s-worker-2** (192.168.1.122): 3 CPU, 8GB RAM - Sonarr, Radarr, Bazarr, Prowlarr
- **k3s-worker-3** (192.168.1.123): 3 CPU, 8GB RAM - qBittorrent, Paperless-ngx

## Services

### Media Stack (Namespace: media)
- **Plex** - Media server (worker-1)
- **Sonarr** - TV show management (worker-2)
- **Radarr** - Movie management (worker-2)
- **Bazarr** - Subtitle management (worker-2)
- **Prowlarr** - Indexer management (worker-2)
- **qBittorrent** - Torrent client (worker-3)

### Document Management (Namespace: documents)
- **Paperless-ngx** - Document management system (worker-3)

### Infrastructure
- **ArgoCD** - GitOps deployment
- **Traefik** - Ingress controller with SSL
- **cert-manager** - SSL certificate management
- **NFS Storage** - Shared storage for media files

## Quick Start

1. **Prerequisites**: Follow setup guides for Proxmox VMs and k3s installation:
   - `1_SETUP_PROXMOX_HOSTS.md`
   - `2_SETUP_K3S.md`

2. **Deploy infrastructure**:
   ```bash
   ./scripts/deploy.sh
   ```

3. **Access services**:
   - ArgoCD: `https://192.168.1.120:30443`
   - Traefik Dashboard: `http://192.168.1.120:30808`
   - Plex: `http://192.168.1.121:32400`

## Configuration

### Storage
- **NFS**: 4TB HDD mounted at `/mnt/hdd-data` on Proxmox host, shared via NFS
- **Local**: SSD storage for application configs and databases

### Network
- **NodePort**: Direct access to services
- **Ingress**: HTTPS access via Traefik with Let's Encrypt certificates

### GitOps
All applications are managed via ArgoCD. Changes to `k8s-manifests/` are automatically deployed.

## Customization

1. **Update domains**: Replace `local.example.com` in ingress files with your domain
2. **Update email**: Set your email in cert-manager cluster issuer
3. **Update timezone**: Set `TZ` environment variable in deployments
4. **Update Plex claim**: Get token from https://www.plex.tv/claim/

## Monitoring

ArgoCD provides deployment status and health monitoring for all applications. Access the dashboard to view:
- Application sync status
- Resource health
- Deployment history
- Configuration drift detection