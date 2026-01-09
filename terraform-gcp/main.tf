resource "random_string" "vm_suffix" {
  length  = 6
  upper   = false
  special = false
}


module "packer_vm" {
  source = "./modules/compute_instance"

  vm_name      = "${var.vm_name}-${random_string.vm_suffix.result}"
  machine_type  = var.machine_type
  zone          = var.zone
  project_id    = var.project_id
  image_name    = var.image_name
}
