resource "libvirt_network" "network" {
  name      = "network"
  autostart = true

  bridge = {
    name = var.bridge_name
  }

  forward = {
    mode = "bridge"
  }
}
