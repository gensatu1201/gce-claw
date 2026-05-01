provider "google" {
  project = var.project_id
  region  = "us-central1"
}

variable "project_id" {
  type = string
}

# 1. THE GATE (Firewall)
resource "google_compute_firewall" "claw_firewall" {
  name    = "allow-claw-web-ui"
  network = "default"

  allow {
    protocol = "tcp"
    # 80/443 for HTTPS, 18789 for OpenClaw Dashboard
    ports    = ["80", "443", "18789"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["claw-node"] 
}

# 2. THE SERVER (VM)
resource "google_compute_instance" "claw_vm" {
  name         = "claw-server"
  machine_type = "e2-small" # 2GB RAM is recommended for OC
  zone         = "us-central1-a"
  
  tags         = ["claw-node"] 

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20 # Persistence: This disk saves all your OC data
    }
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD" # Lower cost networking
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Create 2GB Swap (Safety net for the installer)
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab

    # Install Docker (Used only for Caddy/HTTPS)
    apt-get update && apt-get install -y docker.io
    systemctl enable --now docker
  EOT
}
