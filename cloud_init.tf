resource "libvirt_cloudinit_disk" "vm_init" {
  for_each = local.vms
  name     = "${each.value.hostname}-cloudinit"

  meta_data = <<-EOF
    instance-id: ${each.value.hostname}
    local-hostname: ${each.value.hostname}
  EOF

  user_data = <<-EOF
    #cloud-config
    hostname: ${each.value.hostname}
    fqdn: ${each.value.hostname}.${each.value.domain}
    users:
      - name: ubuntu
        groups: sudo
        shell: /bin/bash
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh_authorized_keys:
          - ${file(var.ssh_public_key_path)}
    write_files:
      - path: /etc/apt/preferences.d/no-snapd
        content: |
          Package: snapd
          Pin: release a=*
          Pin-Priority: -10
      - path: /etc/hosts
        content: |
          127.0.0.1   localhost
          ${each.value.ip}   ${each.value.hostname}.${each.value.domain}   ${each.value.hostname}
          ::1 ip6-localhost ip6-loopback
          fe00::0 ip6-localnet
          ff00::0 ip6-mcastprefix
          ff02::1 ip6-allnodes
          ff02::2 ip6-allrouters
          ff02::3 ip6-allhosts
      - path: /etc/sysctl.d/99-disable-ipv6.conf
        content: |
          # IPv6 disabilitato: il lab e IPv4 e l'IPv6 del router (RA)
          # inietta DNS spuri che rompono la risoluzione del dominio AD.
          net.ipv6.conf.all.disable_ipv6 = 1
          net.ipv6.conf.default.disable_ipv6 = 1
          net.ipv6.conf.lo.disable_ipv6 = 1
    package_update: true
    package_upgrade: false
    packages:
      - qemu-guest-agent
    runcmd:
      - DEBIAN_FRONTEND=noninteractive apt-get -y purge unattended-upgrades snapd
      - DEBIAN_FRONTEND=noninteractive apt-get -y autoremove --purge
      - rm -rf /root/snap /home/ubuntu/snap
      - sysctl --system
  EOF

  network_config = <<-EOF
    version: 2
    ethernets:
      eth0:
        match:
          macaddress: "${each.value.mac}"
        set-name: eth0
        addresses:
          - "${each.value.ip}/24"
        routes:
          - to: default
            via: 192.168.1.1
        nameservers:
          addresses: ${jsonencode(each.value.nameservers)}
          search: ${jsonencode(each.value.search)}
        dhcp4: false
        dhcp6: false
  EOF
}
