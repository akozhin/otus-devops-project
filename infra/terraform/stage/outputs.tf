output "k8s_master_external_ip" {
  value = "${module.k8s_master.k8s_master_external_ip}"
}
output "k8s_node_external_ip" {
  value = "${module.k8s_node.k8s_node_external_ip}"
}

output "repo_server_external_ip" {
  value = "${module.repo_server.repo_server_external_ip}"
}
