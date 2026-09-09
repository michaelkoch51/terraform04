data "yandex_compute_image" "ubuntu_2204" {
  family = "ubuntu-2204-lts"
}

# 1. Модуль сети
module "vpc_dev" {
  source   = "./vpc"
  env_name = "develop"
  zone     = "ru-central1-a"
  cidr     = "10.0.1.0/24"
}

# 2. Модуль для ВМ маркетинга
module "marketing_vm" {
  source         = "./vm"
  env_name       = "marketing"
  instance_name  = "marketing"
  instance_count = 1
  image_id       = data.yandex_compute_image.ubuntu_2204.id
  subnet_id      = module.vpc_dev.subnet_id
  public_ip      = true
  labels = { project = "marketing" }
  metadata = {
    user-data          = templatefile("${path.module}/templates/cloud-init.tftpl", { ssh_key = var.public_key })
    serial-port-enable = 1
  }
}

# 3. Модуль для ВМ аналитики
module "analytics_vm" {
  source         = "./vm"
  env_name       = "analytics"
  instance_name  = "analytics"
  instance_count = 1
  image_id       = data.yandex_compute_image.ubuntu_2204.id
  subnet_id      = module.vpc_dev.subnet_id
  public_ip      = true
  labels = { project = "analytics" }
  metadata = {
    user-data          = templatefile("${path.module}/templates/cloud-init.tftpl", { ssh_key = var.public_key })
    serial-port-enable = 1
  }
}

# 4. Generator
resource "random_password" "input_vms" {
  for_each = toset(["marketing", "analytics"])
  length   = 16
}
