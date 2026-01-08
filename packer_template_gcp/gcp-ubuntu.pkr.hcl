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

  # provisioner "shell" {
  #   inline = [
  #     "sudo apt-get update -y",
  #     "sudo apt-get install -y python3 python3-apt python3-passlib",
  #     "sudo mkdir -p /tmp/.ansible",
  #     "sudo chmod 777 /tmp/.ansible"
  #   ]
  # }
  # ---------------------------------
# Safe APT handling for Ubuntu (Packer)
# ---------------------------------
provisioner "shell" {
  inline = [
    inline_shebang = "/bin/bash -euxo pipefail"

    # Wait for VM initialization
    "sudo cloud-init status --wait",

    # Stop and permanently disable background apt jobs
    "sudo systemctl stop apt-daily.service apt-daily-upgrade.service unattended-upgrades || true",
    "sudo systemctl disable apt-daily.service apt-daily-upgrade.service unattended-upgrades || true",
    "sudo systemctl mask apt-daily.service apt-daily-upgrade.service unattended-upgrades || true",
    "sudo systemctl stop apt-daily.timer apt-daily-upgrade.timer || true",
    "sudo systemctl disable apt-daily.timer apt-daily-upgrade.timer || true",
    "sudo systemctl mask apt-daily.timer apt-daily-upgrade.timer || true",

    # Wait until apt / dpkg is fully free
    "while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done",
    "while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 5; done",
    "while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 5; done",

    # Recover apt safely
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


  provisioner "ansible" {
    playbook_file = "${path.root}/ansible/playbook.yml"
    use_proxy     = false

    extra_arguments = [
      "--become",
      "--extra-vars",
      jsonencode({
        admin_password = var.admin_password
        user1_password = var.user1_password
      }),
      "-e", "ansible_python_interpreter=/usr/bin/python3",
      "-e", "ansible_remote_tmp=/tmp/.ansible"
    ]
  }
}


