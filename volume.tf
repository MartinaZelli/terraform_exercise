resource "libvirt_volume" "ubuntu" {
  name = "ubuntu.qcow2"
  pool = var.storage_pool

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = var.ubuntu_image_url
    }
  }
}

resource "libvirt_volume" "vm1_disk" {
  name     = "vm1.qcow2"
  pool     = var.storage_pool
  capacity = 10240

  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path = libvirt_volume.ubuntu.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_volume" "vm1_init_iso" {
  name  = "vm1-init.iso"
  pool  = var.storage_pool

  create = {
    content = {
      url = libvirt_cloudinit_disk.vm1_init.path
    }
  }
}
