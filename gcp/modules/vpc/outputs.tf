output "network_id" {
  description = "VPC network self-link"
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name to self-link"
  value       = { for k, s in google_compute_subnetwork.private : k => s.id }
}
