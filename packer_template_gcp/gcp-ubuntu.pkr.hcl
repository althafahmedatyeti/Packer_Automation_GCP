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
# Variables populated by secrets.auto.pkrvars.hcl file
variable "admin_password" {
  type      = string
  sensitive = true
}

variable "user1_password" {
  type      = string
  sensitive = true
}

source "googlecompute" "ubuntu" {
  project_id = "packer-automation-483407"
  zone       = "us-central1-a"

  image_name   = "packer-ubuntu-hardened-{{timestamp}}"
  image_family = "packer-ubuntu-hardened"

  machine_type = "e2-micro"

  source_image_family     = "ubuntu-2204-lts"
  source_image_project_id = ["ubuntu-os-cloud"]

  ssh_username = "packer"

  # Credentials picked from GOOGLE_APPLICATION_CREDENTIALS
}

build {
  name    = "gcp-ubuntu-image"
  sources = ["source.googlecompute.ubuntu"]

  provisioner "shell" {
    inline = [
      "set -eu",

      # Non-interactive mode
      "sudo export DEBIAN_FRONTEND=noninteractive || true",
      "sudo export NEEDRESTART_MODE=a || true",

      # Wait for cloud-init
      "sudo cloud-init status --wait",

      # Stop and disable background apt jobs (ROOT REQUIRED)
      "sudo systemctl stop apt-daily.service apt-daily-upgrade.service unattended-upgrades || true",
      "sudo systemctl disable apt-daily.service apt-daily-upgrade.service unattended-upgrades || true",
      "sudo systemctl mask apt-daily.service apt-daily-upgrade.service unattended-upgrades || true",

      "sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer || true",
      "sudo systemctl disable apt-daily.timer apt-daily-upgrade.timer || true",
      "sudo systemctl mask apt-daily.timer apt-daily-upgrade.timer || true",

      # Wait for apt locks
      "while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done",
      "while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 5; done",
      "while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 5; done",

      # Recover apt state (ROOT REQUIRED)
      "sudo rm -rf /var/lib/apt/lists/partial/*",
      "sudo apt-get clean",
      "sudo dpkg --configure -a",

      # Update and install packages
      "sudo apt-get update -y",
      "sudo apt-get install -y python3 python3-apt python3-passlib",

      # Prepare Ansible temp directory
      "sudo mkdir -p /tmp/.ansible",
      "sudo chmod 777 /tmp/.ansible"
    ]
  }
}
