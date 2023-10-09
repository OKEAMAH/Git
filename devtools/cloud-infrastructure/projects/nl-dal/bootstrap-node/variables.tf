variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "nl-dal"
}

variable "region" {
  description = "The GCP region where the VM is deployed."
  type        = string
  default     = ""
}

variable "zone" {
  description = "(optional) The zone where the VM is deployed (if leave empty, will use the location of the cluster deployed if exists; if not use \"europe-west1-b\")."
  type        = string
  default     = ""
}

variable "network" {
  description = "(optional) The network (VPC) used by the VM (if leave empty, will deploy its own network (VPC))."
  type        = string
  default     = ""
}

variable "subnetwork" {
  description = "(optional) The subnetwork used by the VM (if leave empty, will deploy its own subnetwork (VPC))."
  type        = string
  default     = ""
}

variable "firewall_source_ranges" {
  description = "List of IP CIDR ranges for the firewall, defaults to 0.0.0.0/0."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "firewall_opened_ports_range" {
  description = "List of ports to be opened for the firewall, defaults to 50000-51000"
  type        = list(string)
  default     = ["50000-51000"]
}
