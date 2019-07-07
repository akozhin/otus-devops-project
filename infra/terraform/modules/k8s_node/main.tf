resource "google_compute_instance" "k8s_node" {
  name         = "${var.instance_name}${count.index}"
  machine_type = "${var.instance_machine_type}"
  zone         = "${var.zone}"
  tags         = ["${var.instance_tag}"]
  count        = "${var.instance_pool_count}"

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "${var.instance_disk_image}",
      size = "${var.instance_disk_size}",
    }
  }

  # определение сетевого интерфейса
  network_interface {
    # сеть, к которой присоединить данный интерфейс
    network = "${var.instance_network_interface}"

    # использовать ephemeral IP для доступа из Интернет
    access_config {
      # указание IP инстанса с приложением в виде внешнего ресурса
      nat_ip = "${element(google_compute_address.k8s_node_ip.*.address, count.index)}"
    }
  }

  metadata {
    # путь до публичного ключа
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
}

resource "google_compute_address" "k8s_node_ip" {
  #IP для инстанса с приложением в виде внешнего ресурса
  name  = "${var.instance_name}-ip${count.index}"
  count = "${var.instance_pool_count}"
}
