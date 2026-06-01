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

resource "libvirt_volume" "vm_disk" {
  count    = var.control_count
  name     = "vm-${count.index}.qcow2"
  pool     = var.storage_pool
  capacity = 20737418240


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

resource "libvirt_volume" "vm_init_iso" {
  count = var.control_count
  name  = "vm-${count.index}-init.iso"
  pool  = var.storage_pool

  create = {
    content = {
      url = libvirt_cloudinit_disk.vm_init[count.index].path
    }
  }
}
