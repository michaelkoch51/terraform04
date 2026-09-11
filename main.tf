data "yandex_compute_image" "ubuntu_2204" {
  family = "ubuntu-2204-lts"
}
# Security group для VM
resource "yandex_vpc_security_group" "vm_sg" {
  name       = "vm-security-group"
  network_id = module.vpc_dev.vpc_id

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
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
  security_group_ids = [yandex_vpc_security_group.vm_sg.id]
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
  security_group_ids = [yandex_vpc_security_group.vm_sg.id]
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
