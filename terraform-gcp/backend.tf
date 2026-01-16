terraform {
  backend "gcs" {
    bucket  = "my-terraform-state-bucket"
    prefix  = "packer-gcp/vm"
  }
}
