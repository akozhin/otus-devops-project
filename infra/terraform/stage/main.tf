terraform {
  # Версия terraform
  required_version = ">=0.11,<0.12"
}

provider "google" {
  # Версия провайдера
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "k8s_master" {
  source           = "../modules/k8s_master"
  zone             = "${var.zone}"
  public_key_path  = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  instance_disk_image   = "${var.instance_disk_image_k8s_master}"
  instance_machine_type = "${var.instance_machine_type_k8s_master}"
  instance_disk_size = "${var.instance_disk_size_k8s_master}"
  instance_pool_count= "${var.instance_pool_count_k8s_master}"
    instance_name = "${var.instance_name_k8s_master}"
    instance_tag= "${var.instance_tag_k8s_master}"
}

module "k8s_node" {
  source           = "../modules/k8s_node"
  zone             = "${var.zone}"
  public_key_path  = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  instance_disk_image   = "${var.instance_disk_image_k8s_node}"
  instance_machine_type = "${var.instance_machine_type_k8s_node}"
  instance_disk_size = "${var.instance_disk_size_k8s_node}"
  instance_pool_count= "${var.instance_pool_count_k8s_node}"
    instance_name = "${var.instance_name_k8s_node}"
    instance_tag= "${var.instance_tag_k8s_node}"
}

# Временно заблокирован модуль по управлению доступом к серверам по SSH
#module "vpc" {
#  source        = "../modules/vpc"
#  source_ranges = ["0.0.0.0/0"]
#}
