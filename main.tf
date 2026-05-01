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
  # UPGRADE: Tau T2A (Arm) gives you 4GB RAM & dedicated CPU
  machine_type = "t2a-standard-1" 
  zone         = "us-central1-a"
  
  tags         = ["claw-node"] 

  boot_disk {
    initialize_params {
      # UPGRADE: Must use the 'arm64' image for T2A instances
      image = "ubuntu-os-cloud/ubuntu-2204-jammy-arm64-v20240307"
      size  = 20 
    }
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD" 
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Swap is less critical with 4GB RAM, but good to keep as a safety net
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab

    # Install Docker
    apt-get update && apt-get install -y docker.io
    systemctl enable --now docker
  EOT
}
