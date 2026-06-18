locals {
  # Configurazione standard per evitare ripetizioni
  vm_default = {
    memory  = 2048
    vcpu    = 2
    disk_gb = 10
  }

  vms_raw = {
    "app" = {
      hostname = "menu-app"
      ip       = "192.168.1.72"
      mac      = "02:00:00:01:00:01"
    },
    "app2" = {
      hostname = "menu-app-2"
      ip       = "192.168.1.74"
      mac      = "02:00:00:01:00:03"
    },
    "db" = {
      hostname = "menu-db"
      ip       = "192.168.1.73"
      mac      = "02:00:00:01:00:02"
    },
    "lb" = {
      hostname = "menu-lb"
      ip       = "192.168.1.75"
      mac      = "02:00:00:01:00:04"
      # Esempio: se il load balancer avesse bisogno di meno RAM, potresti fare:
      # memory = 1024
    },
    "ldap" = {
      hostname = "ldap"
      ip       = "192.168.1.76"
      mac      = "02:00:00:01:00:05"
      memory   = 1024                    # override: LDAP è leggero, dimezzo i 2048 di default
      vcpu     = 1                       # override: gli basta 1 vCPU
    },
    "dc" = {
      hostname = "dc1"
      ip       = "192.168.1.77"
      mac      = "02:00:00:01:00:06"
      memory   = 4096                    # override: il Domain Controller ha bisogno di più RAM
    }
  }
  # Costruisce la mappa finale delle VM iniettando i parametri hardware di default
  vms = {
    for vm_id, vm_config in local.vms_raw : vm_id => merge(local.vm_default, vm_config)
  }
}
