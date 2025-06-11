# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.vpc.id
  region        = var.region
}

# Firewall Rules
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_ldap" {
  name    = "allow-ldap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["389", "636"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ldap"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ldap"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ldap"]
}

resource "google_compute_firewall" "allow_kerberos" {
  name    = "allow-kerberos"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["88", "464"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ldap"]
}

resource "google_compute_firewall" "allow_udp_kerberos" {
  name    = "allow-udp-kerberos"
  network = google_compute_network.vpc.name

  allow {
    protocol = "udp"
    ports    = ["88", "464", "123"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ldap"]
}

# LDAP Server
resource "google_compute_instance" "ldap" {
  name         = var.ldap_server_name
  machine_type = var.machine_type
  zone         = var.zone
  allow_stopping_for_update = true
  
  boot_disk {
    initialize_params {
      image = "rocky-linux-cloud/rocky-linux-9"
      size  = var.ldap_boot_disk_size
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {}
  }

  metadata = {
    ssh-keys = "reviewer:${file("~/.ssh/reviewer.pub")}"
  }

  tags = ["ssh", "ldap"]

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Application Server
resource "google_compute_instance" "app" {
  name         = var.app_server_name
  machine_type = var.machine_type
  zone         = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.app_boot_disk_size
    }
  }

  attached_disk {
    source      = google_compute_disk.app_data.self_link
    device_name = "app-data"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {}
  }

  metadata = {
    ssh-keys = "reviewer:${file("~/.ssh/reviewer.pub")}"
  }

  tags = ["ssh", "app"]

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Additional disk for app server
resource "google_compute_disk" "app_data" {
  name = "app-data-disk"
  size = var.app_data_disk_size
  zone = var.zone
} 