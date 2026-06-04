resource "libvirt_domain" "vm" {
  for_each    = local.vms
  name        = each.value.hostname
  type        = "kvm"
  memory      = each.value.memory
  memory_unit = "MiB"
  vcpu        = each.value.vcpu
  running     = true
  autostart   = true

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
            volume = libvirt_volume.vm_disk[each.key].name
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
            pool   = libvirt_volume.vm_init_iso[each.key].pool
            volume = libvirt_volume.vm_init_iso[each.key].name
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
        mac   = { address = each.value.mac }
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
