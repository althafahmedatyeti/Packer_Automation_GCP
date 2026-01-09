resource "google_compute_instance" "packer_vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "projects/${var.project_id}/global/images/${var.image_name}"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}
