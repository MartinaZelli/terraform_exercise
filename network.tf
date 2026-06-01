resource "libvirt_network" "network" {
  name      = "network"
  autostart = true

  bridge = {
    name = var.bridge_name
  }

  //domain = {
  //  name = "local"
 // }

  forward = {
    mode = "bridge"
  }
}
