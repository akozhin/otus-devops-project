output "repo_server_external_ip" {
  value = "${google_compute_instance.repo_server.*.network_interface.0.access_config.0.nat_ip}"
}
