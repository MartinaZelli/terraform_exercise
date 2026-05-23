resource "libvirt_domain" "vm1" {
  name        = "vm1"
  type        = "kvm"
  memory      = 1024
  memory_unit = "MiB"
  vcpu        = 2
  running     = true

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "pc"
  }

  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = var.storage_pool
            volume = libvirt_volume.vm1_disk.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.vm1_init_iso.pool
            volume = libvirt_volume.vm1_init_iso.name
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      },
    ]

    interfaces = [
      {
        type  = "network"
        model = { type = "virtio" }
        //mac   = { address = local.control_mgmt_macs[count.index] }
        source = {
          network = {
            network = libvirt_network.network.name
          }
        }
      }
    ]

    rngs = [
      {
        model   = "virtio"
        backend = { random = "/dev/urandom" }
      },
    ]

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "127.0.0.1"
        }
      },
    ]
  }
}
