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
  sources = ["source.googlecompute.ubuntu"]

# ---------------------------------
# Production-safe APT handling (Packer)
# ---------------------------------
provisioner "shell" {
  inline = [
    # Fail fast, POSIX-safe
    "set -eu",

    # Non-interactive installs
    "export DEBIAN_FRONTEND=noninteractive",
    "export NEEDRESTART_MODE=a",

    # Wait for VM initialization
    "cloud-init status --wait",

    # Stop and disable background apt jobs
    "systemctl stop apt-daily.service apt-daily-upgrade.service unattended-upgrades || true",
    "systemctl disable apt-daily.service apt-daily-upgrade.service unattended-upgrades || true",
    "systemctl mask apt-daily.service apt-daily-upgrade.service unattended-upgrades || true",
    "systemctl stop apt-daily.timer apt-daily-upgrade.timer || true",
    "systemctl disable apt-daily.timer apt-daily-upgrade.timer || true",
    "systemctl mask apt-daily.timer apt-daily-upgrade.timer || true",

    # Wait until apt / dpkg locks are released
    "while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done",
    "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 5; done",
    "while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 5; done",

    # Recover apt state safely
    "rm -rf /var/lib/apt/lists/partial/*",
    "apt-get clean",
    "dpkg --configure -a",

    # Update and install required packages
    "apt-get update -y",
    "apt-get install -y python3 python3-apt python3-passlib",

    # Prepare Ansible temp directory
    "mkdir -p /tmp/.ansible",
    "chmod 777 /tmp/.ansible"
  ]
}
}
