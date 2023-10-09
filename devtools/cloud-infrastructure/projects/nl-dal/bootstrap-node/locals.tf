locals {
  labels = {
    terraform = "true"
  }
  metadata = {
    terraform = "true"
  }
  default_vars = {
    region = "europe-west1"
    zone   = "europe-west1-b"
  }

  # Network
  region     = var.region != "" ? var.region : local.default_vars.region
  zone       = var.zone != "" ? var.zone : local.default_vars.zone
  network    = var.network != "" ? var.network : module.gcp-network[0].network_name
  subnetwork = var.subnetwork != "" ? var.subnetwork : module.gcp-network[0].subnets_names[0]

  network_target_tags = [
    "dal"
  ]
  network_tier = "PREMIUM"

  # Machine parameters
  dal_server = {
    # https://cloud.google.com/compute/docs/general-purpose-machines#n2_machine_types
    machine_type = "n2-standard-2"
    # https://cloud.google.com/container-optimized-os/docs/release-notes
    machine_image  = "cos-cloud/cos-109-lts" # End of support: Sept 2025
    disk_labels    = local.labels
    disk_size_gb   = "100"
    disk_type      = "pd-ssd"
    default_user   = "root"
    startup_script = file("./scripts/startup_script.sh")
  }
}
