variable "project_id" {
  default = "packer-automation-483407"
}

variable "image_name" {
  description = "Packer image name"
  type        = string
}

variable "vm_name" {
  default = "packer-vm-from-ci-0102"
}

variable "machine_type" {
  default = "e2-medium"
}

variable "zone" {
  default = "asia-south1-a"
}
