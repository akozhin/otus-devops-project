variable zone {
  description = "Zone"
  default = "europe-west1-b"
}

variable public_key_path {
  description = "Путь к public key для ssh"
}
variable private_key_path {
  description = "Путь к private key для ssh"
}

variable instance_disk_image {
  description = "Образ ОС"
  default     = "rhel-7"
}

variable instance_machine_type {
  description = "Тип машины GCP"
  default     = "f1-micro"
}

variable instance_disk_size {
  description = "Размер диска ОС"
  default     = "50"
}

variable instance_pool_count {
  description = "Количество инстансов в пуле"
  default = "1"
}

variable instance_name {
  description = "Название инстанса"
  default     = "instance"
}

variable instance_tag {
  description = "Тег инстанса по умолчанию"
  default     = "instance_tag"
}

variable instance_network_interface {
  description = "Cеть, к которой присоединить данный интерфейс"
  default     = "default"
}
