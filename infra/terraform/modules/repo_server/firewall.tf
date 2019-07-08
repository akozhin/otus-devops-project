resource "google_compute_firewall" "repo_server_http" {
  name = "allow-${var.instance_name}-http"

  # Название сети, в которой действует правило
  network = "${var.instance_network_interface}"

  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]

  # Правило применимо для инстансов с перечисленными тэгами
  target_tags = ["${var.instance_tag}"]
}

#registry in gitlab
resource "google_compute_firewall" "repo_server_9080" {
  name = "allow-${var.instance_name}-http"

  # Название сети, в которой действует правило
  network = "${var.instance_network_interface}"

  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["9080"]
  }

  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]

  # Правило применимо для инстансов с перечисленными тэгами
  target_tags = ["${var.instance_tag}"]
}
