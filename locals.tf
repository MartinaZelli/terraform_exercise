locals {

  # --- parametri di dominio del lab (centralizzati) ---
  ad_domain   = "ad.lab.home"        # dominio Active Directory
  base_domain = "lab.home"           # dominio per le macchine NON membri AD
  dc_ip       = "192.168.1.77"       # il DC: è il DNS dei membri
  public_dns  = [var.dns1, var.dns2] # DNS pubblici (bootstrap / non-membri)

  # --- default hardware + RUOLO ---
  vm_default = {
    memory               = 1024
    vcpu                 = 1
    disk_gb              = 10
    ad_member            = true  # default: la VM si unisce al dominio AD
    is_domain_controller = false # true SOLO per il DC
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
      hostname  = "ldap"
      ip        = "192.168.1.76"
      mac       = "02:00:00:01:00:05"
      ad_member = false
    },
    "dc" = {
      hostname             = "dc1"
      ip                   = "192.168.1.77"
      mac                  = "02:00:00:01:00:06"
      memory               = 2048
      vcpu                 = 2
      is_domain_controller = true
    }
  }

  # 1) inietta i default hardware/ruolo
  vms_merged = {
    for k, v in local.vms_raw : k => merge(local.vm_default, v)
  }

  # 2) DERIVA la rete dal ruolo
  vms = {
    for k, v in local.vms_merged : k => merge(v, {
      domain      = (v.is_domain_controller || v.ad_member) ? local.ad_domain : local.base_domain
      nameservers = v.is_domain_controller ? local.public_dns : (v.ad_member ? [local.dc_ip] : local.public_dns)
      search      = (v.is_domain_controller || v.ad_member) ? [local.ad_domain] : []
    })
  }
  # Il cuore è il blocco vms finale. Leggilo come tre regole:
  # dominio: DC e membri stanno in ad.lab.home; i non-membri in lab.home.
  # nameservers: il DC usa i DNS pubblici (gli servono al boot per installare Samba, prima di avere un DNS proprio); un membro usa solo il DC; un non-membro i pubblici.
  # search: ad.lab.home per chi è nel dominio, vuoto per gli altri.
}
