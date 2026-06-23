locals {
  # Configurazione standard per evitare ripetizioni
  vm_default = {
    memory  = 1024
    vcpu    = 1
    disk_gb = 10
  }

  vms_raw = {
    # --- VM dell'applicazione: parcheggiate finché non rifacciamo l'app ---
    # Per riattivarle: togli il commento e fai 'tofu apply'.
    # "app" = {
    #   hostname = "menu-app"
    #   ip       = "192.168.1.72"
    #   mac      = "02:00:00:01:00:01"
    # },
    # "app2" = {
    #   hostname = "menu-app-2"
    #   ip       = "192.168.1.74"
    #   mac      = "02:00:00:01:00:03"
    # },
    # "db" = {
    #   hostname = "menu-db"
    #   ip       = "192.168.1.73"
    #   mac      = "02:00:00:01:00:02"
    # },
    "lb" = {
      hostname = "menu-lb"
      ip       = "192.168.1.75"
      mac      = "02:00:00:01:00:04"

    },
    "ldap" = {
      hostname = "ldap"
      ip       = "192.168.1.76"
      mac      = "02:00:00:01:00:05"
    },
    "dc" = {
      hostname = "dc1"
      ip       = "192.168.1.77"
      mac      = "02:00:00:01:00:06"
      memory   = 2048 # a riposo bastano; per RI-provisionare il dominio bumpa a 4096
      vcpu     = 2
    }
  }
  # Costruisce la mappa finale delle VM iniettando i parametri hardware di default
  vms = {
    for vm_id, vm_config in local.vms_raw : vm_id => merge(local.vm_default, vm_config)
  }
}
