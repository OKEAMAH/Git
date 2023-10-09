# Only if no network is given in variables
# https://registry.terraform.io/modules/terraform-google-modules/network/google/latest
module "gcp-network" {
  count   = var.network != "" ? 0 : 1
  source  = "terraform-google-modules/network/google"
  version = "= 6.0.1"

  project_id   = var.project_id
  network_name = "dal-network"

  subnets = [
    {
      subnet_name   = "dal-subnet"
      subnet_ip     = "10.0.0.0/17"
      subnet_region = local.region
    }
  ]
}

resource "google_compute_address" "external" {
  name         = "dal-server-ext-ip-${local.network}"
  address_type = "EXTERNAL"
  network_tier = local.network_tier
  region       = local.region
}

resource "google_compute_address" "internal" {
  name         = "dal-server-int-ip-${local.network}"
  address_type = "INTERNAL"
  subnetwork   = local.subnetwork
  region       = local.region

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_firewall" "firewall" {
  count   = length(var.firewall_source_ranges) > 0 ? 1 : 0
  name    = "${local.network}-dal-server"
  network = local.network
  allow { # SSH
    protocol = "tcp"
    ports    = ["22"]
  }
  allow { # HTTP/HTTPS
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  allow { # Opened port range
    protocol = "tcp"
    ports    = var.firewall_opened_ports_range
  }
  target_tags   = local.network_target_tags
  source_ranges = var.firewall_source_ranges
}
