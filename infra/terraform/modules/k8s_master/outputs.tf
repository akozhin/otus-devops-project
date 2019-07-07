output "k8s_master_external_ip" {
  value = "${google_compute_instance.k8s_master.*.network_interface.0.access_config.0.nat_ip}"
}
