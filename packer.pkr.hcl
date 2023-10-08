packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.5"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}


variable "iso_url" {
  type = string
}

variable "iso_checksum" {
  type = string
}

variable "iso_storage_pool" {
  type = string
  default= "local-lvm"
}

variable "cloudinit_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "cores" {
  type    = string
  default = "2"
}

variable "disk_format" {
  type    = string
  default = "raw"
}

variable "disk_size" {
  type    = string
  default = "20G"
}

variable "disk_storage_pool" {
  type    = string
  default = "local-lvm"
}

variable "cpu_type" {
  type    = string
  default = "kvm64"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "network_vlan" {
  type    = string
  default = ""
}

variable "machine_type" {
  type    = string
  default = ""
}

variable "proxmox_api_password" {
  type      = string
  sensitive = true
  default = ""
}

variable "proxmox_api_user" {
  type = string
  default = ""
}


variable "proxmox_token" {
  type = string
  default = ""
}

variable "proxmox_host" {
  type = string
}

variable "proxmox_node" {
  type = string
}

source "proxmox-iso" "debian" {
  proxmox_url              = "https://${var.proxmox_host}/api2/json"
  insecure_skip_tls_verify = true
  username                 = var.proxmox_api_user
  #password                 = var.proxmox_api_password
  token = var.proxmox_token


  ssh_password = "packer"
  ssh_username = "root"
  ssh_timeout  = "30m"
  ssh_handshake_attempts= "50"

  template_description = "Built from ${basename(var.iso_url)} on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
  node                 = var.proxmox_node

  disks {
    disk_size    = var.disk_size
    format       = var.disk_format
    io_thread    = true
    storage_pool = var.disk_storage_pool
    type         = "scsi"
  }
  scsi_controller = "virtio-scsi-single"
  iso_download_pve = true
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum
  iso_storage_pool = var.iso_storage_pool

  boot_wait      = "10s"
  boot_command   = ["<esc><wait>auto priority=critical interface=ens19  url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/<enter>"]

  http_directory           = "http"

  unmount_iso    = true

  cloud_init              = true
  cloud_init_storage_pool = var.cloudinit_storage_pool

  vm_id    = 901
  vm_name  = trimsuffix(basename(var.iso_url), ".iso")
  cpu_type = var.cpu_type
  os       = "l26"
  memory   = var.memory
  cores    = var.cores
  sockets  = "1"
  machine  = var.machine_type


  network_adapters {
    bridge = "vmbr2"
    model  = "virtio"
    firewall = true
  }
}


build {

    name = "ubuntu-server-focal"
    sources = ["source.proxmox-iso.debian"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

    # Add additional provisioning scripts here
    # ...
}