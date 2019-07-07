resource "google_compute_firewall" "k8s_master_http" {
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

resource "google_compute_firewall" "k8s_master_6443" {
  name = "allow-${var.instance_name}-6443"

  # Название сети, в которой действует правило
  network = "${var.instance_network_interface}"

  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]

  # Правило применимо для инстансов с перечисленными тэгами
  target_tags = ["${var.instance_tag}"]
}
