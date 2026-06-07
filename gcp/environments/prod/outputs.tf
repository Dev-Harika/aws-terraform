output "vpc_network" {
  value = module.vpc.network_name
}

output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "cloudsql_private_ip" {
  value     = module.cloudsql.private_ip
  sensitive = true
}
