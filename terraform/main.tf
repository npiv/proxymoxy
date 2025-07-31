resource "proxmox_vm_qemu" "k3s_master" {
  name        = var.master_vm.name
  target_node = var.proxmox_node
  clone       = var.vm_template
  
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.master_vm.cores
  sockets     = 1
  cpu         = "host"
  memory      = var.master_vm.memory
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot    = 0
    size    = var.master_vm.disk_size
    type    = "scsi"
    storage = var.storage_pool
  }

  network {
    model  = "virtio"
    bridge = var.network_bridge
  }

  cloudinit_cdrom_storage = var.storage_pool

  ipconfig0 = "ip=${var.master_vm.ip}/24,gw=${var.gateway}"
  
  ciuser     = var.vm_user
  cipassword = "changeme123"
  sshkeys    = var.ssh_public_key

  vm_state = "running"

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

resource "proxmox_vm_qemu" "k3s_workers" {
  for_each = var.worker_vms

  name        = each.value.name
  target_node = var.proxmox_node
  clone       = var.vm_template
  
  agent       = 1
  os_type     = "cloud-init"
  cores       = each.value.cores
  sockets     = 1
  cpu         = "host"
  memory      = each.value.memory
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    slot    = 0
    size    = each.value.disk_size
    type    = "scsi"
    storage = var.storage_pool
  }

  network {
    model  = "virtio"
    bridge = var.network_bridge
  }

  cloudinit_cdrom_storage = var.storage_pool

  ipconfig0 = "ip=${each.value.ip}/24,gw=${var.gateway}"
  
  ciuser     = var.vm_user
  cipassword = "changeme123"
  sshkeys    = var.ssh_public_key

  vm_state = "running"

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  depends_on = [proxmox_vm_qemu.k3s_master]
}