locals {
  vms = {
    "app" = {
      hostname = "menu-app"
      ip       = "192.168.1.72"
      mac      = "02:00:00:01:00:01"
      memory   = 2048 # MiB
      vcpu     = 2
      disk_gb  = 10   # 20 GB
    },
    "db" = {
      hostname = "menu-db"
      ip       = "192.168.1.73"
      mac      = "02:00:00:01:00:02"
      memory   = 2048 
      vcpu     = 2
      disk_gb  = 10
    }
  }
}
