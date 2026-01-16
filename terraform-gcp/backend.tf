terraform {
  backend "gcs" {
    bucket  = "packer-terraform-state-bucket"
    prefix  = "packer-gcp-vm"
  }
}
