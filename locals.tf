locals {
  vms = {
    "app" = {
      hostname = "menu-app"
      ip       = "192.168.1.72"
      mac      = "02:00:00:01:00:01"
      memory   = 2048 # MiB
      vcpu     = 2
      disk_gb  = 10
    },
    "app2" = {
      hostname = "menu-app-2"
      ip       = "192.168.1.74"
      mac      = "02:00:00:01:00:03"
      memory   = 2048
      vcpu     = 2
      disk_gb  = 10
    },
    "db" = {
      hostname = "menu-db"
      ip       = "192.168.1.73"
      mac      = "02:00:00:01:00:02"
      memory   = 2048
      vcpu     = 2
      disk_gb  = 10
    },
    "lb" = {
      hostname = "menu-lb"
      ip       = "192.168.1.75"          # <-- IP dedicato al Load Balancer
      mac      = "02:00:00:01:00:04"      # <-- Nuovo MAC Address univoco
      memory   = 2048
      vcpu     = 2
      disk_gb  = 10
    }
  }
}
