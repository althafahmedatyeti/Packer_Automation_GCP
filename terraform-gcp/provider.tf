provider "google" {
  project = var.project_id
  region  = "asia-south1"
  zone    = "asia-south1-a"
}


terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }

    random = {
      source  = "hashicorp/random"
    }
  }
}
