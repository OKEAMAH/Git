resource "google_service_account" "this" {
  account_id   = "dal-server"
  display_name = "Service Account for dal-server"
  description  = "Terraform generated service account for dal-server"
}

# If dal-server needs to access a GCP service, this role can allow it
# resource "google_project_iam_member" "this" {
#   project = var.project_id
#   role    = "roles/storage.objectUser" # Example of role
#   member  = "serviceAccount:${google_service_account.this.email}"
# }

resource "google_compute_instance" "dal_server" {
  name = "${local.network}-dal-server"
  zone = local.zone

  service_account {
    email  = google_service_account.this.email
    scopes = ["cloud-platform"]
  }

  network_interface {
    network    = local.network
    subnetwork = local.subnetwork
    network_ip = google_compute_address.internal.address
    access_config {
      nat_ip = google_compute_address.external.address
    }
  }
  tags     = local.network_target_tags
  labels   = local.labels
  metadata = local.metadata

  machine_type = local.dal_server.machine_type
  boot_disk {
    initialize_params {
      image  = local.dal_server.machine_image
      labels = local.dal_server.disk_labels
      size   = local.dal_server.disk_size_gb
      type   = local.dal_server.disk_type
    }
  }
  metadata_startup_script = local.dal_server.startup_script

  depends_on = [google_compute_firewall.firewall]
}
