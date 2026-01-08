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

