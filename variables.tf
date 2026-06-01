variable "libvirt_uri" {
    description = "Libvirt URI to connect to the hypervisor"
    type        = string
    default     = "qemu:///system"
}
variable "storage_pool" {
  type        = string
  default     = "default"
  description = "Name of the libvirt storage pool"
}

variable "ubuntu_image_url" {
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  description = "URL of the Ubuntu cloud image to fetch as the base volume"
}

variable "dns1" {
  type    = string
  default = "1.1.1.1"
}

variable "dns2" {
  type    = string
  default = "8.8.8.8"
}

variable "ssh_public_key" {
    type        = string
    description = "Path to the SSH public key to be injected into the VM for access"
    default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJR1b9GQMkQZmRGpRzobVxAJ8aaqaB61+7pjV0xl/wwA"

}

variable "bridge_name" {
    type        = string
    default     = "bridge0"
    description = "Name of the libvirt bridge to attach the VM's network interface to"
}

variable "control_count" {
  type    = number
  default = 1
}
