resource "libvirt_cloudinit_disk" "vm_init" {
  for_each = local.vms
  name     = "${each.value.hostname}-cloudinit"

  meta_data = <<-EOF
    instance-id: ${each.value.hostname}
    local-hostname: ${each.value.hostname}
  EOF

  user_data = <<-EOF
    #cloud-config
    hostname: ${each.value.hostname}.local
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
    package_update: true
    package_upgrade: false
    packages:
      - qemu-guest-agent
    runcmd:
      - DEBIAN_FRONTEND=noninteractive apt-get -y purge unattended-upgrades snapd
      - DEBIAN_FRONTEND=noninteractive apt-get -y autoremove --purge
      - rm -rf /root/snap /home/ubuntu/snap
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
        gateway4: "192.168.1.1"
        nameservers:
          addresses:
            - ${var.dns1}
            - ${var.dns2}
        dhcp4: false
        dhcp6: false
  EOF
}
