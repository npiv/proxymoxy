# Manual Proxmox k3s Cluster Setup Guide

This guide walks you through manually creating the k3s cluster VMs on Proxmox without Terraform.

## Prerequisites

- Proxmox VE installed and configured
- Ubuntu 24.04 cloud-init template created (see Template Creation section)
- 32GB RAM installed (4GB reserved for host, 28GB for VMs)
- SSH key pair generated
- Network: 192.168.1.0/24 with gateway at 192.168.1.1

## VM Configuration Overview

| VM Name | CPU Cores | RAM | Disk | IP Address |
|---------|-----------|-----|------|------------|
| k3s-master | 2 | 4GB | 32GB | 192.168.1.120 |
| k3s-worker-1 | 4 | 8GB | 32GB | 192.168.1.121 |
| k3s-worker-2 | 3 | 8GB | 32GB | 192.168.1.122 |
| k3s-worker-3 | 3 | 8GB | 32GB | 192.168.1.123 |

## Part 1: Create Ubuntu Cloud-Init Template

### Method 1: Proxmox Web UI

1. Download Ubuntu 24.04 cloud image:
   ```bash
   cd /var/lib/vz/template/iso
   wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img
   ```

2. Create VM template:
   - Go to **Datacenter > Node > Create VM**
   - **General**: VM ID: `9000`, Name: `ubuntu-24.04-cloudinit`
   - **OS**: Do not use any media
   - **System**: SCSI Controller: `VirtIO SCSI`, QEMU Agent: `Yes`
   - **Hard Disk**: Delete the default disk
   - **CPU**: Sockets: `1`, Cores: `1`, Type: `host`
   - **Memory**: `1024` MB
   - **Network**: Model: `VirtIO`, Bridge: `vmbr0`
   - **Confirm**: Click Finish

3. Import the cloud image:
   ```bash
   qm importdisk 9000 /var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img local-lvm
   ```

4. Configure the template:
   - Select VM 9000 > **Hardware**
   - **Add** > **Hard Disk**: Select the unused disk, Bus: `SCSI`, Device: `0`
   - **Add** > **CloudInit Drive**: Storage: `local-lvm`
   - **Options** > **Boot Order**: Enable `scsi0`
   - **Cloud-Init**: Set user/password, add SSH public key
   - Right-click VM > **Convert to template**

### Method 2: qm Commands

```bash
# Create base VM
qm create 9000 --name ubuntu-24.04-cloudinit --memory 1024 --cores 1 --net0 virtio,bridge=vmbr0

# Import cloud image
qm importdisk 9000 /var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img local-lvm

# Configure VM
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000
```

## Part 2: Create k3s-master VM

### Method 1: Proxmox Web UI

1. **Create VM from Template**:
   - Go to template VM 9000 > **More** > **Clone**
   - **Target**: Current node
   - **Mode**: Full clone
   - **Name**: `k3s-master`
   - **VM ID**: `120` (or any available)

2. **Configure Hardware**:
   - **CPU**: Cores: `2`, Type: `host`
   - **Memory**: `4096` MB (4GB)
   - **Hard Disk**: Resize to `32` GB
   - **Network**: Bridge: `vmbr0`, Model: `VirtIO`

3. **Configure Cloud-Init**:
   - **Cloud-Init** tab:
     - **User**: `ubuntu`
     - **Password**: `changeme123`
     - **SSH public key**: Paste your public key
     - **IP Config (net0)**: `ip=192.168.1.120/24,gw=192.168.1.1`
     - **DNS**: `8.8.8.8`

4. **Start VM**: Click **Start**

### Method 2: qm Commands

```bash
# Clone template
qm clone 9000 120 --name k3s-master --full

# Configure resources
qm set 120 --cores 2 --memory 4096
qm resize 120 scsi0 32G

# Configure network and cloud-init
qm set 120 --ipconfig0 ip=192.168.1.120/24,gw=192.168.1.1
qm set 120 --nameserver 8.8.8.8
qm set 120 --ciuser ubuntu
qm set 120 --cipassword changeme123
qm set 120 --sshkeys ~/.ssh/id_rsa.pub

# Start VM
qm start 120
```

## Part 3: Create k3s-worker VMs

### k3s-worker-1

#### Web UI Method:
1. Clone template (VM ID: `121`, Name: `k3s-worker-1`)
2. Configure: **CPU**: `4 cores`, **Memory**: `8192 MB`, **Disk**: `32GB`
3. **Cloud-Init**: IP: `192.168.1.121/24`, same user/key settings
4. Start VM

#### qm Commands:
```bash
qm clone 9000 121 --name k3s-worker-1 --full
qm set 121 --cores 4 --memory 8192
qm resize 121 scsi0 32G
qm set 121 --ipconfig0 ip=192.168.1.121/24,gw=192.168.1.1
qm set 121 --nameserver 8.8.8.8
qm set 121 --ciuser ubuntu --cipassword changeme123
qm set 121 --sshkeys ~/.ssh/id_rsa.pub
qm start 121
```

### k3s-worker-2

