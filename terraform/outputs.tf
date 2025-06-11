output "ldap_server_ip" {
  description = "The public IP address of the LDAP server"
  value       = google_compute_instance.ldap.network_interface[0].access_config[0].nat_ip
}

output "app_server_ip" {
  description = "The public IP address of the application server"
  value       = google_compute_instance.app.network_interface[0].access_config[0].nat_ip
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnet.name
} 