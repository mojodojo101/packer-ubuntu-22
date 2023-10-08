proxmox_host         = "10.50.3.1:8006"
proxmox_node         = "pve"
proxmox_api_user     = "Packer@pve!packer_token"
proxmox_token="cccc-xxxx-dddd-eee"
iso_url = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.1.0-amd64-netinst.iso"
iso_checksum = "sha512:9da6ae5b63a72161d0fd4480d0f090b250c4f6bf421474e4776e82eea5cb3143bf8936bf43244e438e74d581797fe87c7193bbefff19414e33932fe787b1400f"
iso_storage_pool   = "local"
# Dumb "spezial" configs for my pve node

disk_storage_pool   = "VMs"