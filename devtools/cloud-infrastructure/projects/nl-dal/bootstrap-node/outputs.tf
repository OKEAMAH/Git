output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "id" {
  description = "ID of the instance deployed"
  value       = google_compute_instance.dal_server.id
}

output "zone" {
  description = "Zone used for the deployment"
  value       = google_compute_instance.dal_server.zone
}

output "network" {
  description = "Network used for the deployment."
  value       = google_compute_instance.dal_server.network_interface[0].network
}

output "subnetwork" {
  description = "Network used for the deployment."
  value       = google_compute_instance.dal_server.network_interface[0].subnetwork
}

output "private_ip" {
  description = "Private IP of the instance deployed"
  value       = google_compute_instance.dal_server.network_interface[0].network_ip
}

output "public_ip" {
  description = "Public IP of the instance deployed"
  value       = google_compute_instance.dal_server.network_interface[0].access_config[0].nat_ip
}

output "service_account" {
  description = "Service account used in the instance deployed"
  value       = google_compute_instance.dal_server.service_account
}

output "startup_script" {
  description = "Display the startup_script.sh"
  value       = local.dal_server.startup_script
}
