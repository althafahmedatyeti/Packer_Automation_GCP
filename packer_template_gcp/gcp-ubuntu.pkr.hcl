packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

variable "admin_password" {
  type = string
}

variable "user1_password" {
  type = string
}

source "googlecompute" "ubuntu" {
  project_id   = "packer-automation-483407"
  zone         = "us-central1-a"

  image_name   = "packer-ubuntu-hardened-{{timestamp}}"
  image_family = "packer-ubuntu-hardened"

  machine_type = "e2-micro"

  source_image_family  = "ubuntu-2204-lts"
  source_image_project_id = ["ubuntu-os-cloud"]

  ssh_username = "packer"
  
  #credentials_file = "/home/althaf4321/packer-sa-key.json"

}


build {
  sources = ["source.googlecompute.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y python3 python3-apt",
      "sudo mkdir -p /tmp/.ansible",
      "sudo chmod 777 /tmp/.ansible"
    ]
  }
provisioner "ansible" {
  playbook_file = "${path.root}/ansible/playbook.yml"
  use_proxy     = false

  extra_arguments = [
    "--become",
    "--extra-vars",
    "admin_password=${var.admin_password} user1_password=${var.user1_password}",
    "-e", "ansible_python_interpreter=/usr/bin/python3",
    "-e", "ansible_remote_tmp=/tmp/.ansible"
  ]
}
}


