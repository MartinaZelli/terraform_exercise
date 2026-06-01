resource "libvirt_cloudinit_disk" "vm1_init" {
  name  = "vm1-cloudinit"

  meta_data = <<EOF
instance-id: vm1
local-hostname: vm1
EOF

  user_data = <<EOF
#cloud-config
hostname: vm1.local
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${var.ssh_public_key}
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

  network_config = <<EOF
version: 2
ethernets:
  eth0:
    match:
      macaddress: "${local.control_mgmt_macs[0]}"
    set-name: eth0
    addresses:
      - "192.168.1.72/24"
    gateway4: "192.168.1.1"
    nameservers:
      addresses:
        - ${var.dns1}
        - ${var.dns2}
    dhcp4: false
    dhcp6: false
EOF
}
