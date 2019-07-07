variable project {}

variable region {
  default = "europe-west1"
}

variable zone {
  default = "europe-west1-b"
}

variable public_key_path {}

variable private_key_path {
}

##########################################################
# k8s_master
##########################################################
variable instance_disk_image_k8s_master {
  description = "Образ ОС"
  default     = "rhel-7"
}
variable instance_machine_type_k8s_master {
  description = "Тип машины GCP"
  default     = "n1-standard-1"
}

variable instance_disk_size_k8s_master {
  description = "Размер диска ОС"
  default     = "70"
}
variable instance_pool_count_k8s_master {
  description = "Количество инстансов в пуле"
  default = "1"
}

variable instance_name_k8s_master {
  description = "Название инстанса"
  default     = "k8s-master"
}

variable instance_tag_k8s_master {
  description = "Тег инстанса по умолчанию"
  default     = "k8s-master-tag"
}

##########################################################
# k8s_node
##########################################################
variable instance_disk_image_k8s_node {
  description = "Образ ОС"
  default     = "rhel-7"
}
variable instance_machine_type_k8s_node {
  description = "Тип машины GCP"
  default     = "n1-standard-2"
}

variable instance_disk_size_k8s_node {
  description = "Размер диска ОС"
  default     = "100"
}
//app_pool_nodes
variable instance_pool_count_k8s_node {
  description = "Количество инстансов в пуле"
  default = "1"
}

variable instance_name_k8s_node {
  description = "Название инстанса"
  default     = "k8s-node"
}

variable instance_tag_k8s_node {
  description = "Тег инстанса по умолчанию"
  default     = "k8s-node-tag"
}
