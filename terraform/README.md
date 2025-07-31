# Terraform Proxmox k3s Infrastructure

This Terraform configuration provisions a 4-node k3s cluster on Proxmox for the homelab setup.

## Prerequisites

### 1. Proxmox Setup
- Proxmox VE 7.x or 8.x installed
- Ubuntu 22.04 cloud-init template created
- 32GB RAM upgrade installed
- 4TB HDD mounted at `/mnt/hdd-data` on Proxmox host

### 2. Create Ubuntu Cloud-Init Template

Download and create the Ubuntu 24.04 LTS template on your Proxmox host:

```bash
# SSH to your Proxmox host
cd /var/lib/vz/template/iso

# Ubuntu 24.04 LTS "Noble" (recommended - latest LTS)
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# Create VM template
qm create 9000 --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000
qm set 9000 --name ubuntu-24.04-cloudinit
```

### 3. Generate SSH Key Pair

If you don't have an SSH key pair:

```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
cat ~/.ssh/id_rsa.pub  # Copy this for terraform.tfvars
```

### 4. Set up HDD Storage

Ensure your 4TB HDD is mounted on the Proxmox host:

```bash
# On Proxmox host - verify mount exists
ls -la /mnt/hdd-data
df -h | grep hdd-data

# Create required directories if needed
mkdir -p /mnt/hdd-data/{media/{movies,tv,music},downloads,paperless/{documents,consume,export},config/backups,arr-data}
```

## Installation Steps

### 1. Install Terraform

```bash
# macOS
brew install terraform

# Linux
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 2. Configure Variables

Copy and customize the configuration:

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

- **proxmox_api_url**: Your Proxmox web interface URL
- **proxmox_user**: Usually `root@pam` for root user
- **proxmox_password**: Your Proxmox root password
- **proxmox_node**: Name of your Proxmox node (visible in web UI)
- **ssh_public_key**: Your SSH public key content
- **IP addresses**: Adjust to match your network

### 3. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. Verify Deployment

After successful deployment:

```bash
# Get cluster information
terraform output

# Test SSH access to master
ssh ubuntu@192.168.1.10

# Test SSH access to workers
ssh ubuntu@192.168.1.11
ssh ubuntu@192.168.1.12
ssh ubuntu@192.168.1.13

# Verify HDD mount on all nodes
ssh ubuntu@192.168.1.10 "df -h | grep hdd-data"
```

## Resource Allocation

- **Total RAM**: 28GB allocated (4GB buffer for Proxmox host)
- **Master**: 2 CPU cores, 4GB RAM, 32GB disk
- **Worker-1**: 4 CPU cores, 8GB RAM, 32GB disk (Plex transcoding)
- **Worker-2**: 3 CPU cores, 8GB RAM, 32GB disk (Arr suite)
- **Worker-3**: 3 CPU cores, 8GB RAM, 32GB disk (Paperless + qBittorrent)

## Next Steps

After VMs are provisioned:

1. **Install k3s**: Use the bash scripts in `../scripts/` directory
2. **Deploy ArgoCD**: Set up GitOps workflow
3. **Configure storage**: Set up persistent volumes with HDD access
4. **Deploy applications**: Install media stack and document management

## Troubleshooting

### Common Issues

**Template not found**:
```bash
# List available templates on Proxmox
qm list
```

**Network connectivity issues**:
- Verify bridge name (`vmbr0` is default)
- Check IP range doesn't conflict with existing devices
- Ensure gateway IP is correct

**Storage issues**:
```bash
# List storage pools on Proxmox
pvesm status
```

**SSH access denied**:
- Verify SSH public key is correctly formatted
- Check cloud-init logs: `sudo cat /var/log/cloud-init-output.log`

### Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

## Security Notes

- Default VM password is `changeme123` (change after deployment)
- SSH password authentication is disabled
- Only SSH key authentication is allowed
- VMs are configured with sudo access for the ubuntu user