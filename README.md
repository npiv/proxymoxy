# Proxmox k3s Homelab

Infrastructure as Code setup for a Kubernetes homelab running Plex, Arr services, and document management on Proxmox VMs with Pi-hole DNS.

## Architecture

- **k3s-master** (192.168.1.120): 2 CPU, 4GB RAM - Kubernetes control plane
- **k3s-worker-1** (192.168.1.121): 4 CPU, 8GB RAM - Dynamic pod scheduling
- **k3s-worker-2** (192.168.1.122): 3 CPU, 8GB RAM - Dynamic pod scheduling  
- **k3s-worker-3** (192.168.1.123): 3 CPU, 8GB RAM - Dynamic pod scheduling

**Note**: Services are scheduled dynamically by Kubernetes across available worker nodes for optimal resource utilization and high availability.

## Services

### Media Stack (Namespace: media)
- **Plex** - Media server with hardware transcoding support
- **Sonarr** - TV show management and automation
- **Radarr** - Movie management and automation
- **Bazarr** - Subtitle management and automation
- **Prowlarr** - Indexer management for *arr services
- **qBittorrent** - Torrent client with web interface

### Document Management (Namespace: documents)
- **Paperless-ngx** - Document digitization and management

### Infrastructure (Namespace: infrastructure)
- **Pi-hole** - DNS server with ad-blocking and local domain resolution
- **ArgoCD** - GitOps deployment and application management
- **Traefik** - Ingress controller with automatic SSL certificates
- **cert-manager** - SSL certificate management with Let's Encrypt
- **NFS Storage** - Shared storage for media files on 4TB HDD

## Quick Start

1. **Prerequisites**: Follow setup guides for Proxmox VMs and k3s installation:
   - `1_SETUP_PROXMOX_HOSTS.md`
   - `2_SETUP_K3S.md`

2. **Deploy infrastructure**:
   ```bash
   ./scripts/deploy.sh
   ```

3. **Configure DNS**:
   - Update your router's DHCP settings to use Pi-hole as primary DNS
   - Set Pi-hole IP (discovered after deployment) as primary DNS
   - Set 8.8.8.8 as secondary DNS

4. **Access services**:
   - **Direct access**: Use NodePort URLs provided by deployment script
   - **Domain access**: Use https://servicename.homelab.local after DNS setup

## Configuration

### Storage
- **NFS**: 4TB HDD mounted at `/mnt/hdd-data` on Proxmox host, shared via NFS
- **Local**: SSD storage for application configs and databases

### Network & DNS
- **Pi-hole**: Provides local DNS resolution for `.homelab.local` domains
- **NodePort**: Direct access to critical services (Pi-hole DNS, Plex discovery)
- **Ingress**: HTTPS access via Traefik with automatic SSL certificates
- **Load Balancing**: Traefik distributes traffic across available pods

### GitOps
All applications are managed via ArgoCD with automatic sync. Changes to `k8s-manifests/` trigger deployments.

### Dynamic Scheduling
Services are not tied to specific nodes, allowing Kubernetes to:
- Schedule pods based on resource availability
- Provide high availability through rescheduling
- Optimize resource utilization across the cluster

## Customization

1. **Update Pi-hole password**: Change `WEBPASSWORD` in Pi-hole deployment
2. **Update email**: Set your email in cert-manager cluster issuer  
3. **Update timezone**: Set `TZ` environment variable in deployments
4. **Update Plex claim**: Get token from https://www.plex.tv/claim/
5. **Custom domains**: Modify Pi-hole ConfigMap for additional local domains

## Monitoring

ArgoCD provides deployment status and health monitoring for all applications. Access the dashboard to view:
- Application sync status
- Resource health
- Deployment history
- Configuration drift detection