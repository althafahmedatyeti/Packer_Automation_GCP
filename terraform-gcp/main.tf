resource "google_compute_instance" "packer_vm" {
  name         = "packer-vm-from-ci"
  machine_type = "e2-medium"
  zone         = "asia-south1-a"

  boot_disk {
    initialize_params {
      image = "projects/my-gcp-project-id/global/images/${var.image_name}"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}