#### Web UI Method:
1. Clone template (VM ID: `122`, Name: `k3s-worker-2`)
2. Configure: **CPU**: `3 cores`, **Memory**: `8192 MB`, **Disk**: `32GB`
3. **Cloud-Init**: IP: `192.168.1.122/24`
4. Start VM

#### qm Commands:
```bash
qm clone 9000 122 --name k3s-worker-2 --full
qm set 122 --cores 3 --memory 8192
qm resize 122 scsi0 32G
qm set 122 --ipconfig0 ip=192.168.1.122/24,gw=192.168.1.1
qm set 122 --nameserver 8.8.8.8
qm set 122 --ciuser ubuntu --cipassword changeme123
qm set 122 --sshkeys ~/.ssh/id_rsa.pub
qm start 122
```

### k3s-worker-3

#### Web UI Method:
1. Clone template (VM ID: `123`, Name: `k3s-worker-3`)
2. Configure: **CPU**: `3 cores`, **Memory**: `8192 MB`, **Disk**: `32GB`
3. **Cloud-Init**: IP: `192.168.1.123/24`
4. Start VM

#### qm Commands:
```bash
qm clone 9000 123 --name k3s-worker-3 --full
qm set 123 --cores 3 --memory 8192
qm resize 123 scsi0 32G
qm set 123 --ipconfig0 ip=192.168.1.123/24,gw=192.168.1.1
qm set 123 --nameserver 8.8.8.8
qm set 123 --ciuser ubuntu --cipassword changeme123
qm set 123 --sshkeys ~/.ssh/id_rsa.pub
qm start 123
```

## Part 4: Verify VM Creation

### Check VM Status
```bash
# List all VMs
qm list

# Check specific VM status
qm status 120  # master
qm status 121  # worker-1
qm status 122  # worker-2
qm status 123  # worker-3
```

### Test SSH Access
```bash
# Test connectivity to all nodes
ssh ubuntu@192.168.1.120  # master
ssh ubuntu@192.168.1.121  # worker-1
ssh ubuntu@192.168.1.122  # worker-2
ssh ubuntu@192.168.1.123  # worker-3
```

## Part 5: Configure HDD Storage Mount

Each VM needs access to the 4TB HDD for persistent storage.

### Option 1: NFS Share (Recommended)

1. **On Proxmox Host**, export the HDD mount:
   ```bash
   # Install NFS server
   apt update && apt install nfs-kernel-server

   # Add to /etc/exports
   echo "/mnt/hdd-data 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
   
   # Apply changes
   exportfs -ra
   systemctl enable --now nfs-kernel-server
   ```

2. **On each VM**, mount the NFS share:
   ```bash
   # Install NFS client
   sudo apt update && sudo apt install nfs-common

   # Create mount point
   sudo mkdir -p /mnt/hdd-data

   # Add to /etc/fstab for persistent mount
   echo "192.168.1.1:/mnt/hdd-data /mnt/hdd-data nfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab

   # Mount immediately
   sudo mount -a
   ```

### Option 2: Directory Bind Mount

1. **Add storage to each VM** via Proxmox UI:
   - VM > **Hardware** > **Add** > **Hard Disk**
   - **Storage**: Select storage containing HDD
   - **Disk size**: Use existing disk or create bind mount

2. **Mount inside each VM**:
   ```bash
   sudo mkdir -p /mnt/hdd-data
   sudo mount /dev/sdb1 /mnt/hdd-data  # Adjust device as needed
   echo "/dev/sdb1 /mnt/hdd-data ext4 defaults 0 2" | sudo tee -a /etc/fstab
   ```

## Part 6: Next Steps

After completing this manual setup, you can proceed with:

1. **k3s Installation**: Install k3s on master, then join workers
2. **Storage Classes**: Configure persistent volume storage
3. **Ingress**: Set up Traefik for external access
4. **Applications**: Deploy Plex, arr suite, Paperless-ngx

## Quick Status Check Commands

```bash
# Check all VM status
for vm in 120 121 122 123; do
  echo "VM $vm: $(qm status $vm)"
done

# Ping all nodes
for ip in 120 121 122 123; do
  ping -c 1 192.168.1.$ip > /dev/null 2>&1 && echo "192.168.1.$ip: UP" || echo "192.168.1.$ip: DOWN"
done

# SSH connection test
for ip in 120 121 122 123; do
  ssh -o ConnectTimeout=5 ubuntu@192.168.1.$ip "echo 192.168.1.$ip: SSH OK" 2>/dev/null || echo "192.168.1.$ip: SSH FAILED"
done
```

## Troubleshooting

### VM Won't Start
- Check VM configuration: `qm config <vmid>`
- Verify template exists: `qm list`
- Check storage space: `df -h`

### Network Issues
- Verify bridge configuration: `ip link show vmbr0`
- Check DHCP conflicts: `nmap -sn 192.168.1.0/24`
- Test from Proxmox host: `ping 192.168.1.120`

### Cloud-Init Issues
- Check cloud-init logs: `sudo cloud-init status --long`
- Regenerate cloud-init: `sudo cloud-init clean --reboot`
- Verify SSH key format in Proxmox UI

Your k3s cluster VMs are now ready for Kubernetes installation!