locals {
  control_mgmt_macs = [for i in range(var.control_count) : format("02:00:00:01:00:%02x", i + 1)]
}
