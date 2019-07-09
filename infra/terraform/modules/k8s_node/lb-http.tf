# HTTP балансировщик
resource "google_compute_target_pool" "k8s_node_pool" {
  name = "k8s-node-pool"

  instances = [
    "${google_compute_instance.k8s_node.*.self_link}",
  ]

  health_checks = [
    "${google_compute_http_health_check.k8s_node_pool_healthcheck.name}",
  ]
}

resource "google_compute_http_health_check" "k8s_node_pool_healthcheck" {
  name               = "k8s-node-pool-healthcheck"
  request_path       = "/"
  check_interval_sec = 120
  timeout_sec        = 15
  port               = 80
}

resource "google_compute_address" "k8s_node_lb_http_ip" {
  #Статический IP
  name = "k8s-node-lb-http-ip"
}

resource "google_compute_forwarding_rule" "k8s_node_lb_rule" {
  name       = "k8s-node-lb-rule"
  target     = "${google_compute_target_pool.k8s_node_pool.self_link}"
  port_range = "80"
  ip_address = "${google_compute_address.k8s_node_lb_http_ip.self_link}"
}
